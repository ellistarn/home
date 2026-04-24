package main

import (
	"fmt"
	"os"
	"strings"
)

func main() {
	args := os.Args[1:]

	// Parse global flags
	remote := false
	var remaining []string
	for i := 0; i < len(args); i++ {
		switch args[i] {
		case "-r", "--remote":
			remote = true
		case "-h", "--help":
			printUsage()
			os.Exit(0)
		default:
			remaining = append(remaining, args[i])
		}
	}

	// Dispatch
	if len(remaining) > 0 && remaining[0] == "ls" {
		cmdLs(remote)
		return
	}

	if remote {
		cmdRemote(remaining)
	} else {
		cmdLocal(remaining)
	}
}

// cmdLocal handles: wt [name]
func cmdLocal(args []string) {
	repo, err := gitRepoRoot("")
	if err != nil {
		die("not in a git repo")
	}

	var name, wtDir string
	if len(args) == 0 {
		// Create new worktree
		name = generateName()
		wtDir = repo + "/.worktrees/" + name
		if err := gitWorktreeAdd("", repo, name); err != nil {
			die("failed to create worktree: %v", err)
		}
		fmt.Printf("Created worktree: %s\n", name)
		fmt.Printf("  resume:\n  wt %s\n", name)
	} else {
		name = args[0]
		wtDir = repo + "/.worktrees/" + name
		if !dirExists("", wtDir) {
			// Not found locally — try remote
			attachRemoteByName(name)
			return
		}
	}

	// Attach: exec opencode in the worktree
	execOpencode(wtDir)
}

// cmdRemote handles: wt -r <path> [name]
func cmdRemote(args []string) {
	if len(args) == 0 {
		die("remote mode requires a repo path: wt -r <path> [name]")
	}

	host := sshHost()
	remoteHome := resolveRemoteHome(host)
	remotePath := toRemotePath(args[0], remoteHome)

	repo, err := gitRepoRoot(host, remotePath)
	if err != nil {
		die("not a git repo on remote: %s", remotePath)
	}

	var name, wtDir string
	if len(args) < 2 {
		// Create new worktree
		name = generateName()
		wtDir = repo + "/.worktrees/" + name
		if err := gitWorktreeAdd(host, repo, name); err != nil {
			die("failed to create remote worktree: %v", err)
		}
		localPath := args[0]
		fmt.Printf("Created worktree: %s\n", name)
		fmt.Printf("  resume:\n  wt -r %s %s\n", localPath, name)
	} else {
		name = args[1]
		wtDir = repo + "/.worktrees/" + name
		if !dirExists(host, wtDir) {
			die("worktree not found on remote: %s", wtDir)
		}
	}

	// Attach: find most recent session, then opencode attach
	serverURL := opencodeServerURL()
	sessionID := findLatestSession(serverURL, wtDir)
	execOpencodeAttach(serverURL, wtDir, sessionID)
}

// attachRemoteByName searches remote worktrees for one matching the given name
// and attaches to it. Dies if DEV_DESKTOP_HOST is unset or the name isn't found.
func attachRemoteByName(name string) {
	host := os.Getenv("DEV_DESKTOP_HOST")
	if host == "" {
		die("worktree %q not found locally and DEV_DESKTOP_HOST is not set", name)
	}

	entries := listRemoteWorktrees(host)
	for _, e := range entries {
		if e.Name == name {
			serverURL := opencodeServerURL()
			sessionID := findLatestSession(serverURL, e.Dir)
			execOpencodeAttach(serverURL, e.Dir, sessionID)
			return // unreachable — execOpencodeAttach calls syscall.Exec
		}
	}
	die("worktree %q not found locally or on remote", name)
}

// cmdLs handles: wt ls
func cmdLs(remoteOnly bool) {
	host := os.Getenv("DEV_DESKTOP_HOST")

	// Run local and remote discovery concurrently
	type result struct {
		entries []WorktreeEntry
	}
	localCh := make(chan result, 1)
	remoteCh := make(chan result, 1)

	if !remoteOnly {
		go func() { localCh <- result{listLocalWorktrees()} }()
	} else {
		localCh <- result{}
	}

	if host != "" {
		go func() { remoteCh <- result{listRemoteWorktrees(host)} }()
	} else {
		if remoteOnly {
			die("DEV_DESKTOP_HOST is not set")
		}
		remoteCh <- result{}
	}

	local := (<-localCh).entries
	remote := (<-remoteCh).entries

	enrichLocalWithSessions(local)
	if host != "" {
		enrichRemoteWithSessions(host, remote)
	}

	all := append(local, remote...)
	sortWorktrees(all)

	if len(all) == 0 {
		fmt.Println("No worktrees found.")
		return
	}
	printWorktreeTable(all)
}

func printUsage() {
	usage := strings.TrimSpace(`
wt — worktree session manager

Usage:
  wt                        Create a new local worktree and attach
  wt <name>                 Attach to an existing local worktree
  wt -r <path>              Create a new remote worktree and attach
  wt -r <path> <name>       Attach to an existing remote worktree
  wt ls                     List all worktrees (local and remote)
  wt -r ls                  List remote worktrees only

Flags:
  -r, --remote              Operate on the remote dev desktop
  -h, --help                Show this help
`)
	fmt.Println(usage)
}

func die(format string, args ...any) {
	fmt.Fprintf(os.Stderr, "wt: "+format+"\n", args...)
	os.Exit(1)
}
