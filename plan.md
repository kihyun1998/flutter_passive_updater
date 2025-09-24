# Flutter Passive Updater - macOS Implementation Plan

## 프로젝트 개요

Flutter 앱이 종료된 후에도 독립적으로 실행되는 백그라운드 데몬을 통해 Flutter 앱을 자동으로 재시작하는 플러그인을 구현합니다. macOS의 Launch Agent 시스템을 활용하여 시스템 레벨에서 동작하는 안정적인 업데이터를 제공합니다.

## 아키텍처

```
┌─────────────────┐    IPC     ┌──────────────────┐    Launch Agent    ┌─────────────────┐
│   Flutter App   │ ◄─────────► │  Updater Daemon  │ ◄─────────────────► │  macOS System   │
│     (GUI)       │  Commands   │  (Background)    │    Registration     │   Services      │
└─────────────────┘             └──────────────────┘                     └─────────────────┘
        │                                │
        │                                │
        ▼                                ▼
┌─────────────────┐                ┌──────────────────┐
│  Config Files   │                │   Log Files      │
│  (.json, .plist)│                │   (.log, .txt)   │
└─────────────────┘                └──────────────────┘
```

## 프로젝트 구조

```
flutter_passive_updater/
├── plan.md                                          # 이 문서
├── lib/
│   ├── flutter_passive_updater.dart                 # Public Dart API
│   ├── flutter_passive_updater_platform_interface.dart
│   └── flutter_passive_updater_method_channel.dart
├── macos/
│   ├── Classes/
│   │   └── FlutterPassiveUpdaterPlugin.swift        # Flutter 플러그인 (기존)
│   ├── daemon/                                      # 새로 추가할 데몬 프로젝트
│   │   ├── Sources/
│   │   │   ├── main.swift                           # 데몬 메인 진입점
│   │   │   ├── UpdaterDaemon.swift                  # 데몬 핵심 로직
│   │   │   ├── Logger.swift                         # 로깅 시스템
│   │   │   ├── AppLauncher.swift                    # 앱 실행 관리
│   │   │   ├── ConfigManager.swift                  # 설정 파일 관리
│   │   │   └── IPCHandler.swift                     # 프로세스간 통신
│   │   ├── Package.swift                            # Swift Package 매니페스트
│   │   ├── build.sh                                 # 빌드 자동화 스크립트
│   │   └── install.sh                               # 설치 자동화 스크립트
│   ├── Resources/
│   │   ├── com.flutter.passive.updater.plist        # Launch Agent 설정 템플릿
│   │   └── PrivacyInfo.xcprivacy                    # 기존 파일
│   └── flutter_passive_updater.podspec              # 기존 파일
├── example/
│   └── ... (기존 예제 앱)
└── test/
    └── ... (테스트 코드)
```

## 핵심 컴포넌트

### 1. Launch Agent (plist)
macOS 시스템이 관리하는 백그라운드 서비스 등록 파일

```xml
<!-- ~/Library/LaunchAgents/com.flutter.passive.updater.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.flutter.passive.updater</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/{username}/Library/Application Support/FlutterUpdater/updater-daemon</string>
    </array>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/{username}/Library/Logs/FlutterUpdater/daemon.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/{username}/Library/Logs/FlutterUpdater/daemon.error.log</string>
</dict>
</plist>
```

### 2. Updater Daemon (Swift 독립 실행파일)
시스템과 독립적으로 실행되는 백그라운드 프로세스

**주요 기능:**
- Flutter 앱 상태 모니터링
- 설정된 딜레이 후 앱 자동 재시작
- 로그 파일 생성 및 관리
- IPC를 통한 명령 처리

### 3. Flutter 플러그인 확장
기존 플러그인에 데몬 관리 기능 추가

**새로운 메서드:**
```dart
// Dart API
class FlutterPassiveUpdater {
  // 데몬 설치 및 Launch Agent 등록
  Future<bool> installDaemon();

  // 데몬 시작
  Future<bool> startDaemon();

  // 데몬 중지
  Future<bool> stopDaemon();

  // 로그 경로 설정
  Future<bool> setLogPath(String path);

  // 재시작 스케줄링 (초 단위)
  Future<bool> scheduleRestart(int delaySeconds);

  // 데몬 상태 확인
  Future<String> getDaemonStatus();

  // 설정 업데이트
  Future<bool> updateConfig(Map<String, dynamic> config);
}
```

### 4. IPC 통신 시스템
Flutter 앱과 데몬 간의 통신을 위한 파일 기반 메시징

**설정 파일 (JSON):**
```json
// ~/.flutter_updater_config.json
{
  "app_bundle_path": "/path/to/flutter_app.app",
  "log_path": "/Users/username/Library/Logs/FlutterUpdater/updater.log",
  "restart_delay": 5,
  "auto_restart": true,
  "daemon_status": "running",
  "last_update": "2024-09-24T20:00:00Z",
  "commands": {
    "action": "restart",
    "timestamp": "2024-09-24T20:00:00Z",
    "processed": false
  }
}
```

### 5. 로깅 시스템
구조화된 로깅 및 자동 로그 파일 관리

**로그 레벨:**
- `INFO`: 일반 정보
- `WARN`: 경고 사항
- `ERROR`: 오류 발생
- `DEBUG`: 디버그 정보

**로그 형식:**
```
[2024-09-24 20:00:00] [INFO] Daemon started successfully
[2024-09-24 20:00:05] [INFO] Flutter app terminated, scheduling restart in 5 seconds
[2024-09-24 20:00:10] [INFO] Restarting Flutter app: /path/to/app.app
```

## 단계별 구현 계획

### Phase 1: 기본 인프라 구축 (1-2일)
1. **데몬 프로젝트 구조 생성**
   - Swift Package 초기화
   - 기본 디렉토리 구조 생성
   - 빌드 스크립트 작성

2. **Launch Agent 템플릿 작성**
   - plist 파일 템플릿 생성
   - 설치/제거 스크립트 작성

3. **기본 로깅 시스템 구현**
   - Logger.swift 구현
   - 로그 파일 자동 생성
   - 로그 로테이션 기능

### Phase 2: 데몬 핵심 기능 구현 (2-3일)
1. **UpdaterDaemon.swift 구현**
   - 데몬 메인 루프
   - 프로세스 모니터링
   - 설정 파일 감시

2. **AppLauncher.swift 구현**
   - Flutter 앱 실행 로직
   - 딜레이 관리
   - 프로세스 상태 확인

3. **ConfigManager.swift 구현**
   - JSON 설정 파일 읽기/쓰기
   - 설정 검증
   - 기본값 관리

### Phase 3: IPC 통신 시스템 (1-2일)
1. **IPCHandler.swift 구현**
   - 파일 기반 메시징
   - 명령 큐 처리
   - 상태 동기화

2. **명령 처리 시스템**
   - restart, stop, status 명령
   - 비동기 명령 처리
   - 응답 메커니즘

### Phase 4: Flutter 플러그인 확장 (2-3일)
1. **FlutterPassiveUpdaterPlugin.swift 확장**
   - 데몬 관리 메서드 추가
   - Launch Agent 등록/해제
   - 파일 시스템 권한 처리

2. **Dart API 확장**
   - 새로운 메서드 인터페이스
   - 에러 처리
   - 플랫폼별 구현

### Phase 5: 통합 테스트 및 최적화 (2-3일)
1. **End-to-End 테스트**
   - Flutter 앱 → 데몬 설치 → 재시작 테스트
   - 다양한 시나리오 검증
   - 로깅 시스템 검증

2. **최적화 및 버그 수정**
   - 메모리 사용량 최적화
   - 에러 핸들링 강화
   - 사용자 경험 개선

### Phase 6: 문서화 및 배포 준비 (1일)
1. **문서 작성**
   - API 문서
   - 사용 가이드
   - 트러블슈팅 가이드

2. **예제 앱 업데이트**
   - 새로운 기능 시연
   - UI 개선

## 테스트 시나리오

### 기본 워크플로우 테스트
1. **설치 테스트**
   ```
   Flutter 앱 실행 → installDaemon() 호출 → Launch Agent 등록 확인
   ```

2. **재시작 테스트**
   ```
   Flutter 앱 실행 → scheduleRestart(5) 호출 → 앱 종료 → 5초 후 앱 재시작 확인
   ```

3. **로깅 테스트**
   ```
   setLogPath() 설정 → 다양한 동작 수행 → 로그 파일 생성 및 내용 확인
   ```

### 고급 시나리오 테스트
1. **권한 테스트**: macOS 보안 설정에서의 동작
2. **에러 복구 테스트**: 설정 파일 손상, 데몬 크래시 등
3. **동시성 테스트**: 여러 Flutter 앱 인스턴스
4. **리소스 테스트**: 장시간 실행 시 메모리/CPU 사용량

## 기대 결과

이 구현을 완료하면:

1. **Flutter 앱이 종료되어도** 독립적인 데몬이 계속 실행
2. **자동 재시작 기능**으로 앱 가용성 향상
3. **체계적인 로깅**으로 디버깅 및 모니터링 지원
4. **확장 가능한 구조**로 향후 업데이트 기능 추가 용이
5. **macOS 네이티브 통합**으로 안정적인 시스템 레벨 동작

## 주의사항

1. **보안**: macOS에서 데몬 실행을 위한 사용자 권한 필요
2. **권한**: Launch Agent 등록 시 사용자 승인 필요
3. **리소스**: 백그라운드 프로세스의 CPU/메모리 사용량 관리
4. **호환성**: 다양한 macOS 버전에서의 동작 확인 필요

---

**다음 단계**: Phase 1부터 순차적으로 구현 시작