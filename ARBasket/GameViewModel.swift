import Foundation

@MainActor
final class GameViewModel: ObservableObject {
    enum Phase: Equatable {
        case scanning
        case ready
        case playing
        case finished
        case unavailable
    }

    @Published private(set) var score = 0
    @Published private(set) var timeRemaining = 60
    @Published private(set) var phase: Phase = .scanning
    @Published private(set) var placementResetToken = 0

    private var timer: Timer?
    @Published private var placementFeedback: String?
    private var placementFeedbackWorkItem: DispatchWorkItem?

    var statusText: String {
        switch phase {
        case .scanning:
            placementFeedback ?? "휴대폰을 좌우로 천천히 움직여 벽을 찾아보세요"
        case .ready:
            placementFeedback ?? "초록색 벽에서 골대 위치를 탭하세요"
        case .playing:
            "위로 스와이프해 슛"
        case .finished:
            ""
        case .unavailable:
            "이 기기에서는 AR을 사용할 수 없습니다"
        }
    }

    func planeDetected() {
        guard phase == .scanning else { return }
        placementFeedback = nil
        placementFeedbackWorkItem?.cancel()
        phase = .ready
    }

    func placementFailed() {
        guard phase == .scanning || phase == .ready else { return }
        placementFeedbackWorkItem?.cancel()
        placementFeedback = phase == .ready
            ? "초록색 영역 안쪽을 탭하세요"
            : "벽을 향한 채 휴대폰을 천천히 좌우로 움직이세요"

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.placementFeedback = nil
        }
        placementFeedbackWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: workItem)
    }

    func hoopPlaced() {
        placementFeedbackWorkItem?.cancel()
        placementFeedback = nil
        score = 0
        timeRemaining = 60
        phase = .playing
        startTimer()
    }

    func addScore() {
        guard phase == .playing else { return }
        score += 1
    }

    func markUnavailable() {
        timer?.invalidate()
        phase = .unavailable
    }

    func requestGameRestart() {
        timer?.invalidate()
        placementFeedbackWorkItem?.cancel()
        placementFeedback = nil
        score = 0
        timeRemaining = 60
        phase = .scanning
        placementResetToken += 1
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self else {
                    timer.invalidate()
                    return
                }
                guard self.phase == .playing else {
                    timer.invalidate()
                    return
                }
                self.timeRemaining -= 1
                if self.timeRemaining <= 0 {
                    self.timeRemaining = 0
                    self.phase = .finished
                    timer.invalidate()
                }
            }
        }
    }
}
