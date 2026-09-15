import ARKit
import RealityKit
import SwiftUI
import UIKit

struct ARGameView: UIViewRepresentable {
    @ObservedObject var game: GameViewModel

    func makeUIView(context: Context) -> ARBasketView {
        let view = ARBasketView(frame: .zero)
        view.configure(game: game)
        context.coordinator.view = view
        return view
    }

    func updateUIView(_ uiView: ARBasketView, context: Context) {
        if context.coordinator.lastPlacementResetToken != game.placementResetToken {
            context.coordinator.lastPlacementResetToken = game.placementResetToken
            uiView.resetPlacement()
        }

        uiView.isShootingEnabled = game.phase == .playing
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        weak var view: ARBasketView?
        var lastPlacementResetToken = 0
    }
}

final class ARBasketView: ARView, ARSessionDelegate {
    private var game: GameViewModel!
    private var hoopAnchor: AnchorEntity?
    private var ballAnchor: AnchorEntity?
    private var rimCenter: Entity?
    private var ball: ModelEntity?
    private var previousBallPositionInRimSpace: SIMD3<Float>?
    private var didScoreCurrentBall = false
    private var wallVisualizationAnchors: [UUID: AnchorEntity] = [:]
    private var floorColliderAnchors: [UUID: AnchorEntity] = [:]
    private var displayLink: CADisplayLink?
    private var ballResetWorkItem: DispatchWorkItem?
    private let coachingOverlay = ARCoachingOverlayView()

    var isShootingEnabled = false

    @MainActor required dynamic init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
    }

    func configure(game: GameViewModel) {
        guard self.game == nil else { return }
        self.game = game
        configureView()
        startSession()
    }

    @MainActor required dynamic init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        displayLink?.invalidate()
    }

    private func configureView() {
        environment.sceneUnderstanding.options = []
        renderOptions.insert(.disableMotionBlur)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        addGestureRecognizer(pan)

        coachingOverlay.session = session
        coachingOverlay.goal = .tracking
        coachingOverlay.activatesAutomatically = true
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        addSubview(coachingOverlay)
        NSLayoutConstraint.activate([
            coachingOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            coachingOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            coachingOverlay.topAnchor.constraint(equalTo: topAnchor),
            coachingOverlay.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        displayLink = CADisplayLink(target: self, selector: #selector(updateGameLoop))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func startSession() {
        guard ARWorldTrackingConfiguration.isSupported else {
            game.markUnavailable()
            return
        }

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        configuration.isAutoFocusEnabled = true
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
            configuration.sceneReconstruction = .meshWithClassification
        }
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }
        session.delegate = self
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        coachingOverlay.setActive(true, animated: false)
    }

    func resetPlacement() {
        ballResetWorkItem?.cancel()
        hoopAnchor?.removeFromParent()
        ballAnchor?.removeFromParent()
        wallVisualizationAnchors.values.forEach { $0.removeFromParent() }
        floorColliderAnchors.values.forEach { $0.removeFromParent() }
        hoopAnchor = nil
        ballAnchor = nil
        rimCenter = nil
        ball = nil
        previousBallPositionInRimSpace = nil
        didScoreCurrentBall = false
        wallVisualizationAnchors.removeAll()
        floorColliderAnchors.removeAll()
        startSession()
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        let planes = anchors.compactMap { $0 as? ARPlaneAnchor }
        guard !planes.isEmpty else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            for plane in planes {
                if plane.alignment == .vertical, self.hoopAnchor == nil {
                    self.upsertWallVisualization(for: plane)
                    self.game.planeDetected()
                    self.coachingOverlay.setActive(false, animated: true)
                } else if plane.alignment == .horizontal {
                    self.upsertFloorCollider(for: plane)
                }
            }
        }
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        let planes = anchors.compactMap { $0 as? ARPlaneAnchor }
        guard !planes.isEmpty else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            for plane in planes {
                if plane.alignment == .vertical, self.hoopAnchor == nil {
                    self.upsertWallVisualization(for: plane)
                } else if plane.alignment == .horizontal {
                    self.upsertFloorCollider(for: plane)
                }
            }
        }
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        let identifiers = anchors.map(\.identifier)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            for identifier in identifiers {
                self.wallVisualizationAnchors.removeValue(forKey: identifier)?.removeFromParent()
                self.floorColliderAnchors.removeValue(forKey: identifier)?.removeFromParent()
            }
        }
    }

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        attemptHoopPlacement(at: recognizer.location(in: self))
    }

    private func attemptHoopPlacement(at location: CGPoint) {
        guard hoopAnchor == nil,
              game.phase == .scanning || game.phase == .ready,
              let cameraTransform = session.currentFrame?.camera.transform else {
            return
        }

        guard let wallResult = wallRaycastResult(from: location) else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            game.placementFailed()
            return
        }

        placeHoop(onWallAt: wallResult.worldTransform, cameraTransform: cameraTransform)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        game.hoopPlaced()
    }

    @objc private func handleSwipe(_ recognizer: UIPanGestureRecognizer) {
        guard recognizer.state == .ended,
              isShootingEnabled,
              hoopAnchor != nil,
              let ball,
              ball.physicsBody?.mode != .dynamic,
              let rimCenter,
              let cameraTransform = session.currentFrame?.camera.transform else { return }

        let gestureVelocity = recognizer.velocity(in: self)
        guard gestureVelocity.y < -70 else { return }

        let cameraRight = SIMD3<Float>(
            cameraTransform.columns.0.x,
            cameraTransform.columns.0.y,
            cameraTransform.columns.0.z
        )
        let origin = ball.position(relativeTo: nil)
        let target = rimCenter.position(relativeTo: nil) + SIMD3<Float>(0, 0.015, 0)
        let launchVelocity = GameMath.shotVelocity(
            gestureVelocity: gestureVelocity,
            origin: origin,
            target: target,
            cameraRight: cameraRight
        )

        ball.physicsBody?.mode = .dynamic
        ball.physicsMotion = PhysicsMotionComponent(
            linearVelocity: launchVelocity,
            angularVelocity: safelyNormalized(cameraRight) * -10
        )
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        scheduleBallReset()
    }

    private func wallRaycastResult(from location: CGPoint) -> ARRaycastResult? {
        raycast(from: location, allowing: .existingPlaneGeometry, alignment: .vertical).first
            ?? raycast(from: location, allowing: .existingPlaneInfinite, alignment: .vertical).first
            ?? raycast(from: location, allowing: .estimatedPlane, alignment: .vertical).first
    }

    private func placeHoop(onWallAt wallTransform: simd_float4x4, cameraTransform: simd_float4x4) {
        let wallPosition = translation(of: wallTransform)
        let cameraPosition = translation(of: cameraTransform)
        var wallNormal = safelyNormalized(SIMD3<Float>(
            wallTransform.columns.1.x,
            wallTransform.columns.1.y,
            wallTransform.columns.1.z
        ))
        if simd_dot(wallNormal, cameraPosition - wallPosition) < 0 {
            wallNormal *= -1
        }

        let worldUp = SIMD3<Float>(0, 1, 0)
        let right = safelyNormalized(simd_cross(worldUp, wallNormal))
        let correctedUp = safelyNormalized(simd_cross(wallNormal, right))
        var hoopTransform = matrix_identity_float4x4
        hoopTransform.columns.0 = SIMD4<Float>(right.x, right.y, right.z, 0)
        hoopTransform.columns.1 = SIMD4<Float>(correctedUp.x, correctedUp.y, correctedUp.z, 0)
        hoopTransform.columns.2 = SIMD4<Float>(wallNormal.x, wallNormal.y, wallNormal.z, 0)
        let mountedPosition = wallPosition + wallNormal * 0.025
        hoopTransform.columns.3 = SIMD4<Float>(mountedPosition.x, mountedPosition.y, mountedPosition.z, 1)

        let anchor = AnchorEntity(world: hoopTransform)

        let rimMaterial = SimpleMaterial(
            color: UIColor(red: 0.92, green: 0.18, blue: 0.035, alpha: 1),
            roughness: 0.34,
            isMetallic: true
        )
        let frameMaterial = SimpleMaterial(color: .white, roughness: 0.35, isMetallic: false)
        let darkMaterial = SimpleMaterial(
            color: UIColor(red: 0.10, green: 0.11, blue: 0.13, alpha: 1),
            roughness: 0.62,
            isMetallic: true
        )
        let boardMaterial = SimpleMaterial(
            color: UIColor(red: 0.80, green: 0.92, blue: 0.96, alpha: 0.34),
            roughness: 0.12,
            isMetallic: false
        )

        let boardSize = SIMD3<Float>(1.08, 0.64, 0.028)
        let board = boxEntity(size: boardSize, material: boardMaterial, collidable: true)
        anchor.addChild(board)

        addBackboardFrame(to: anchor, material: frameMaterial)
        addTargetSquare(to: anchor, material: rimMaterial)

        let lowerMount = boxEntity(size: [0.16, 0.12, 0.22], material: darkMaterial, collidable: true)
        lowerMount.position = [0, -0.17, 0.12]
        anchor.addChild(lowerMount)

        let rim = Entity()
        rim.name = "rimCenter"
        rim.position = [0, -0.16, 0.40]
        anchor.addChild(rim)
        buildRim(under: rim, rimMaterial: rimMaterial, netMaterial: frameMaterial)

        wallVisualizationAnchors.values.forEach { $0.removeFromParent() }
        wallVisualizationAnchors.removeAll()
        coachingOverlay.setActive(false, animated: true)
        scene.addAnchor(anchor)
        hoopAnchor = anchor
        rimCenter = rim
        spawnBall()
    }

    private func addBackboardFrame(to anchor: Entity, material: SimpleMaterial) {
        let frameDepth: Float = 0.038
        let horizontalSize = SIMD3<Float>(1.12, 0.035, frameDepth)
        let verticalSize = SIMD3<Float>(0.035, 0.68, frameDepth)

        for y: Float in [-0.322, 0.322] {
            let bar = boxEntity(size: horizontalSize, material: material)
            bar.position = [0, y, 0.012]
            anchor.addChild(bar)
        }
        for x: Float in [-0.542, 0.542] {
            let bar = boxEntity(size: verticalSize, material: material)
            bar.position = [x, 0, 0.012]
            anchor.addChild(bar)
        }
    }

    private func addTargetSquare(to anchor: Entity, material: SimpleMaterial) {
        let width: Float = 0.46
        let height: Float = 0.30
        let thickness: Float = 0.022
        let depth: Float = 0.016
        let centerY: Float = -0.045

        for y in [centerY - height / 2, centerY + height / 2] {
            let bar = boxEntity(size: [width, thickness, depth], material: material)
            bar.position = [0, y, 0.026]
            anchor.addChild(bar)
        }
        for x in [-width / 2, width / 2] {
            let bar = boxEntity(size: [thickness, height, depth], material: material)
            bar.position = [x, centerY, 0.026]
            anchor.addChild(bar)
        }
    }

    private func buildRim(
        under parent: Entity,
        rimMaterial: SimpleMaterial,
        netMaterial: SimpleMaterial
    ) {
        let radius: Float = 0.275
        let points = circlePoints(radius: radius, y: 0, count: 28)

        addClosedTube(
            points: points,
            radius: 0.018,
            material: rimMaterial,
            collidable: true,
            to: parent
        )

        parent.addChild(cylinderSegment(
            from: [0, 0, -0.39],
            to: [0, 0, -radius],
            radius: 0.024,
            material: rimMaterial,
            collidable: true
        ))

        buildNet(under: parent, material: netMaterial)
    }

    private func buildNet(under parent: Entity, material: SimpleMaterial) {
        let strandCount = 10
        let radii: [Float] = [0.255, 0.22, 0.18, 0.14]
        let heights: [Float] = [-0.025, -0.13, -0.24, -0.34]

        for level in 0..<(radii.count - 1) {
            for index in 0..<strandCount {
                let startAngle = 2 * Float.pi * Float(index) / Float(strandCount)
                    + (level.isMultiple(of: 2) ? 0 : Float.pi / Float(strandCount))
                let endAngle = 2 * Float.pi * Float(index) / Float(strandCount)
                    + (level.isMultiple(of: 2) ? Float.pi / Float(strandCount) : 0)
                let start = SIMD3<Float>(
                    cos(startAngle) * radii[level],
                    heights[level],
                    sin(startAngle) * radii[level]
                )
                let end = SIMD3<Float>(
                    cos(endAngle) * radii[level + 1],
                    heights[level + 1],
                    sin(endAngle) * radii[level + 1]
                )
                parent.addChild(cylinderSegment(
                    from: start,
                    to: end,
                    radius: 0.004,
                    material: material
                ))
            }
        }

        for level in 1..<radii.count {
            addClosedTube(
                points: circlePoints(radius: radii[level], y: heights[level], count: strandCount),
                radius: 0.0035,
                material: material,
                collidable: false,
                to: parent
            )
        }
    }

    private func spawnBall() {
        guard let cameraTransform = session.currentFrame?.camera.transform else { return }

        ballAnchor?.removeFromParent()
        let radius: Float = 0.12
        let ballMaterial = SimpleMaterial(
            color: UIColor(red: 0.84, green: 0.25, blue: 0.045, alpha: 1),
            roughness: 0.92,
            isMetallic: false
        )
        let newBall = ModelEntity(mesh: .generateSphere(radius: radius), materials: [ballMaterial])
        newBall.name = "basketball"
        newBall.collision = CollisionComponent(shapes: [.generateSphere(radius: radius * 0.92)])
        newBall.physicsBody = PhysicsBodyComponent(
            massProperties: .default,
            material: .generate(friction: 0.58, restitution: 0.76),
            mode: .kinematic
        )
        addBasketballSeams(to: newBall, ballRadius: radius)

        let cameraPosition = translation(of: cameraTransform)
        let cameraForward = safelyNormalized(-SIMD3<Float>(
            cameraTransform.columns.2.x,
            0,
            cameraTransform.columns.2.z
        ))
        newBall.position = cameraPosition + cameraForward * 0.52 + SIMD3<Float>(0, -0.42, 0)

        let anchor = AnchorEntity(world: .zero)
        anchor.addChild(newBall)
        scene.addAnchor(anchor)

        ballAnchor = anchor
        ball = newBall
        previousBallPositionInRimSpace = nil
        didScoreCurrentBall = false
    }

    private func addBasketballSeams(to ball: Entity, ballRadius: Float) {
        let seamMaterial = SimpleMaterial(
            color: UIColor(red: 0.055, green: 0.045, blue: 0.04, alpha: 1),
            roughness: 0.95,
            isMetallic: false
        )
        let radius = ballRadius * 1.01
        let segmentCount = 24

        let horizontal = (0..<segmentCount).map { index -> SIMD3<Float> in
            let angle = 2 * Float.pi * Float(index) / Float(segmentCount)
            return [cos(angle) * radius, 0, sin(angle) * radius]
        }
        let frontVertical = (0..<segmentCount).map { index -> SIMD3<Float> in
            let angle = 2 * Float.pi * Float(index) / Float(segmentCount)
            return [cos(angle) * radius, sin(angle) * radius, 0]
        }
        let sideVertical = (0..<segmentCount).map { index -> SIMD3<Float> in
            let angle = 2 * Float.pi * Float(index) / Float(segmentCount)
            return [0, cos(angle) * radius, sin(angle) * radius]
        }

        for points in [horizontal, frontVertical, sideVertical] {
            addClosedTube(
                points: points,
                radius: 0.0045,
                material: seamMaterial,
                collidable: false,
                to: ball
            )
        }
    }

    private func upsertWallVisualization(for plane: ARPlaneAnchor) {
        wallVisualizationAnchors.removeValue(forKey: plane.identifier)?.removeFromParent()

        let width = max(plane.planeExtent.width, 0.2)
        let height = max(plane.planeExtent.height, 0.2)
        let anchor = AnchorEntity(world: plane.transform)
        let visualization = Entity()
        visualization.position = plane.center
        visualization.orientation = simd_quatf(
            angle: plane.planeExtent.rotationOnYAxis,
            axis: SIMD3<Float>(0, 1, 0)
        )

        let fillMaterial = SimpleMaterial(
            color: UIColor(red: 0.18, green: 0.92, blue: 0.47, alpha: 0.11),
            roughness: 1,
            isMetallic: false
        )
        let borderMaterial = SimpleMaterial(
            color: UIColor(red: 0.24, green: 1, blue: 0.52, alpha: 0.88),
            roughness: 0.8,
            isMetallic: false
        )
        let fill = boxEntity(size: [width, 0.006, height], material: fillMaterial)
        visualization.addChild(fill)

        for z in [-height / 2, height / 2] {
            let edge = boxEntity(size: [width, 0.012, 0.018], material: borderMaterial)
            edge.position = [0, 0.008, z]
            visualization.addChild(edge)
        }
        for x in [-width / 2, width / 2] {
            let edge = boxEntity(size: [0.018, 0.012, height], material: borderMaterial)
            edge.position = [x, 0.008, 0]
            visualization.addChild(edge)
        }

        anchor.addChild(visualization)
        scene.addAnchor(anchor)
        wallVisualizationAnchors[plane.identifier] = anchor
    }

    private func upsertFloorCollider(for plane: ARPlaneAnchor) {
        floorColliderAnchors.removeValue(forKey: plane.identifier)?.removeFromParent()

        let width = max(plane.planeExtent.width, 0.15)
        let depth = max(plane.planeExtent.height, 0.15)
        let anchor = AnchorEntity(world: plane.transform)
        let invisibleMaterial = SimpleMaterial(color: .clear, roughness: 1, isMetallic: false)
        let floor = boxEntity(
            size: [width, 0.025, depth],
            material: invisibleMaterial,
            collidable: true
        )
        floor.position = plane.center + SIMD3<Float>(0, -0.018, 0)
        floor.orientation = simd_quatf(
            angle: plane.planeExtent.rotationOnYAxis,
            axis: SIMD3<Float>(0, 1, 0)
        )
        anchor.addChild(floor)
        scene.addAnchor(anchor)
        floorColliderAnchors[plane.identifier] = anchor
    }

    private func scheduleBallReset() {
        ballResetWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.game.phase == .playing else { return }
            self.spawnBall()
        }
        ballResetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2, execute: workItem)
    }

    @objc private func updateGameLoop() {
        guard let ball, let rimCenter, ball.physicsBody?.mode == .dynamic else { return }
        let current = ball.position(relativeTo: rimCenter)

        if let previous = previousBallPositionInRimSpace,
           !didScoreCurrentBall,
           GameMath.passedThroughRim(previous: previous, current: current) {
            didScoreCurrentBall = true
            game.addScore()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        previousBallPositionInRimSpace = current
    }

    private func addClosedTube(
        points: [SIMD3<Float>],
        radius: Float,
        material: SimpleMaterial,
        collidable: Bool,
        to parent: Entity
    ) {
        guard points.count > 2 else { return }
        for index in points.indices {
            let nextIndex = (index + 1) % points.count
            parent.addChild(cylinderSegment(
                from: points[index],
                to: points[nextIndex],
                radius: radius,
                material: material,
                collidable: collidable
            ))
        }
    }

    private func circlePoints(radius: Float, y: Float, count: Int) -> [SIMD3<Float>] {
        (0..<count).map { index in
            let angle = 2 * Float.pi * Float(index) / Float(count)
            return SIMD3<Float>(cos(angle) * radius, y, sin(angle) * radius)
        }
    }

    private func cylinderSegment(
        from start: SIMD3<Float>,
        to end: SIMD3<Float>,
        radius: Float,
        material: SimpleMaterial,
        collidable: Bool = false
    ) -> ModelEntity {
        let delta = end - start
        let length = max(simd_length(delta), 0.001)
        let segment = ModelEntity(
            mesh: .generateBox(
                size: [radius * 2, length, radius * 2],
                cornerRadius: radius
            ),
            materials: [material]
        )
        segment.position = (start + end) / 2
        segment.orientation = rotationFromYAxis(to: delta)
        if collidable {
            segment.collision = CollisionComponent(shapes: [
                .generateCapsule(height: length, radius: radius)
            ])
            segment.physicsBody = PhysicsBodyComponent(mode: .static)
        }
        return segment
    }

    private func boxEntity(
        size: SIMD3<Float>,
        material: SimpleMaterial,
        collidable: Bool = false
    ) -> ModelEntity {
        let entity = ModelEntity(mesh: .generateBox(size: size), materials: [material])
        if collidable {
            entity.collision = CollisionComponent(shapes: [.generateBox(size: size)])
            entity.physicsBody = PhysicsBodyComponent(mode: .static)
        }
        return entity
    }

    private func rotationFromYAxis(to direction: SIMD3<Float>) -> simd_quatf {
        let target = safelyNormalized(direction)
        let up = SIMD3<Float>(0, 1, 0)
        let dotValue = min(max(simd_dot(up, target), -1), 1)

        if dotValue > 0.9999 {
            return simd_quatf(angle: 0, axis: up)
        }
        if dotValue < -0.9999 {
            return simd_quatf(angle: .pi, axis: SIMD3<Float>(1, 0, 0))
        }

        return simd_quatf(
            angle: acos(dotValue),
            axis: simd_normalize(simd_cross(up, target))
        )
    }

    private func translation(of transform: simd_float4x4) -> SIMD3<Float> {
        SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }

    private func safelyNormalized(_ vector: SIMD3<Float>) -> SIMD3<Float> {
        let length = simd_length(vector)
        return length > 0.0001 ? vector / length : SIMD3<Float>(0, 0, -1)
    }
}
