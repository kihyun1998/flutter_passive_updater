# Flutter Passive Updater - Go Binary Implementation Plan

## 프로젝트 개요

Flutter 앱의 자동 업데이트를 위한 간단하고 안전한 Go 바이너리 기반 업데이터입니다. 복잡한 데몬이나 백그라운드 서비스 없이, 필요할 때만 실행되는 단순한 업데이터 바이너리로 구현합니다.

## 아키텍처

```
┌─────────────────┐    Execute     ┌──────────────────┐    Update     ┌─────────────────┐
│   Flutter App   │ ─────────────► │  Go Updater      │ ────────────► │  Updated App    │
│     (현재)      │   + zip file   │   (일회성 실행)  │   Extract     │   (새 버전)     │
└─────────────────┘                └──────────────────┘               └─────────────────┘
        │                                │                                      ▲
        │                                │                                      │
        ▼                                ▼                                      │
┌─────────────────┐                ┌──────────────────┐                       │
│    앱 종료      │                │   백업 생성      │ ──────────────────────┘
│                 │                │   해시 검증      │      실행
└─────────────────┘                │   압축 해제      │
                                   │   복구 처리      │
                                   └──────────────────┘
```

## 프로젝트 구조

```
flutter_passive_updater/
├── plan.md                                          # 이 문서
├── lib/
│   ├── flutter_passive_updater.dart                 # Public Dart API
│   ├── flutter_passive_updater_platform_interface.dart
│   └── flutter_passive_updater_method_channel.dart
├── updater/                                         # Go 업데이터 프로젝트
│   ├── main.go                                      # 업데이터 메인 진입점
│   ├── updater/
│   │   ├── core.go                                  # 핵심 업데이트 로직
│   │   ├── backup.go                                # 백업/복구 관리
│   │   ├── hash.go                                  # 해시 검증
│   │   ├── extract.go                               # ZIP 압축 해제
│   │   └── launcher.go                              # 앱 실행 관리
│   ├── go.mod                                       # Go 모듈 파일
│   ├── build.sh                                     # 크로스 플랫폼 빌드 스크립트
│   └── README.md                                    # 업데이터 사용법
├── macos/
│   ├── Classes/
│   │   └── FlutterPassiveUpdaterPlugin.swift        # Flutter 플러그인
│   └── Resources/
│       ├── updater-darwin-amd64                     # macOS Intel 바이너리
│       ├── updater-darwin-arm64                     # macOS Apple Silicon 바이너리
│       └── PrivacyInfo.xcprivacy                    # 기존 파일
├── windows/                                         # Windows 지원 시 추가
│   └── Resources/
│       └── updater-windows-amd64.exe
├── linux/                                          # Linux 지원 시 추가
│   └── Resources/
│       └── updater-linux-amd64
├── example/
│   └── ... (기존 예제 앱)
└── test/
    └── ... (테스트 코드)
```

## 핵심 컴포넌트

### 1. Go 업데이터 바이너리 (일회성 실행)

**실행 방식:**
```bash
./updater <current-app-path> <update-zip-path> <hash> [options]
```

**주요 기능:**
- ZIP 파일 해시 검증
- 현재 앱 백업 생성
- 압축 해제 및 파일 교체
- 실패 시 자동 복구
- 업데이트된 앱 실행

### 2. Flutter 플러그인 (간단한 실행기)

**새로운 API:**
```dart
class FlutterPassiveUpdater {
  // 업데이트 실행 (앱은 자동 종료됨)
  static Future<bool> performUpdate({
    required String updateZipPath,
    required String expectedHash,
  });

  // 업데이터 바이너리 존재 확인
  static Future<bool> isUpdaterAvailable();

  // 현재 앱 경로 가져오기 (디버깅용)
  static Future<String> getCurrentAppPath();
}
```

### 3. 업데이트 워크플로우

```dart
// 사용 예시
await FlutterPassiveUpdater.performUpdate(
  updateZipPath: '/path/to/update.zip',
  expectedHash: 'sha256:abc123...',
);
// 이 시점에서 앱이 종료되고 업데이터가 실행됨
```

## 개발 단계별 구현

각 단계마다 Go 바이너리를 만들고 Flutter 앱에서 실행해서 테스트합니다.

### 단계 0: 기본 재시작만 하는 Go 바이너리
- 아무것도 안하고 그냥 Flutter 앱 다시 실행
- `./updater -app /path/to/current/app.app`
- **Flutter 테스트**: 버튼 눌러서 앱이 종료되고 다시 시작되는지 확인

### 단계 1: ZIP 압축 해제 기능 추가
- ZIP 파일을 임시 폴더에 압축 해제
- 기존 앱과 교체
- 앱 재시작
- **Flutter 테스트**: 실제 업데이트 ZIP으로 앱이 바뀌는지 확인

### 단계 2: 해시 검증 기능 추가
- ZIP 파일 해시 검증 후 업데이트
- 해시 불일치시 업데이트 중단
- **Flutter 테스트**: 올바른 해시/잘못된 해시로 각각 테스트
- **실패 테스트**: `-force-hash-fail` 플래그로 의도적 해시 실패 (배포전 제거)

### 단계 3: 백업/복구 시스템 추가
- 업데이트 전 현재 앱 백업
- 업데이트 실패시 백업에서 복구
- **Flutter 테스트**: 정상 업데이트 및 실패 복구 시나리오
- **실패 테스트**: `-force-extract-fail` 플래그로 의도적 압축해제 실패 (배포전 제거)

### 단계 4: Flutter 플러그인 완전 연동
- Swift에서 Go 바이너리 실행
- 현재 앱 경로 자동 감지
- 에러 처리 및 상태 반환
- **최종 테스트**: 실제 사용자 시나리오 검증

### 테스트용 실패 플래그 (배포전 제거)
- `-force-hash-fail`: 해시 검증 강제 실패
- `-force-extract-fail`: 압축 해제 강제 실패
- `-force-backup-fail`: 백업 생성 강제 실패
- `-force-launch-fail`: 앱 실행 강제 실패

## 사용 시나리오

### 기본 업데이트 워크플로우
```dart
// 1. 업데이트 파일 다운로드 (사용자 구현)
String updateZip = await downloadUpdate();
String expectedHash = await getUpdateHash();

// 2. 업데이트 실행
bool success = await FlutterPassiveUpdater.performUpdate(
  updateZipPath: updateZip,
  expectedHash: expectedHash,
);

// 이 이후 코드는 실행되지 않음 (앱이 종료됨)
```

## 에러 처리 시나리오

1. **해시 불일치**: 업데이트 중단, 기존 앱 유지
2. **압축 해제 실패**: 백업에서 자동 복구
3. **파일 교체 실패**: 백업에서 자동 복구
4. **앱 실행 실패**: 백업에서 복구 후 실행 재시도


## 개발 계획

### Phase 1: Go 업데이터 구현 (2-3일)
- 기본 구조 및 해시 검증
- 백업/복구 시스템
- ZIP 압축 해제 로직
- 앱 실행 로직

### Phase 2: Flutter 플러그인 연동 (1-2일)
- Swift/Kotlin에서 Go 바이너리 실행
- 플랫폼별 앱 경로 감지
- 에러 처리 및 상태 반환

### Phase 3: 테스트 및 최적화 (1-2일)
- End-to-End 테스트
- 다양한 실패 시나리오 테스트
- 크로스 플랫폼 호환성 검증

### Phase 4: 문서화 및 예제 (1일)
- API 문서 작성
- 예제 앱 업데이트
- 사용 가이드 작성

---

**이 방식의 핵심**: 복잡하지 않고, 안전하며, 정확히 필요한 기능만 구현