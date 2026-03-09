# BicoBob (비코밥)

macOS 메뉴바에서 바로 확인하는 점심 메뉴 위젯

## Download

| 버전 | 설명 | 다운로드 |
|------|------|----------|
| BicoBob (네이티브) | Swift/SwiftUI | [BicoBob_1.0.0.dmg](https://github.com/dfassf/bicobob/releases/download/v1.0.0/BicoBob_1.0.0.dmg) |
| 비코밥 (Tauri) | React/Rust (레거시) | [비코밥_1.0.0_aarch64.dmg](https://github.com/dfassf/bicobob/releases/download/v1.0.0/비코밥_1.0.0_aarch64.dmg) |

## Features

- Slack 채널에서 주간 점심 메뉴 이미지 자동 수집
- Gemini AI로 메뉴 이미지 분석 (요일별 중식/석식 파싱)
- 주간 캐싱 + 3분 쿨다운으로 불필요한 API 호출 방지
- 요일별 메뉴 네비게이션 (월~금)
- 원본 메뉴 이미지 뷰어 (클릭 줌 지원)
- 점심시간 알림 (커스텀 시간 설정)
- 로그인 시 자동 실행

## Tech Stack

- **Swift** + **SwiftUI** + **AppKit**
- `NSPanel` + `NSVisualEffectView(.menu)` — 네이티브 macOS 메뉴 스타일
- `NSStatusItem` — 메뉴바 트레이 아이콘
- `URLSession` — Slack / Gemini API 통신
- `SMAppService` — Launch at Login
- `UserDefaults` — 설정 저장
- `UNUserNotificationCenter` — 알림

## Project Structure

```
BicoBob/Sources/
├── App/                    # 앱 진입점, AppDelegate, StatusBarPanel
├── Models/                 # 데이터 모델, 날짜 유틸
├── ViewModels/             # LunchViewModel
├── Views/                  # SwiftUI 뷰
│   └── Components/         # ButtonStyles, MenuSection 등
└── Services/               # Slack, Gemini, Cache, Settings, LaunchAtLogin
```

## Setup

1. `.env` 파일 생성 (`.env.example` 참고)

```
SLACK_TOKEN=xoxp-your-token
CHANNEL_NAME=채널명
USERNAME=사용자명
GEMINI_API_KEY=your-api-key
```

2. Xcode 프로젝트 생성 및 빌드

```bash
brew install xcodegen  # 없으면 설치
xcodegen generate
open BicoBob.xcodeproj
# Cmd+R로 실행
```

또는 CLI 빌드:

```bash
xcodegen generate
xcodebuild -project BicoBob.xcodeproj -scheme BicoBob -configuration Release build
```

## Requirements

- macOS 14.0+
- Xcode 16.0+
- Slack User Token (`xoxp-`) with `search:read`, `users:read`, `files:read` scopes
- Gemini API Key
