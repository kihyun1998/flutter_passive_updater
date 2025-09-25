package service

import (
	"fmt"
	"os/exec"
	"time"
)

// LauncherService handles app launching logic
type LauncherService struct{}

// NewLauncherService creates a new launcher service
func NewLauncherService() *LauncherService {
	return &LauncherService{}
}

// RestartApp restarts the given application after a delay
func (l *LauncherService) RestartApp(appPath string, logger *Logger) error {
	logger.Info(fmt.Sprintf("Step 0: Basic restart - Starting app: %s", appPath))

	// 2초 대기 (Flutter 앱이 완전히 종료될 시간)
	time.Sleep(2 * time.Second)

	// macOS에서 앱 실행
	err := exec.Command("open", appPath).Start()
	if err != nil {
		return fmt.Errorf("failed to start app: %v", err)
	}

	logger.Info("App restarted successfully!")
	return nil
}