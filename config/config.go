package config

import (
	_ "embed"
	"fmt"
	"os"
	"strings"
	"path/filepath"
)

//go:embed version
var version string

//go:embed name
var name string

type LogLevel string

const (
	Debug LogLevel = "debug"
	Info  LogLevel = "info"
	Warn  LogLevel = "warn"
	Error LogLevel = "error"
)

func GetVersion() string {
	return strings.TrimSpace(version)
}

func GetName() string {
	return strings.TrimSpace(name)
}

func GetLogLevel() LogLevel {
	if IsDebug() {
		return Debug
	}
	logLevel := os.Getenv("XUI_LOG_LEVEL")
	if logLevel == "" {
		return Info
	}
	return LogLevel(logLevel)
}

func IsDebug() bool {
	return os.Getenv("XUI_DEBUG") == "true"
}

func GetDBPath() string {
	return fmt.Sprintf("%s/%s.db", GetExecPath(), GetName())
}

func GetExecPath() string {
    path, err := os.Executable()
    if err != nil {
        fmt.Println("fail to get exec path:", err)
        return fmt.Sprintf("/etc/%s", GetName())
    }
    return filepath.Dir(path)
}
