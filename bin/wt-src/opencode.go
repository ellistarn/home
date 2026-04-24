package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"sort"
	"sync"
	"time"
)

// OpenCode API types (minimal subset).

type ocSession struct {
	ID        string `json:"id"`
	ParentID  string `json:"parentID,omitempty"`
	Directory string `json:"directory"`
	Title     string `json:"title"`
	Time      struct {
		Created int64 `json:"created"`
		Updated int64 `json:"updated"`
	} `json:"time"`
}

// sessionRecord holds the fields we need from a session for display.
type sessionRecord struct {
	id      string
	dir     string
	title   string
	updated int64
}

// deriveStatus infers session status from the session's last update time.
// While the agent is generating, the session's time_updated advances as
// tokens stream in. Once complete, it stops updating.
func deriveStatus(r sessionRecord) string {
	if r.updated > 0 {
		age := time.Since(time.UnixMilli(r.updated))
		if age < 60*time.Second {
			return "working"
		}
	}
	return "idle"
}

func localServerURL() string {
	if u := os.Getenv("WT_LOCAL_SERVER"); u != "" {
		return u
	}
	return "http://localhost:9000"
}

func opencodeServerURL() string {
	if u := os.Getenv("WT_SERVER"); u != "" {
		return u
	}
	port := os.Getenv("DEV_DESKTOP_TUNNEL_PORT")
	if port == "" {
		port = "9847"
	}
	return fmt.Sprintf("http://opencode.etarn:%s", port)
}

// findLatestSession queries the OpenCode server for the most recent session
// in the given directory. Returns empty string if none found or server unreachable.
func findLatestSession(serverURL, directory string) string {
	u := serverURL + "/session"
	if directory != "" {
		u += "?directory=" + url.QueryEscape(directory)
	}
	resp, err := httpGet(u)
	if err != nil {
		return ""
	}
	defer resp.Body.Close()

	var sessions []ocSession
	if err := json.NewDecoder(resp.Body).Decode(&sessions); err != nil {
		return ""
	}
	if len(sessions) == 0 {
		return ""
	}
	sort.Slice(sessions, func(i, j int) bool {
		return sessions[i].Time.Updated > sessions[j].Time.Updated
	})
	return sessions[0].ID
}

// fetchSessionsForDirs queries an OpenCode server for sessions across multiple
// directories in parallel. Each directory gets its own /session?directory= call.
func fetchSessionsForDirs(serverURL string, dirs []string) ([]sessionRecord, error) {
	if len(dirs) == 0 {
		return nil, nil
	}

	type result struct {
		records []sessionRecord
		err     error
	}

	results := make([]result, len(dirs))
	var wg sync.WaitGroup
	for i, dir := range dirs {
		wg.Add(1)
		go func(idx int, d string) {
			defer wg.Done()
			u := serverURL + "/session?directory=" + url.QueryEscape(d)
			resp, err := httpGet(u)
			if err != nil {
				results[idx] = result{err: err}
				return
			}
			defer resp.Body.Close()

			var sessions []ocSession
			if err := json.NewDecoder(resp.Body).Decode(&sessions); err != nil {
				results[idx] = result{err: fmt.Errorf("decode sessions: %w", err)}
				return
			}

			var records []sessionRecord
			for _, s := range sessions {
				if s.ParentID != "" {
					continue // skip subagent sessions
				}
				records = append(records, sessionRecord{
					id:      s.ID,
					dir:     s.Directory,
					title:   s.Title,
					updated: s.Time.Updated,
				})
			}
			results[idx] = result{records: records}
		}(i, dir)
	}
	wg.Wait()

	var all []sessionRecord
	var firstErr error
	for _, r := range results {
		if r.err != nil && firstErr == nil {
			firstErr = r.err
		}
		all = append(all, r.records...)
	}
	return all, firstErr
}

func enrichWithSessions(serverURL string, entries []WorktreeEntry) error {
	if len(entries) == 0 {
		return nil
	}
	dirs := make([]string, len(entries))
	for i, e := range entries {
		dirs[i] = e.Dir
	}
	records, err := fetchSessionsForDirs(serverURL, dirs)
	enrichEntries(entries, records) // use whatever we got, even on partial failure
	return err
}

func enrichEntries(entries []WorktreeEntry, records []sessionRecord) {
	byDir := make(map[string]sessionRecord)
	for _, r := range records {
		existing, ok := byDir[r.dir]
		if !ok || r.updated > existing.updated {
			byDir[r.dir] = r
		}
	}

	for i := range entries {
		r, ok := byDir[entries[i].Dir]
		if !ok {
			entries[i].Status = "missing"
			continue
		}
		entries[i].SessionID = r.id
		entries[i].Title = r.title
		entries[i].UpdatedAt = time.UnixMilli(r.updated)
		entries[i].Status = deriveStatus(r)
	}
}

var httpClient = &http.Client{Timeout: 5 * time.Second}

func httpGet(u string) (*http.Response, error) {
	resp, err := httpClient.Get(u)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		resp.Body.Close()
		return nil, fmt.Errorf("HTTP %d from %s", resp.StatusCode, u)
	}
	return resp, nil
}
