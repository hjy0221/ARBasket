import SwiftUI

struct ContentView: View {
    @StateObject private var game = GameViewModel()

    var body: some View {
        ZStack {
            ARGameView(game: game)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                scoreboard
                Spacer()
                statusPanel
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .preferredColorScheme(.dark)
    }

    private var scoreboard: some View {
        HStack(spacing: 12) {
            metric(title: "SCORE", value: "\(game.score)")
            Spacer()

            if game.phase == .playing || game.phase == .finished {
                Button {
                    game.requestGameRestart()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 36, height: 36)
                        .background(.orange, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("게임 다시 시작")
            }

            Spacer()
            metric(title: "TIME", value: String(format: "0:%02d", game.timeRemaining))
        }
        .padding(.horizontal, 18)
        .frame(height: 64)
        .background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: title == "SCORE" ? .leading : .trailing, spacing: 1) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .monospacedDigit()
        }
        .frame(width: 78, alignment: title == "SCORE" ? .leading : .trailing)
    }

    @ViewBuilder
    private var statusPanel: some View {
        Label(statusMessage, systemImage: statusIcon)
            .font(.subheadline.weight(.semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(statusColor)
            .padding(.horizontal, 16)
            .frame(minHeight: 42)
            .background(.black.opacity(0.72), in: Capsule())
            .padding(.bottom, 24)
    }

    private var statusMessage: String {
        game.phase == .finished ? "게임 종료" : game.statusText
    }

    private var statusIcon: String {
        switch game.phase {
        case .scanning:
            "viewfinder"
        case .ready:
            "checkmark.circle.fill"
        case .playing:
            "arrow.up.circle.fill"
        case .finished:
            "clock.badge.checkmark"
        case .unavailable:
            "exclamationmark.triangle.fill"
        }
    }

    private var statusColor: Color {
        switch game.phase {
        case .ready:
            .green
        case .scanning:
            .orange
        default:
            .white
        }
    }
}
