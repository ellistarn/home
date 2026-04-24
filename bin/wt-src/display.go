package main

import (
	"fmt"
	"os"
	"text/tabwriter"
	"time"
)

func printWorktreeTable(entries []WorktreeEntry) {
	w := tabwriter.NewWriter(os.Stdout, 2, 4, 2, ' ', 0)

	fmt.Fprintf(w, "  UPDATED\tCREATED\tWORKTREE\tREPO\tSTATUS\tTITLE\n")

	now := time.Now()
	for _, e := range entries {
		status := e.Status
		if status == "" {
			status = "-"
		}
		title := e.Title
		if title == "" {
			title = "-"
		}
		updated := formatAge(e.UpdatedAt, now)
		created := formatAge(e.CreatedAt, now)
		repo := formatRepo(e.Repo, e.Remote)
		fmt.Fprintf(w, "  %s\t%s\t%s\t%s\t%s\t%s\n", updated, created, e.Name, repo, status, title)
	}

	w.Flush()
}

// formatRepo prefixes remote repos with ssh:// to distinguish them from local.
func formatRepo(repo string, remote bool) string {
	if remote {
		return "ssh://" + repo
	}
	return repo
}

func formatAge(t time.Time, now time.Time) string {
	if t.IsZero() {
		return "-"
	}
	d := now.Sub(t)
	switch {
	case d < time.Minute:
		return "just now"
	case d < time.Hour:
		return fmt.Sprintf("%dm ago", int(d.Minutes()))
	case d < 24*time.Hour:
		return fmt.Sprintf("%dh ago", int(d.Hours()))
	default:
		days := int(d.Hours() / 24)
		if days == 1 {
			return "1d ago"
		}
		return fmt.Sprintf("%dd ago", days)
	}
}
