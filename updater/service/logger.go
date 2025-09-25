package service

import (
	"fmt"
	"os"
	"path/filepath"
	"time"
)

// Logger provides file-based logging functionality
type Logger struct {
	logFile *os.File
}

// NewLogger creates a new logger with the specified log file path
func NewLogger(logPath string) (*Logger, error) {
	// Create directory if it doesn't exist
	if err := os.MkdirAll(filepath.Dir(logPath), 0755); err != nil {
		return nil, fmt.Errorf("failed to create log directory: %v", err)
	}

	// Open or create log file
	logFile, err := os.OpenFile(logPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		return nil, fmt.Errorf("failed to open log file: %v", err)
	}

	logger := &Logger{
		logFile: logFile,
	}

	// Log session start
	logger.Info("=== Updater session started ===")

	return logger, nil
}

// Info logs an info message
func (l *Logger) Info(message string) {
	l.writeLog("INFO", message)
}

// Error logs an error message
func (l *Logger) Error(message string) {
	l.writeLog("ERROR", message)
}

// writeLog writes a formatted log entry
func (l *Logger) writeLog(level, message string) {
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	logEntry := fmt.Sprintf("[%s] %s: %s\n", timestamp, level, message)

	if l.logFile != nil {
		l.logFile.WriteString(logEntry)
		l.logFile.Sync() // Ensure immediate write
	}
}

// Close closes the log file
func (l *Logger) Close() error {
	if l.logFile != nil {
		l.Info("=== Updater session ended ===")
		return l.logFile.Close()
	}
	return nil
}