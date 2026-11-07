# AR Basket

[日本語](https://github.com/hjy0221/ARBasket#%E6%97%A5%E6%9C%AC%E8%AA%9E) · [English](https://github.com/hjy0221/ARBasket#english) · [한국어](https://github.com/hjy0221/ARBasket#%ED%95%9C%EA%B5%AD%EC%96%B4)

## 日本語

SwiftUI、ARKit、RealityKit で作られた iOS 向け AR バスケットボールゲームの MVP です。

### アプリアイコン

<p align="center">
  <img src="ARBasket/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="180" alt="AR Basket app icon">
</p>

### ゲーム画面

| Wall Scan | Placement Guide | Wall Detected | Gameplay |
| --- | --- | --- | --- |
| <img src="docs/images/ar-basket-scanning.jpg" width="160" alt="AR Basket wall scan"> | <img src="docs/images/ar-basket-ready.jpg" width="160" alt="AR Basket placement guide"> | <img src="docs/images/ar-basket-wall-detected.jpg" width="160" alt="AR Basket wall detected"> | <img src="docs/images/ar-basket-gameplay.jpg" width="160" alt="AR Basket gameplay"> |

### 機能

- 垂直な壁の検出とゴール設置、スキャン案内
- スワイプの方向と速度に応じたシュート
- ボール、リング、バックボードの物理衝突と得点判定
- スコアボード、60秒タイマー、ゴール位置を変える再スタート
- 初心者向けの照準補正と得点判定の許容範囲

### 必要環境

Xcode 16 以降、iOS 17 以降、ARKit 対応の実機 iPhone / iPad、カメラの使用許可が必要です。シミュレーターではビルドや一部のテストはできますが、AR ゲームのプレイには対応する実機が必要です。

### 実行と操作

1. Xcode で `ARBasket.xcodeproj` を開き、実機と開発チームを選択して実行します。
2. カメラを壁に向け、デバイスをゆっくり左右に動かします。
3. 検出された壁または ARKit が推定した壁をタップしてゴールを設置します。
4. 上にスワイプしてシュートします。再スタートするにはスコアボードのボタンを押し、壁を再選択します。

Swift、SwiftUI、ARKit、RealityKit、XCTest を使用し、外部ライブラリには依存しません。

## English

AR Basket is an iOS augmented-reality basketball MVP built with SwiftUI, ARKit, and RealityKit.

## App Icon

<p align="center">
  <img src="ARBasket/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="180" alt="AR Basket app icon">
</p>

## Gameplay

| Wall Scan | Placement Guide | Wall Detected | Gameplay |
| --- | --- | --- | --- |
| <img src="docs/images/ar-basket-scanning.jpg" width="160" alt="AR Basket wall scanning screen"> | <img src="docs/images/ar-basket-ready.jpg" width="160" alt="AR Basket hoop placement guidance screen"> | <img src="docs/images/ar-basket-wall-detected.jpg" width="160" alt="AR Basket detected wall screen"> | <img src="docs/images/ar-basket-gameplay.jpg" width="160" alt="AR Basket gameplay screenshot"> |

## Features

- Vertical wall detection and wall-mounted hoop placement
- Detected-wall visualization and AR scanning guidance
- Swipe shooting based on gesture direction and speed
- Physics collisions for the ball, rim, and backboard
- Score detection when the ball passes through the rim
- Scoreboard and 60-second timer
- Restart flow for choosing a new hoop position
- Beginner-friendly aim assistance and scoring tolerance

## Requirements

- Xcode 16 or later
- iOS 17 or later
- A physical ARKit-compatible iPhone or iPad
- Camera permission

AR gameplay is not available in the simulator. The project can compile and run some tests there, but gameplay requires a physical ARKit-compatible device.

## Run

1. Open `ARBasket.xcodeproj` in Xcode.
2. Select the iPhone or iPad you want to use.
3. Choose your development team under Signing & Capabilities.
4. Build and run the app.
5. Point the camera at a wall and move the device slowly from side to side.
6. Tap a green detected wall or a vertical surface estimated by ARKit to place the hoop.
7. Swipe upward on the screen to shoot.

## Controls

- **Place hoop:** Tap a detected wall.
- **Shoot:** Swipe upward on the screen.
- **Restart:** Tap the small restart button in the top scoreboard, then tap a wall again.

## Technology

- Swift
- SwiftUI
- ARKit
- RealityKit
- XCTest

The project has no external dependencies.

## 한국어

SwiftUI, ARKit, RealityKit으로 만든 iOS 증강현실 농구 게임 MVP입니다.

## 앱 아이콘

<p align="center">
  <img src="ARBasket/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="180" alt="AR Basket 앱 아이콘">
</p>

## 게임 화면

| 벽 스캔 | 위치 안내 | 벽 감지 | 게임 플레이 |
| --- | --- | --- | --- |
| <img src="docs/images/ar-basket-scanning.jpg" width="160" alt="AR Basket 벽 스캔 화면"> | <img src="docs/images/ar-basket-ready.jpg" width="160" alt="AR Basket 골대 위치 선택 안내 화면"> | <img src="docs/images/ar-basket-wall-detected.jpg" width="160" alt="AR Basket 벽 감지 화면"> | <img src="docs/images/ar-basket-gameplay.jpg" width="160" alt="AR Basket 실행 화면"> |

## 주요 기능

- 실제 수직 벽 인식 및 골대 배치
- 인식된 벽 시각화와 AR 스캔 안내
- 스와이프 방향과 속도를 반영한 슛
- 농구공, 골대, 백보드의 물리 충돌
- 링 통과 득점 판정
- 점수판과 60초 타이머
- 골대 위치를 다시 지정할 수 있는 재시작 기능
- 초보자를 위한 슛 보정과 넓은 득점 범위

## 요구 사항

- Xcode 16 이상
- iOS 17 이상
- ARKit을 지원하는 실제 iPhone 또는 iPad
- 카메라 권한

AR 게임은 시뮬레이터에서 플레이할 수 없습니다. 빌드와 일부 테스트는 가능하지만 실제 플레이에는 ARKit 지원 기기가 필요합니다.

## 실행 방법

1. 카메라를 벽에 향한 채 천천히 좌우로 움직입니다.
2. 초록색으로 표시된 벽 또는 ARKit이 추정한 벽을 탭해 골대를 배치합니다.
3. 화면을 위로 스와이프해 공을 던집니다.

## 조작 방법

- **골대 배치:** 인식된 벽을 탭합니다.
- **슛:** 화면을 위로 스와이프합니다.
- **다시 시작:** 상단 점수판의 작은 재시작 버튼을 누른 뒤 벽을 다시 탭합니다.

## 기술 구성

- Swift
- SwiftUI
- ARKit
- RealityKit
- XCTest

외부 라이브러리는 사용하지 않습니다.
