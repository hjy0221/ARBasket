# AR Basket

**한국어** | [English](README.en.md)

SwiftUI, ARKit, RealityKit으로 만든 iOS 증강현실 농구 게임 MVP입니다.

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

## 암호화 처리

- **클라이언트:** 데이터를 수신한 뒤 SHA256 해시를 검증하고 복호화합니다.
- **대칭키 암호화:** AES-256-CBC
- **IV:** `bytes(16)` 형식의 16바이트 0 값
- **해시:** SHA256
- **공개키:** RSA-2048

## 기술 구성

- Swift
- SwiftUI
- ARKit
- RealityKit
- XCTest

외부 라이브러리는 사용하지 않습니다.
