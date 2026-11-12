# AR Basket

[日本語](README.ja.md) · [English](README.md) · [한국어](README.ko.md)

This is an iOS augmented reality basketball game MVP created with SwiftUI, ARKit, and RealityKit.

## App icon

<p align="center">
  <img src="ARBasket/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="180" alt="AR Basket app icon">
</p>

## Game screen

| wall scan | Location information | wall detection | Gameplay |
| --- | --- | --- | --- |
| <img src="docs/images/ar-basket-scanning-en.png" width="160" alt="AR Basket wall scanning screen"> | <img src="docs/images/ar-basket-ready-en.png" width="160" alt="AR Basket goalpost location selection guidance screen"> | <img src="docs/images/ar-basket-wall-detected-en.png" width="160" alt="AR Basket wall detection screen"> | <img src="docs/images/ar-basket-gameplay-en.png" width="160" alt="AR Basket execution screen"> |

## Main features

- Real vertical wall recognition and goal placement
- Recognized wall visualization and AR scanning guidance
- Shoots that reflect the swipe direction and speed
- Physical collision of basketball, goalpost, and backboard
- Score judgment for passing the ring
- Scoreboard and 60 second timer
- Restart function to re-position the goalposts
- Shot correction and wide scoring range for beginners

## Requirements

- Xcode 16 or higher
- iOS 17 or higher
- A physical iPhone or iPad that supports ARKit
- Camera permission

AR games cannot be played on the simulator. You can build and do some testing, but to actually play you'll need an ARKit-enabled device.

## How to run

1. Point the camera at the wall and slowly move it left and right.
2. Tap the wall shown in green or the wall estimated by ARKit to place the goal.
3. Swipe up on the screen to throw the ball.

## How to operate

- **Goal Placement:** Tap on a recognized wall.
- **Shoot:** Swipe up on the screen.
- **Restart:** Press the small restart button on the top scoreboard and then tap the wall again.

## Technical configuration

-Swift
-SwiftUI
-ARKit
- RealityKit
-XCTest

No external libraries are used.
