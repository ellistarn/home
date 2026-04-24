package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

// OpenCode API types (minimal subset, used for remote attach).

type ocSession struct {
	ID        string `json:"id"`
	Directory string `json:"directory"`
	Title     string `json:"title"`
	Time      struct {
		Created int64 `json:"created"`
		Updated int64 `json:"updated"`
	} `json:"time"`
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

// sessionRecord holds the fields we need from the SQLite session + last message.
type sessionRecord struct {
	id             string
	dir            string
	title          string
	updated        int64
	lastMsgRole    string
	lastMsgUpdated int64
}

// deriveStatus infers session status from the last message.
// While the agent is generating, the assistant message's time_updated advances
// as tokens stream in. Once complete, it stops updating.
func deriveStatus(r sessionRecord) string {
	if r.lastMsgRole == "assistant" && r.lastMsgUpdated > 0 {
		age := time.Since(time.UnixMilli(r.lastMsgUpdated))
		if age < 60*time.Second {
			return "working"
		}
	}
	return "idle"
}

// opencodeDBPath returns the path to the local OpenCode SQLite database.
func opencodeDBPath() string {
	dataDir := os.Getenv("XDG_DATA_HOME")
	if dataDir == "" {
		home, _ := os.UserHomeDir()
		dataDir = filepath.Join(home, ".local", "share")
	}
	return filepath.Join(dataDir, "opencode", "opencode.db")
}

const sessionQuery = `
SELECT s.id, s.directory, s.title, s.time_updated,
       CASE WHEN m.data LIKE '%%"role":"assistant"%%' THEN 'assistant' ELSE '' END,
       COALESCE(m.time_updated, 0)
FROM session s
LEFT JOIN message m ON m.session_id = s.id
  AND m.time_created = (SELECT MAX(time_created) FROM message WHERE session_id = s.id)
WHERE s.directory IN (%s)
ORDER BY s.time_updated DESC
`

func queryLocalSessions(dirs []string) []sessionRecord {
	if len(dirs) == 0 {
		return nil
	}
	return querySessionsFromDB("", opencodeDBPath(), dirs)
}

func queryRemoteSessions(host string, dirs []string) []sessionRecord {
	if len(dirs) == 0 {
		return nil
	}
	return querySessionsFromDB(host, "$HOME/.local/share/opencode/opencode.db", dirs)
}

func querySessionsFromDB(host, dbPath string, dirs []string) []sessionRecord {
	quoted := make([]string, len(dirs))
	for i, d := range dirs {
		quoted[i] = "'" + strings.ReplaceAll(d, "'", "''") + "'"
	}
	query := fmt.Sprintf(sessionQuery, strings.Join(quoted, ","))

	var out string
	var err error
	if host == "" {
		// Run sqlite3 locally, passing the query via stdin to avoid shell quoting issues.
		c := exec.Command("sqlite3", "-separator", "\t", dbPath)
		c.Stdin = strings.NewReader(query)
		b, e := c.Output()
		out, err = string(b), e
	} else {
		cmd := fmt.Sprintf("sqlite3 -separator '\t' \"%s\" \"%s\"", dbPath, query)
		out, err = sshRun(host, cmd)
	}
	if err != nil {
		return nil
	}

	var records []sessionRecord
	for _, line := range strings.Split(strings.TrimSpace(out), "\n") {
		if line == "" {
			continue
		}
		parts := strings.SplitN(line, "\t", 6)
		if len(parts) < 6 {
			continue
		}
		var updated, lastMsgUpdated int64
		fmt.Sscanf(parts[3], "%d", &updated)
		fmt.Sscanf(parts[5], "%d", &lastMsgUpdated)
		records = append(records, sessionRecord{
			id:             parts[0],
			dir:            parts[1],
			title:          parts[2],
			updated:        updated,
			lastMsgRole:    parts[4],
			lastMsgUpdated: lastMsgUpdated,
		})
	}
	return records
}

func enrichLocalWithSessions(entries []WorktreeEntry) {
	dirs := make([]string, len(entries))
	for i, e := range entries {
		dirs[i] = e.Dir
	}
	enrichEntries(entries, queryLocalSessions(dirs))
}

func enrichRemoteWithSessions(host string, entries []WorktreeEntry) {
	dirs := make([]string, len(entries))
	for i, e := range entries {
		dirs[i] = e.Dir
	}
	enrichEntries(entries, queryRemoteSessions(host, dirs))
}

func enrichEntries(entries []WorktreeEntry, records []sessionRecord) {
	type sessionInfo struct {
		record sessionRecord
	}
	byDir := make(map[string]sessionInfo)

	for _, r := range records {
		existing, ok := byDir[r.dir]
		if !ok || r.updated > existing.record.updated {
			byDir[r.dir] = sessionInfo{record: r}
		}
	}

	for i := range entries {
		info, ok := byDir[entries[i].Dir]
		if !ok {
			entries[i].Status = "missing"
			continue
		}
		entries[i].SessionID = info.record.id
		entries[i].Title = info.record.title
		entries[i].UpdatedAt = time.UnixMilli(info.record.updated)
		entries[i].Status = deriveStatus(info.record)
	}
}

func httpGet(u string) (*http.Response, error) {
	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Get(u)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		resp.Body.Close()
		return nil, fmt.Errorf("HTTP %d from %s", resp.StatusCode, u)
	}
	return resp, nil
}
