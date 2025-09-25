#!/usr/bin/env dart

import 'dart:io';

/// Build script for Go updater binaries
/// Usage: dart run tool/build.dart
void main() async {
  print('🔨 Building Go updater binaries for macOS...');

  final projectRoot = Directory.current.path;
  final updaterDir = '$projectRoot/updater';
  final outputDir = '$projectRoot/macos/Resources';

  // Create output directory if it doesn't exist
  await Directory(outputDir).create(recursive: true);

  try {
    // Build for macOS Intel (amd64)
    print('📦 Building for macOS Intel (amd64)...');
    await _buildBinary(
      updaterDir,
      '$outputDir/updater-darwin-amd64',
      'darwin',
      'amd64',
    );

    // Build for macOS Apple Silicon (arm64)
    print('📦 Building for macOS Apple Silicon (arm64)...');
    await _buildBinary(
      updaterDir,
      '$outputDir/updater-darwin-arm64',
      'darwin',
      'arm64',
    );

    // Create Universal Binary
    print('🔗 Creating Universal Binary...');
    await Process.run('lipo', [
      '-create',
      '$outputDir/updater-darwin-amd64',
      '$outputDir/updater-darwin-arm64',
      '-output',
      '$outputDir/updater-darwin-universal',
    ]);

    // Make binaries executable
    await Process.run('chmod', ['+x', '$outputDir/updater-darwin-amd64']);
    await Process.run('chmod', ['+x', '$outputDir/updater-darwin-arm64']);
    await Process.run('chmod', ['+x', '$outputDir/updater-darwin-universal']);

    print('✅ Build completed!');
    print('   - $outputDir/updater-darwin-amd64');
    print('   - $outputDir/updater-darwin-arm64');
    print('   - $outputDir/updater-darwin-universal (recommended)');
    print('');
    print('Now you can test with:');
    print('   cd example && flutter run');
  } catch (e) {
    print('❌ Build failed: $e');
    exit(1);
  }
}

Future<void> _buildBinary(
  String sourceDir,
  String outputPath,
  String goos,
  String goarch,
) async {
  final result = await Process.run(
    'go',
    ['build', '-o', outputPath, '.'],
    workingDirectory: sourceDir,
    environment: {
      'GOOS': goos,
      'GOARCH': goarch,
    },
  );

  if (result.exitCode != 0) {
    throw Exception('Go build failed: ${result.stderr}');
  }
}