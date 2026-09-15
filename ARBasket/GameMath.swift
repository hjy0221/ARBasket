import CoreGraphics
import simd

enum GameMath {
    static func shotVelocity(
        gestureVelocity: CGPoint,
        origin: SIMD3<Float>,
        target: SIMD3<Float>,
        cameraRight: SIMD3<Float>
    ) -> SIMD3<Float> {
        let upwardSpeed = Float(max(0, -gestureVelocity.y))
        let power = min(max((upwardSpeed - 60) / 940, 0), 1)
        let flatRight = safelyNormalized(SIMD3(cameraRight.x, 0, cameraRight.z))
        let sideOffset = min(max(Float(gestureVelocity.x) / 4_500, -0.12), 0.12)
        let adjustedTarget = target + flatRight * sideOffset

        let gravity: Float = 9.81
        let apexHeight = max(origin.y, adjustedTarget.y) + 0.58 + 0.22 * power
        let rise = max(apexHeight - origin.y, 0.1)
        let fall = max(apexHeight - adjustedTarget.y, 0.1)
        let verticalVelocity = sqrt(2 * gravity * rise)
        let flightTime = verticalVelocity / gravity + sqrt(2 * fall / gravity)
        let horizontalDisplacement = SIMD3<Float>(
            adjustedTarget.x - origin.x,
            0,
            adjustedTarget.z - origin.z
        )
        let horizontalVelocity = horizontalDisplacement / max(flightTime, 0.45)

        return horizontalVelocity + SIMD3<Float>(0, verticalVelocity, 0)
    }

    static func passedThroughRim(
        previous: SIMD3<Float>,
        current: SIMD3<Float>,
        rimRadius: Float = 0.20
    ) -> Bool {
        guard previous.y > 0, current.y <= 0 else { return false }
        let crossingProgress = previous.y / (previous.y - current.y)
        let crossingPoint = simd_mix(previous, current, SIMD3<Float>(repeating: crossingProgress))
        let distanceFromCenter = simd_length(SIMD2(crossingPoint.x, crossingPoint.z))
        return distanceFromCenter <= rimRadius
    }

    private static func safelyNormalized(_ vector: SIMD3<Float>) -> SIMD3<Float> {
        let length = simd_length(vector)
        return length > 0.0001 ? vector / length : SIMD3<Float>(1, 0, 0)
    }
}
