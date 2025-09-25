package main

import (
	"flag"
	"fmt"
	"log"

	"flutter_passive_updater/service"
)

func main() {
	var appPath = flag.String("app", "", "Current app path to restart")
	var logPath = flag.String("log", "", "Log file path")
	flag.Parse()

	if *appPath == "" {
		log.Fatal("Usage: updater -app /path/to/app.app -log /path/to/log.txt")
	}

	if *logPath == "" {
		log.Fatal("Usage: updater -app /path/to/app.app -log /path/to/log.txt")
	}

	// Initialize logger
	logger, err := service.NewLogger(*logPath)
	if err != nil {
		log.Fatalf("Failed to initialize logger: %v", err)
	}
	defer logger.Close()

	// Initialize launcher service
	launcher := service.NewLauncherService()

	// Restart the app
	if err := launcher.RestartApp(*appPath, logger); err != nil {
		logger.Error(fmt.Sprintf("Failed to restart app: %v", err))
		log.Fatalf("Failed to restart app: %v", err)
	}
}