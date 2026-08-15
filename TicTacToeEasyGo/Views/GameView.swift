import SwiftUI

struct GameView: View {
    @EnvironmentObject private var quota: GameQuotaStore
    @EnvironmentObject private var auth: AuthStore
    @Environment(\.dismiss) private var dismiss
    let mode: GameMode
    let language: AppLanguage

    @State private var engine = GameEngine()
    @State private var computerThinking = false
    @State private var didRecordCurrentGame = false

    private var copy: AppCopy { AppCopy(language: language) }

    var body: some View {
        VStack(spacing: 28) {
            statusView
                .frame(height: 44)

            GeometryReader { geometry in
                let side = min(geometry.size.width, geometry.size.height)
                board(side: side)
                    .frame(width: side, height: side)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .aspectRatio(1, contentMode: .fit)

            if engine.result != .inProgress {
                Button(copy.text(.playAgain)) { restart() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .navigationTitle(modeTitle)
        .navigationBarTitleDisplayMode(.inline)
        .disabled(computerThinking)
        .onChange(of: engine.result) { _, newResult in
            guard newResult != .inProgress, !didRecordCurrentGame else { return }
            didRecordCurrentGame = true
            if auth.isAuthenticated {
                Task { await auth.consumeBonusGame() }
            } else {
                quota.recordCompletedGame()
            }
        }
    }

    private var statusView: some View {
        Group {
            switch engine.result {
            case .inProgress:
                if computerThinking {
                    Label(copy.text(.computerTurn), systemImage: "ellipsis")
                } else if mode == .twoPlayers {
                    Text(String(format: copy.text(.playerTurn), engine.currentPlayer.rawValue))
                } else {
                    Text(copy.text(.yourTurn))
                }
            case .draw:
                Text(copy.text(.draw))
            case .won(.x, _):
                Text(copy.text(.xWon))
            case .won(.o, _):
                Text(copy.text(.oWon))
            }
        }
        .font(.title3.bold())
    }

    private func board(side: CGFloat) -> some View {
        let gap: CGFloat = 8
        let cellSize = (side - gap * 2) / 3

        return ZStack {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: gap), count: 3), spacing: gap) {
                ForEach(0..<9, id: \.self) { index in
                    Button { play(at: index) } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.secondary.opacity(0.10))
                            if let mark = engine.board[index] {
                                Text(mark.rawValue)
                                    .font(.system(size: cellSize * 0.55, weight: .bold, design: .rounded))
                                    .foregroundStyle(mark == .x ? .indigo : .mint)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(engine.board[index] != nil || engine.result != .inProgress)
                    .frame(width: cellSize, height: cellSize)
                }
            }

            if case let .won(_, line) = engine.result {
                WinLineShape(cells: line.cells, gap: gap, extensionLength: cellSize * 0.22)
                    .stroke(.pink, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .allowsHitTesting(false)
            }
        }
    }

    private func play(at index: Int) {
        guard engine.play(at: index) else { return }
        guard engine.result == .inProgress, mode != .twoPlayers else { return }

        computerThinking = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            let move = mode == .professional
                ? GameEngine.professionalMove(on: engine.board)
                : GameEngine.beginnerMove(on: engine.board)
            if let move { _ = engine.play(at: move) }
            computerThinking = false
        }
    }

    private func restart() {
        let canStart = auth.isAuthenticated ? auth.bonusGamesRemaining > 0 : quota.canStartGame
        guard canStart else {
            dismiss()
            return
        }
        engine.reset()
        didRecordCurrentGame = false
    }

    private var modeTitle: String {
        switch mode {
        case .beginner: copy.text(.beginner)
        case .professional: copy.text(.professional)
        case .twoPlayers: copy.text(.twoPlayers)
        }
    }
}

private struct WinLineShape: Shape {
    let cells: [Int]
    let gap: CGFloat
    let extensionLength: CGFloat

    func path(in rect: CGRect) -> Path {
        guard let first = cells.first, let last = cells.last else { return Path() }
        let cellWidth = (rect.width - gap * 2) / 3
        let cellHeight = (rect.height - gap * 2) / 3

        func center(for index: Int) -> CGPoint {
            CGPoint(
                x: CGFloat(index % 3) * (cellWidth + gap) + cellWidth / 2,
                y: CGFloat(index / 3) * (cellHeight + gap) + cellHeight / 2
            )
        }

        let firstCenter = center(for: first)
        let lastCenter = center(for: last)
        let dx = lastCenter.x - firstCenter.x
        let dy = lastCenter.y - firstCenter.y
        let distance = max(hypot(dx, dy), 1)
        let unit = CGVector(dx: dx / distance, dy: dy / distance)
        let start = CGPoint(
            x: firstCenter.x - unit.dx * extensionLength,
            y: firstCenter.y - unit.dy * extensionLength
        )
        let end = CGPoint(
            x: lastCenter.x + unit.dx * extensionLength,
            y: lastCenter.y + unit.dy * extensionLength
        )

        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        return path
    }
}
