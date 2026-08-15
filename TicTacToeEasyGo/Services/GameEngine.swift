import Foundation

struct GameEngine: Sendable {
    private(set) var board: [Mark?] = Array(repeating: nil, count: 9)
    private(set) var currentPlayer: Mark = .x
    private(set) var result: GameResult = .inProgress

    mutating func play(at index: Int) -> Bool {
        guard board.indices.contains(index), board[index] == nil, result == .inProgress else {
            return false
        }

        board[index] = currentPlayer
        result = Self.result(for: board)
        if result == .inProgress {
            currentPlayer = currentPlayer.opponent
        }
        return true
    }

    mutating func reset() {
        board = Array(repeating: nil, count: 9)
        currentPlayer = .x
        result = .inProgress
    }

    static func result(for board: [Mark?]) -> GameResult {
        for line in WinningLine.all {
            let first = board[line.cells[0]]
            if let first,
               board[line.cells[1]] == first,
               board[line.cells[2]] == first {
                return .won(first, line)
            }
        }
        return board.contains(where: { $0 == nil }) ? .inProgress : .draw
    }

    static func beginnerMove(on board: [Mark?], random: () -> Double = { Double.random(in: 0..<1) }) -> Int? {
        if let winningMove = immediateMove(for: .o, on: board) { return winningMove }
        if random() < 0.75, let blockingMove = immediateMove(for: .x, on: board) { return blockingMove }
        if board[4] == nil { return 4 }

        let corners = [0, 2, 6, 8].filter { board[$0] == nil }
        if !corners.isEmpty, random() < 0.6 {
            return corners[min(Int(random() * Double(corners.count)), corners.count - 1)]
        }

        let empty = board.indices.filter { board[$0] == nil }
        guard !empty.isEmpty else { return nil }
        return empty[min(Int(random() * Double(empty.count)), empty.count - 1)]
    }

    static func professionalMove(on board: [Mark?]) -> Int? {
        let moves = board.indices.filter { board[$0] == nil }
        guard !moves.isEmpty else { return nil }

        var bestScore = Int.min
        var bestMove = moves[0]
        for move in moves {
            var candidate = board
            candidate[move] = .o
            let score = minimax(board: candidate, maximizing: false, depth: 0)
            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }
        return bestMove
    }

    private static func immediateMove(for mark: Mark, on board: [Mark?]) -> Int? {
        for line in WinningLine.all {
            let marks = line.cells.map { board[$0] }
            if marks.filter({ $0 == mark }).count == 2,
               let emptyOffset = marks.firstIndex(where: { $0 == nil }) {
                return line.cells[emptyOffset]
            }
        }
        return nil
    }

    private static func minimax(board: [Mark?], maximizing: Bool, depth: Int) -> Int {
        switch result(for: board) {
        case .won(.o, _): return 10 - depth
        case .won(.x, _): return depth - 10
        case .draw: return 0
        case .inProgress: break
        }

        let moves = board.indices.filter { board[$0] == nil }
        if maximizing {
            return moves.map { move in
                var candidate = board
                candidate[move] = .o
                return minimax(board: candidate, maximizing: false, depth: depth + 1)
            }.max() ?? 0
        }

        return moves.map { move in
            var candidate = board
            candidate[move] = .x
            return minimax(board: candidate, maximizing: true, depth: depth + 1)
        }.min() ?? 0
    }
}
