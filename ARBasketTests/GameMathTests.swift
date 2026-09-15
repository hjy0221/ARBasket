import CoreGraphics
import XCTest
@testable import ARBasket

final class GameMathTests: XCTestCase {
    func testFasterUpwardSwipeProducesStrongerShot() {
        let forward = SIMD3<Float>(0, 0, -1)
        let right = SIMD3<Float>(1, 0, 0)
        let slow = GameMath.shotVelocity(
            gestureVelocity: CGPoint(x: 0, y: -300),
            origin: .zero,
            target: forward * 2 + SIMD3<Float>(0, 0.5, 0),
            cameraRight: right
        )
        let fast = GameMath.shotVelocity(
            gestureVelocity: CGPoint(x: 0, y: -1_200),
            origin: .zero,
            target: forward * 2 + SIMD3<Float>(0, 0.5, 0),
            cameraRight: right
        )

        XCTAssertGreaterThan(fast.y, slow.y)
    }

    func testHorizontalSwipeAddsSideVelocity() {
        let velocity = GameMath.shotVelocity(
            gestureVelocity: CGPoint(x: 500, y: -700),
            origin: .zero,
            target: SIMD3<Float>(0, 0.5, -2),
            cameraRight: SIMD3<Float>(1, 0, 0)
        )

        XCTAssertGreaterThan(velocity.x, 0)
        XCTAssertLessThan(velocity.x, 0.25)
    }

    func testDownwardCrossingInsideRimScores() {
        XCTAssertTrue(GameMath.passedThroughRim(
            previous: SIMD3<Float>(0.05, 0.1, 0.04),
            current: SIMD3<Float>(0.06, -0.03, 0.04)
        ))
    }

    func testCrossingOutsideRimDoesNotScore() {
        XCTAssertFalse(GameMath.passedThroughRim(
            previous: SIMD3<Float>(0.4, 0.1, 0),
            current: SIMD3<Float>(0.4, -0.03, 0)
        ))
    }

    func testUpwardCrossingDoesNotScore() {
        XCTAssertFalse(GameMath.passedThroughRim(
            previous: SIMD3<Float>(0, -0.1, 0),
            current: SIMD3<Float>(0, 0.1, 0)
        ))
    }

    func testCrossingUsesInterpolatedPosition() {
        XCTAssertTrue(GameMath.passedThroughRim(
            previous: SIMD3<Float>(0, 0.1, 0),
            current: SIMD3<Float>(0.4, -0.1, 0)
        ))
    }

    func testNearRimEdgeStillScores() {
        XCTAssertTrue(GameMath.passedThroughRim(
            previous: SIMD3<Float>(0.18, 0.08, 0),
            current: SIMD3<Float>(0.18, -0.04, 0)
        ))
    }
}
