#!/bin/bash

# Flutter Passive Updater - Go Binary Build Script

set -e

echo "🔨 Building Go updater binaries for macOS..."

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Output directory
OUTPUT_DIR="$PROJECT_ROOT/macos/Resources"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Build for macOS Intel (amd64)
echo "📦 Building for macOS Intel (amd64)..."
cd "$SCRIPT_DIR"
GOOS=darwin GOARCH=amd64 go build -o "$OUTPUT_DIR/updater-darwin-amd64" .

# Build for macOS Apple Silicon (arm64)
echo "📦 Building for macOS Apple Silicon (arm64)..."
GOOS=darwin GOARCH=arm64 go build -o "$OUTPUT_DIR/updater-darwin-arm64" .

# Create Universal Binary
echo "🔗 Creating Universal Binary..."
lipo -create "$OUTPUT_DIR/updater-darwin-amd64" "$OUTPUT_DIR/updater-darwin-arm64" -output "$OUTPUT_DIR/updater-darwin-universal"

# Make binaries executable
chmod +x "$OUTPUT_DIR/updater-darwin-amd64"
chmod +x "$OUTPUT_DIR/updater-darwin-arm64"
chmod +x "$OUTPUT_DIR/updater-darwin-universal"

echo "✅ Build completed!"
echo "   - $OUTPUT_DIR/updater-darwin-amd64"
echo "   - $OUTPUT_DIR/updater-darwin-arm64"
echo "   - $OUTPUT_DIR/updater-darwin-universal (recommended)"
echo ""
echo "Now you can test with:"
echo "   cd example && flutter run"