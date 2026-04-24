package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
)

func listLocalWorktrees() []WorktreeEntry {
	home, err := os.UserHomeDir()
	if err != nil {
		return nil
	}
	if resolved, err := filepath.EvalSymlinks(home); err == nil {
		home = resolved
	}

	// Find .worktrees directories by walking with os.ReadDir, which uses
	// the d_type field from readdir to check IsDir() without stat syscalls.
	var all []WorktreeEntry
	seen := make(map[string]bool)
	findWorktreeDirs(home, 0, 6, func(repo string) {
		if seen[repo] {
			return
		}
		seen[repo] = true
		all = append(all, listWorktreesInRepo("", repo)...)
	})
	return all
}

// findWorktreeDirs walks directories looking for .worktrees entries.
// Uses os.ReadDir which returns d_type from readdir (no stat per entry).
func findWorktreeDirs(dir string, depth, maxDepth int, fn func(repo string)) {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return
	}
	for _, e := range entries {
		if !e.IsDir() {
			continue
		}
		name := e.Name()
		if name == ".worktrees" {
			fn(dir)
			continue
		}
		// Skip hidden directories and common heavy dirs
		if strings.HasPrefix(name, ".") {
			continue
		}
		if depth < maxDepth {
			findWorktreeDirs(filepath.Join(dir, name), depth+1, maxDepth, fn)
		}
	}
}

func listWorktreesInRepo(host, repo string) []WorktreeEntry {
	var out string
	var err error
	if host == "" {
		b, e := exec.Command("git", "-C", repo, "worktree", "list", "--porcelain").Output()
		out, err = string(b), e
	} else {
		out, err = sshRun(host, fmt.Sprintf("git -C '%s' worktree list --porcelain", repo))
	}
	if err != nil {
		return nil
	}
	return parseWorktreeList(out, repo)
}

func parseWorktreeList(porcelain, repo string) []WorktreeEntry {
	var entries []WorktreeEntry
	var currentWT string
	wtPrefix := repo + "/.worktrees/"

	for _, line := range strings.Split(porcelain, "\n") {
		if strings.HasPrefix(line, "worktree ") {
			currentWT = strings.TrimPrefix(line, "worktree ")
		}
		if strings.HasPrefix(line, "branch ") && currentWT != "" {
			branch := strings.TrimPrefix(line, "branch refs/heads/")
			if strings.HasPrefix(currentWT, wtPrefix) {
				e := WorktreeEntry{
					Name: branch,
					Dir:  currentWT,
					Repo: repo,
				}
				// For local worktrees, stat the .git file to get creation time.
				// Git creates this file when the worktree is added; it doesn't change.
				if info, err := os.Stat(filepath.Join(currentWT, ".git")); err == nil {
					e.CreatedAt = info.ModTime()
				}
				entries = append(entries, e)
			}
			currentWT = ""
		}
	}
	return entries
}

func listRemoteWorktrees(host string) []WorktreeEntry {
	script := `
set -eu
home=$(readlink -f "$HOME")
shopt -s nullglob
for wt_dir in "$home"/*/.worktrees "$home"/*/*/.worktrees "$home"/*/*/*/.worktrees "$home"/*/*/*/*/.worktrees "$home"/*/*/*/*/*/.worktrees; do
    repo="${wt_dir%/.worktrees}"
    if [ -d "$repo/.git" ] || [ -f "$repo/.git" ]; then
        git -C "$repo" worktree list --porcelain 2>/dev/null | awk -v repo="$repo" '
            /^worktree / { wt=$2 }
            /^branch / {
                br=$2; sub(/^refs\/heads\//, "", br)
                if (wt ~ /\/.worktrees\//) print wt "\t" br "\t" repo
            }
        '
    fi
done
`
	out, err := sshRun(host, script)
	if err != nil {
		return nil
	}

	// Collect worktree paths to batch-stat their .git files for creation time
	var lines []string
	for _, line := range strings.Split(strings.TrimSpace(out), "\n") {
		if line != "" {
			lines = append(lines, line)
		}
	}
	if len(lines) == 0 {
		return nil
	}

	// Build a batch stat command for all .git files
	var statPaths []string
	for _, line := range lines {
		parts := strings.SplitN(line, "\t", 3)
		if len(parts) >= 1 {
			statPaths = append(statPaths, fmt.Sprintf("'%s/.git'", parts[0]))
		}
	}
	statScript := fmt.Sprintf("stat -c '%%Y' %s 2>/dev/null || true", strings.Join(statPaths, " "))
	statOut, _ := sshRun(host, statScript)
	statLines := strings.Split(strings.TrimSpace(statOut), "\n")

	var entries []WorktreeEntry
	for i, line := range lines {
		parts := strings.SplitN(line, "\t", 3)
		if len(parts) < 3 {
			continue
		}
		e := WorktreeEntry{
			Dir:    parts[0],
			Name:   parts[1],
			Repo:   parts[2],
			Remote: true,
		}
		if i < len(statLines) {
			if ts, err := strconv.ParseInt(strings.TrimSpace(statLines[i]), 10, 64); err == nil {
				e.CreatedAt = timeUnix(ts)
			}
		}
		entries = append(entries, e)
	}
	return entries
}
