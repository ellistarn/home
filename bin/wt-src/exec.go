package main

import (
	"os"
	"os/exec"
	"syscall"
)

// execOpencode replaces the current process with opencode in the given directory.
func execOpencode(dir string) {
	binary, err := exec.LookPath("opencode")
	if err != nil {
		die("opencode not found in PATH")
	}

	args := []string{"opencode"}

	if err := os.Chdir(dir); err != nil {
		die("cannot cd to %s: %v", dir, err)
	}

	if err := syscall.Exec(binary, args, os.Environ()); err != nil {
		die("exec opencode: %v", err)
	}
}

// execOpencodeAttach replaces the current process with opencode attach.
func execOpencodeAttach(serverURL, dir, sessionID string) {
	binary, err := exec.LookPath("opencode")
	if err != nil {
		die("opencode not found in PATH")
	}

	args := []string{"opencode", "attach", serverURL, "--dir", dir}
	if sessionID != "" {
		args = append(args, "--session", sessionID)
	}

	if err := syscall.Exec(binary, args, os.Environ()); err != nil {
		die("exec opencode attach: %v", err)
	}
}
