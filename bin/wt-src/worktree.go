package main

import (
	"fmt"
	"math/rand"
	"sort"
	"time"
)

// WorktreeEntry represents a discovered worktree.
type WorktreeEntry struct {
	Name      string    // branch/worktree name
	Dir       string    // absolute path on the host where it lives
	Repo      string    // repo root path
	Remote    bool      // true if this worktree lives on the remote host
	CreatedAt time.Time // worktree creation time (from filesystem)
	UpdatedAt time.Time // last session activity (from OpenCode server)
	SessionID string    // most recent OpenCode session ID (empty if none)
	Status    string    // working, idle, or missing
	Title     string    // OpenCode session title
}

func generateName() string {
	now := time.Now()
	return fmt.Sprintf("%s-%d", now.Format("0102T1504"), rand.Intn(100000))
}

// sortWorktrees sorts entries by most recent activity, newest first.
// Uses UpdatedAt if available, otherwise CreatedAt.
// Entries without any timestamp sort to the end.
func sortWorktrees(entries []WorktreeEntry) {
	sort.SliceStable(entries, func(i, j int) bool {
		ti := entries[i].sortTime()
		tj := entries[j].sortTime()
		if ti.IsZero() && tj.IsZero() {
			return entries[i].Name < entries[j].Name
		}
		if ti.IsZero() {
			return false
		}
		if tj.IsZero() {
			return true
		}
		return ti.After(tj)
	})
}

// sortTime returns UpdatedAt if set, otherwise CreatedAt.
func (e *WorktreeEntry) sortTime() time.Time {
	if !e.UpdatedAt.IsZero() {
		return e.UpdatedAt
	}
	return e.CreatedAt
}

// timeUnix converts a unix timestamp to time.Time.
func timeUnix(sec int64) time.Time {
	return time.Unix(sec, 0)
}
