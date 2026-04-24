package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestFetchSessionsForDirs(t *testing.T) {
	sessions := map[string][]ocSession{
		"/repo/.worktrees/wt1": {
			{ID: "ses_1", Directory: "/repo/.worktrees/wt1", Title: "Fix auth", Time: struct {
				Created int64 `json:"created"`
				Updated int64 `json:"updated"`
			}{Created: 1000, Updated: 2000}},
		},
		"/repo/.worktrees/wt2": {
			{ID: "ses_2", Directory: "/repo/.worktrees/wt2", Title: "Add tests", Time: struct {
				Created int64 `json:"created"`
				Updated int64 `json:"updated"`
			}{Created: 1000, Updated: 3000}},
			// Subagent session — should be filtered out
			{ID: "ses_sub", ParentID: "ses_2", Directory: "/repo/.worktrees/wt2", Title: "Explore codebase (@explore subagent)", Time: struct {
				Created int64 `json:"created"`
				Updated int64 `json:"updated"`
			}{Created: 1000, Updated: 4000}},
		},
	}

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		dir := r.URL.Query().Get("directory")
		s := sessions[dir]
		if s == nil {
			s = []ocSession{}
		}
		json.NewEncoder(w).Encode(s)
	}))
	defer srv.Close()

	records, err := fetchSessionsForDirs(srv.URL, []string{
		"/repo/.worktrees/wt1",
		"/repo/.worktrees/wt2",
		"/repo/.worktrees/wt3", // no sessions
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	// Should have 2 records (wt1 + wt2), subagent filtered out, wt3 empty
	if len(records) != 2 {
		t.Fatalf("expected 2 records, got %d", len(records))
	}

	byDir := map[string]sessionRecord{}
	for _, r := range records {
		byDir[r.dir] = r
	}
	if r := byDir["/repo/.worktrees/wt1"]; r.title != "Fix auth" {
		t.Errorf("wt1: expected title %q, got %q", "Fix auth", r.title)
	}
	if r := byDir["/repo/.worktrees/wt2"]; r.title != "Add tests" {
		t.Errorf("wt2: expected title %q, got %q", "Add tests", r.title)
	}
}

func TestFetchSessionsForDirs_ServerDown(t *testing.T) {
	// Point at a closed server
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {}))
	srv.Close()

	records, err := fetchSessionsForDirs(srv.URL, []string{"/repo/.worktrees/wt1"})
	if err == nil {
		t.Fatal("expected error for unreachable server")
	}
	if len(records) != 0 {
		t.Errorf("expected 0 records on error, got %d", len(records))
	}
}

func TestFetchSessionsForDirs_Empty(t *testing.T) {
	records, err := fetchSessionsForDirs("http://unused", nil)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if records != nil {
		t.Errorf("expected nil records, got %v", records)
	}
}

func TestEnrichEntries(t *testing.T) {
	entries := []WorktreeEntry{
		{Dir: "/repo/.worktrees/wt1"},
		{Dir: "/repo/.worktrees/wt2"},
		{Dir: "/repo/.worktrees/wt3"}, // no matching session
	}
	records := []sessionRecord{
		{id: "ses_old", dir: "/repo/.worktrees/wt1", title: "Old", updated: 1000},
		{id: "ses_new", dir: "/repo/.worktrees/wt1", title: "New", updated: 2000}, // should win
		{id: "ses_2", dir: "/repo/.worktrees/wt2", title: "Second", updated: 3000},
	}

	enrichEntries(entries, records)

	// wt1: most recent session wins
	if entries[0].SessionID != "ses_new" {
		t.Errorf("wt1: expected session ses_new, got %s", entries[0].SessionID)
	}
	if entries[0].Title != "New" {
		t.Errorf("wt1: expected title %q, got %q", "New", entries[0].Title)
	}

	// wt2: normal match
	if entries[1].SessionID != "ses_2" {
		t.Errorf("wt2: expected session ses_2, got %s", entries[1].SessionID)
	}

	// wt3: no match → missing
	if entries[2].Status != "missing" {
		t.Errorf("wt3: expected status %q, got %q", "missing", entries[2].Status)
	}
}

func TestDeriveStatus(t *testing.T) {
	now := time.Now().UnixMilli()

	tests := []struct {
		name    string
		updated int64
		want    string
	}{
		{"recent update is working", now - 10_000, "working"}, // 10s ago
		{"old update is idle", now - 120_000, "idle"},          // 2min ago
		{"zero update is idle", 0, "idle"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := deriveStatus(sessionRecord{updated: tt.updated})
			if got != tt.want {
				t.Errorf("deriveStatus(updated=%d) = %q, want %q", tt.updated, got, tt.want)
			}
		})
	}
}

func TestFetchSessionsForDirs_PartialFailure(t *testing.T) {
	// Server that returns 500 for wt2 but succeeds for wt1
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		dir := r.URL.Query().Get("directory")
		if dir == "/repo/.worktrees/wt2" {
			w.WriteHeader(http.StatusInternalServerError)
			return
		}
		json.NewEncoder(w).Encode([]ocSession{
			{ID: "ses_1", Directory: dir, Title: "Success", Time: struct {
				Created int64 `json:"created"`
				Updated int64 `json:"updated"`
			}{Created: 1000, Updated: 2000}},
		})
	}))
	defer srv.Close()

	records, err := fetchSessionsForDirs(srv.URL, []string{
		"/repo/.worktrees/wt1",
		"/repo/.worktrees/wt2",
	})

	// Should return an error AND partial results
	if err == nil {
		t.Fatal("expected error for partial failure")
	}
	if len(records) != 1 {
		t.Fatalf("expected 1 partial record, got %d", len(records))
	}
	if records[0].dir != "/repo/.worktrees/wt1" {
		t.Errorf("expected wt1 record, got %s", records[0].dir)
	}
}
