package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

func sshHost() string {
	host := os.Getenv("DEV_DESKTOP_HOST")
	if host == "" {
		die("DEV_DESKTOP_HOST is not set")
	}
	return host
}

func sshRun(host, cmd string) (string, error) {
	c := exec.Command("ssh", host, "bash")
	c.Stdin = strings.NewReader(cmd)
	out, err := c.CombinedOutput()
	if err != nil {
		return string(out), fmt.Errorf("ssh %s: %w: %s", host, err, string(out))
	}
	return string(out), nil
}

func runCommand(name string, args ...string) ([]byte, error) {
	return exec.Command(name, args...).Output()
}

// resolveRemoteHome resolves and caches the remote physical home directory.
func resolveRemoteHome(host string) string {
	cacheDir, _ := os.UserCacheDir()
	cachePath := filepath.Join(cacheDir, "wt-remote-home")

	if data, err := os.ReadFile(cachePath); err == nil {
		return strings.TrimSpace(string(data))
	}

	out, err := sshRun(host, "readlink -f $HOME")
	if err != nil {
		die("cannot resolve remote HOME: %v", err)
	}
	home := strings.TrimSpace(out)

	_ = os.MkdirAll(filepath.Dir(cachePath), 0755)
	_ = os.WriteFile(cachePath, []byte(home), 0644)
	return home
}

// toRemotePath translates a local path to its remote equivalent.
func toRemotePath(localPath, remoteHome string) string {
	home, err := os.UserHomeDir()
	if err != nil {
		die("cannot determine HOME: %v", err)
	}

	// Expand ~ explicitly
	if strings.HasPrefix(localPath, "~/") {
		localPath = home + localPath[1:]
	}

	if !strings.HasPrefix(localPath, home) {
		die("path must start with $HOME: %s", localPath)
	}

	return remoteHome + localPath[len(home):]
}
