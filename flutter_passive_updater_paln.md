# `flutter_passive_updater` Plugin Design Document

## 1. 플러그인 개요

`flutter_passive_updater`는 Flutter macOS 데스크톱 애플리케이션을 위한 강력하고 유연한 자동 업데이트 플러그인입니다. Sparkle과 같은 외부 프레임워크에 의존하지 않고, Swift로 구현된 헬퍼 앱을 통해 백그라운드에서 안전하고 매끄러운 업데이트 경험을 제공합니다. 개발자가 업데이트 결정 로직을 커스터마이징하고, 다양한 업데이트 정보 소스를 활용할 수 있도록 설계되었습니다.

## 2. 핵심 철학

*   **투명한 사용자 경험:** 업데이트 과정은 사용자에게 최소한의 개입만 요구하며, 백그라운드에서 조용히 진행됩니다.
*   **개발자 유연성:** 업데이트 정보 소스, 업데이트 결정 로직, 콘텐츠 검증 등 핵심 로직을 개발자가 직접 제어할 수 있도록 합니다.
*   **안정성 및 보안:** 견고한 오류 처리, 무결성 검증, 실패 시 복구 메커니즘을 통해 안정적인 업데이트를 보장합니다.
*   **Flutter 친화적:** Dart API를 통해 네이티브 macOS 업데이트 로직을 쉽게 사용할 수 있도록 추상화합니다.

## 3. 주요 기능

*   **백그라운드 업데이트:** 앱 실행 중 새 버전 다운로드 및 다음 실행 시 자동 적용.
*   **유연한 업데이트 정보 소스:**
    *   원격 서버의 XML/JSON 파일로부터 업데이트 메타데이터 파싱.
    *   다운로드된 `.zip` 파일 자체의 `Info.plist`에서 버전 정보 추출.
*   **커스텀 업데이트 결정 로직:** 개발자가 Dart 콜백 함수를 통해 업데이트 여부를 최종적으로 결정.
*   **커스텀 콘텐츠 검증:** 다운로드 및 압축 해제된 새 앱 번들에 대한 추가적인 개발자 정의 검증 로직 수행.
*   **업데이트 진행 상황 알림:** Dart 스트림/콜백을 통해 다운로드 진행률, 상태 변경 등 알림.
*   **안전한 파일 교체:** 헬퍼 앱을 통한 원자적(atomic) 파일 교체.
*   **무결성 검증:** 다운로드된 `.zip` 파일의 SHA256 해시 검증.
*   **실패 시 자동 복구:** 업데이트 실패 시 기존 앱 번들로 자동 롤백.
*   **업데이트 후 앱 재실행 시 인자 전달:** 업데이트 완료 후 앱 재실행 시 특정 인자를 전달하여 앱 내에서 업데이트 여부 인지 가능.

## 4. 아키텍처 개요

```
+-------------------------------------------------------------------+
|                           Flutter App                             |
| +---------------------------------------------------------------+
| |                       Dart Layer                              |
| | +-----------------------------------------------------------+
| | | `PassiveUpdater` API (init, checkForUpdates, startUpdate) |
| | | - Calls Native via Platform Channel                       |
| | | - Handles Custom Update Decision Callback                 |
| | | - Handles Custom Content Validation Callback              |
| | | - Receives Progress/Status Streams                        |
| | +-----------------------------------------------------------+
| +---------------------------------------------------------------+
|                               |                                   |
|                               v                                   |
| +-------------------------------------------------------------------+
| |                       Native macOS Layer (Plugin)                 |
| | +---------------------------------------------------------------+
| | | `PassiveUpdaterPlugin.swift` (Platform Channel Handler)       |
| | |                                                               |
| | | - Receives Dart calls (e.g., `checkForUpdates`, `startUpdate`)|
| | | - Manages Update Info Fetching (XML/JSON or ZIP analysis)     |
| | | - Downloads .zip file to temporary location                   |
| | | - Triggers Helper App execution (passing necessary args)      |
| | | - Sends progress/status back to Dart via EventChannel         |
| | +---------------------------------------------------------------+
| +-------------------------------------------------------------------+
|                               | (Launches)                        |
|                               v                                   |
| +-------------------------------------------------------------------+
| |                       Helper App (Swift)                          |
| | +---------------------------------------------------------------+
| | | `UpdaterHelper.app` (Bundled within Main App)                 |
| | |                                                               |
| | | - Executed by Native Plugin Layer                             |
| | | - Waits for Main App to terminate                             |
| | | - Performs:                                                   |
| | |   - Backup of old app bundle                                  |
| | |   - Unzips new app bundle                                     |
| | |   - Invokes Custom Content Validation Callback (via IPC)      |
| | |   - Moves new app bundle to original location (atomic replace)|
| | |   - Relaunches Main App (with optional args)                  |
| | |   - Handles rollback on failure                               |
| | +---------------------------------------------------------------+
+-------------------------------------------------------------------+
```

## 5. API 설계 (Dart)

```dart
import 'dart:async';

class PassiveUpdater {
  /// 플러그인을 초기화합니다.
  /// [feedUrl]은 업데이트 메타데이터(XML/JSON)의 URL입니다. 제공되지 않으면 .zip 파일 자체에서 정보를 추출합니다.
  /// [customContentValidationCallback]은 다운로드 및 압축 해제된 새 앱 번들에 대한 추가 검증 로직을 정의합니다.
  static Future<void> init({
    String? feedUrl,
    required Future<bool> Function(UpdateInfo latestUpdate, String unzippedAppPath) customContentValidationCallback,
  }) async {
    // 내부적으로 MethodChannel을 통해 네이티브 초기화 로직 호출
  }

  /// 업데이트 정보를 나타내는 클래스.
  class UpdateInfo {
    final String latestVersion;
    final String releaseNotes; // 릴리스 노트 URL 또는 내용
    final String downloadUrl;   // .zip 파일 다운로드 URL
    final String sha256;        // .zip 파일의 SHA256 해시 (무결성 검증용)
    // 기타 필요한 정보 (예: minimumSystemVersion)

    UpdateInfo({
      required this.latestVersion,
      required this.releaseNotes,
      required this.downloadUrl,
      required this.sha256,
    });
  }

  /// 업데이트를 확인하고 최신 업데이트 정보를 반환합니다.
  /// 업데이트가 없으면 null을 반환합니다.
  static Future<UpdateInfo?> checkForUpdates() async {
    // 내부적으로 네이티브 레이어에서 메타데이터를 가져오고 파싱
    // .zip 파일 자체에서 정보를 추출하는 로직 포함
  }

  /// 업데이트 다운로드 및 설치를 시작합니다.
  /// 이 메서드는 checkForUpdates()를 통해 UpdateInfo를 받은 후 호출되어야 합니다.
  static Future<void> startUpdate() async {
    // 내부적으로 네이티브 레이어에서 다운로드, 헬퍼 앱 실행 로직 호출
  }

  /// 업데이트 진행 상황을 스트리밍합니다.
  /// 다운로드 진행률, 현재 상태 메시지 등을 포함합니다.
  static Stream<UpdateProgress> get onUpdateProgress {
    // EventChannel을 통해 네이티브로부터 진행 상황 스트리밍
  }

  /// 업데이트 상태 변경을 스트리밍합니다.
  /// (예: '다운로드 중', '검증 중', '설치 중', '성공', '실패' 등)
  static Stream<UpdateStatus> get onUpdateStatus {
    // EventChannel을 통해 네이티브로부터 상태 변경 스트리밍
  }

  /// 현재 앱의 버전을 가져옵니다.
  static Future<String> getCurrentAppVersion() async {
    // 네이티브 API를 통해 CFBundleShortVersionString 가져오기
  }

  /// 앱을 재실행합니다. 업데이트 완료 후 또는 특정 상황에서 사용됩니다.
  /// [args]는 재실행될 앱에 전달될 명령줄 인자입니다.
  static Future<void> relaunch({List<String> args = const []}) async {
    // 네이티브 API를 통해 앱 재실행 로직 호출
  }
}

/// 업데이트 진행 상황을 나타내는 클래스.
class UpdateProgress {
  final double progress; // 0.0 ~ 1.0
  final String message;  // 현재 진행 중인 작업 설명
  UpdateProgress(this.progress, this.message);
}

/// 업데이트 상태를 나타내는 enum.
enum UpdateStatus {
  checkingForUpdates,
  downloading,
  verifyingChecksum,
  unzipping,
  backingUp,
  installing,
  customValidation,
  relaunching,
  success,
  failed,
  // 기타 상세 상태
}
```

## 6. 업데이트 정보 처리

*   **서버 기반 (XML/JSON):**
    *   `PassiveUpdater.init()` 시 `feedUrl`이 제공되면, 네이티브 레이어는 해당 URL에서 XML 또는 JSON 파일을 다운로드하여 파싱합니다.
    *   파싱된 데이터는 `UpdateInfo` 객체로 변환되며, 최신 버전, 릴리스 노트, 다운로드 URL, SHA256 해시 등을 포함합니다.
    *   **XML 예시 (Sparkle Appcast와 유사):**
        ```xml
        <item>
            <version>1.0.1</version>
            <releaseNotes>https://yourdomain.com/release_notes_1.0.1.html</releaseNotes>
            <url>https://yourdomain.com/YourApp-1.0.1.zip</url>
            <sha256>...</sha256>
        </item>
        ```
    *   **JSON 예시:**
        ```json
        {
            "version": "1.0.1",
            "releaseNotes": "https://yourdomain.com/release_notes_1.0.1.html",
            "url": "https://yourdomain.com/YourApp-1.0.1.zip",
            "sha256": "..."
        }
        ```
*   **Zip 파일 자체 메타데이터:**
    *   `feedUrl`이 제공되지 않거나, 개발자가 `.zip` 파일 자체에서 정보를 얻도록 설정한 경우, 플러그인은 HTTP Range Request를 사용하여 `.zip` 파일의 특정 부분(예: `.app/Contents/Info.plist` 위치)만 읽어와 버전 정보(CFBundleShortVersionString, CFBundleVersion)를 추출합니다.
    *   이 방식은 서버에서 별도의 메타데이터 파일을 관리할 필요가 없지만, `.zip` 파일 전체를 다운로드해야 SHA256 해시를 검증할 수 있다는 단점이 있습니다.

## 7. 업데이트 시나리오 (사용자 주도)

1.  **사용자 액션: 업데이트 확인 요청**
    *   사용자가 앱 메뉴에서 "업데이트 확인" 버튼 클릭.
    *   **Dart 코드:** `PassiveUpdater.checkForUpdates()` 호출.
2.  **업데이트 메타데이터 가져오기 및 판단**
    *   **플러그인 네이티브 레이어:** `feedUrl` (XML/JSON) 또는 `.zip` 파일 자체에서 최신 버전 메타데이터를 가져와 `UpdateInfo` 객체 생성.
    *   **반환:** `UpdateInfo` 객체 또는 `null` (업데이트 없음)을 Dart로 반환.
3.  **업데이트 여부 사용자에게 표시 및 결정**
    *   **Dart 코드:** `checkForUpdates()`의 반환 값을 받아, `UpdateInfo`가 있다면 사용자에게 업데이트 대화 상자 표시 ("업데이트하시겠습니까?").
    *   사용자는 "업데이트" 또는 "취소" 선택.
4.  **업데이트 시작 요청**
    *   사용자가 "업데이트"를 선택하면, **Dart 코드:** `PassiveUpdater.startUpdate()` 호출.
5.  **새 버전 다운로드 및 무결성 검증**
    *   **플러그인 네이티브 레이어:** `UpdateInfo`에 명시된 `.zip` 파일 다운로드 (진행률 `onUpdateProgress` 스트리밍).
    *   다운로드 완료 후, `.zip` 파일의 SHA256 해시를 메타데이터의 해시 값과 비교하여 무결성 검증. 실패 시 오류 발생 및 업데이트 중단.
6.  **기존 앱 백업 및 앱 종료**
    *   **플러그인 네이티브 레이어:** 현재 실행 중인 메인 앱 번들을 안전한 임시 위치에 백업.
    *   메인 앱 종료.
7.  **헬퍼 앱 실행 및 파일 교체**
    *   **플러그인 네이티브 레이어:** 메인 앱 종료와 동시에 헬퍼 앱 실행. 헬퍼 앱에 다운로드된 `.zip` 파일 경로, 대상 설치 경로, 백업 경로, 커스텀 콘텐츠 검증을 위한 정보 등을 인자로 전달.
    *   **헬퍼 앱:**
        *   메인 앱이 완전히 종료될 때까지 대기.
        *   다운로드된 `.zip` 파일 압축 해제.
        *   **커스텀 콘텐츠 검증:** 압축 해제된 새 앱 번들의 경로를 Dart 레이어의 `customContentValidationCallback`으로 전달. 콜백이 `false` 반환 시 업데이트 실패로 간주.
        *   검증 성공 시, 새 앱 번들을 기존 앱 위치에 덮어쓰기 (원자적 교체).
8.  **업데이트 완료 및 앱 재실행**
    *   **헬퍼 앱:** 파일 교체 성공 시, 새로 설치된 메인 앱을 `PassiveUpdater.relaunch()`를 통해 재실행 (개발자가 지정한 인자 전달 가능).
    *   헬퍼 앱 종료.
9.  **업데이트 실패 시 복구**
    *   **헬퍼 앱:** 다운로드, 해시 검증, 압축 해제, 커스텀 콘텐츠 검증, 파일 교체 중 오류 발생 시, 백업해 둔 기존 앱 번들을 원래 위치로 복원.
    *   복원된 기존 앱을 다시 실행.
    *   **오류 알림:** `onUpdateStatus` 스트림을 통해 업데이트 실패 및 복구 완료 이벤트 전달.

## 8. 오류 처리 및 견고성

*   **롤백 메커니즘:** 업데이트 실패 시, 백업해 둔 기존 앱 번들을 원래 위치로 복원하고 기존 앱을 재실행하여 앱의 가용성을 유지합니다.
*   **상세 오류 보고:** `onUpdateStatus` 스트림을 통해 구체적인 오류 유형(네트워크, 해시 불일치, 파일 시스템, 커스텀 검증 실패 등)을 Dart로 전달하여 개발자가 적절히 대응할 수 있도록 합니다.
*   **재시도 로직:** 네트워크 문제 등으로 인한 일시적인 실패 시, 제한된 횟수만큼 재시도를 고려할 수 있습니다.

## 9. 보안 고려사항

*   **HTTPS 사용:** 업데이트 정보 및 `.zip` 파일 다운로드는 반드시 HTTPS를 통해 이루어져야 합니다.
*   **파일 무결성 검증:** 다운로드된 `.zip` 파일의 SHA256 해시 검증은 필수입니다. 이는 파일이 전송 중 변조되지 않았음을 보장합니다.
*   **디지털 서명 (선택 사항):** SHA256 해시 외에, `.zip` 파일에 대한 추가적인 디지털 서명(예: 코드 서명)을 통해 파일의 신뢰성을 더욱 강화할 수 있습니다. 이는 플러그인 외부에서 처리되어야 합니다.
*   **권한 최소화:** 헬퍼 앱은 필요한 최소한의 권한만 가져야 합니다.
*   **샌드박싱:** 앱이 샌드박스 처리되어 있다면, 업데이트 로직 구현에 제약이 따르므로, 샌드박스 해제 또는 특정 권한 요청에 대한 가이드라인을 제공해야 합니다.

## 10. 개발 및 배포 고려사항

*   **Xcode 프로젝트 통합:** 헬퍼 앱을 메인 Flutter 앱의 Xcode 프로젝트에 통합하여 빌드 프로세스를 단순화합니다. 헬퍼 앱은 메인 앱 번들 내에 리소스로 포함될 수 있습니다.
*   **코드 서명:** 헬퍼 앱과 메인 앱 모두 올바르게 코드 서명되어야 합니다. 이는 macOS 보안 정책에 필수적입니다.
*   **테스트:** 다양한 시나리오(네트워크 불안정, 디스크 공간 부족, 권한 문제, 업데이트 파일 손상 등)에 대한 철저한 테스트가 필요합니다.
*   **문서화:** 플러그인 사용법, `UpdateInfo` 형식, 헬퍼 앱 빌드 및 통합 방법, 배포 가이드 등을 상세히 문서화하여 다른 개발자들이 쉽게 사용할 수 있도록 합니다.
*   **CI/CD 통합:** 업데이트 `.zip` 파일 생성, SHA256 해시 계산, 메타데이터 파일 업데이트 등을 자동화하는 CI/CD 파이프라인 구축을 권장합니다.

---