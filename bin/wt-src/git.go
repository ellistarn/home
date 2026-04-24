package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// gitRepoRoot returns the repo root. If host is empty, runs locally.
// For remote, pass the remote directory as extra args.
func gitRepoRoot(host string, dir ...string) (string, error) {
	if host == "" {
		out, err := exec.Command("git", "rev-parse", "--show-toplevel").Output()
		if err != nil {
			return "", err
		}
		root := strings.TrimSpace(string(out))
		// Resolve symlinks so paths match OpenCode session directories
		if resolved, err := filepath.EvalSymlinks(root); err == nil {
			root = resolved
		}
		return root, nil
	}
	d := "."
	if len(dir) > 0 {
		d = dir[0]
	}
	out, err := sshRun(host, fmt.Sprintf("git -C '%s' rev-parse --show-toplevel", d))
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(out), nil
}

func gitWorktreeAdd(host, repo, name string) error {
	if host == "" {
		cmd := exec.Command("git", "worktree", "add", ".worktrees/"+name, "-b", name)
		cmd.Dir = repo
		cmd.Stdout = os.Stderr
		cmd.Stderr = os.Stderr
		return cmd.Run()
	}
	script := fmt.Sprintf("cd '%s' && git worktree add '.worktrees/%s' -b '%s'", repo, name, name)
	_, err := sshRun(host, script)
	return err
}

func dirExists(host, path string) bool {
	if host == "" {
		info, err := os.Stat(path)
		return err == nil && info.IsDir()
	}
	_, err := sshRun(host, fmt.Sprintf("test -d '%s'", path))
	return err == nil
}
