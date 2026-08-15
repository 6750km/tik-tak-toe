import Foundation

enum Mark: String, Equatable, Sendable {
    case x = "X"
    case o = "O"

    var opponent: Mark { self == .x ? .o : .x }
}

enum GameMode: String, CaseIterable, Identifiable, Sendable {
    case beginner
    case professional
    case twoPlayers

    var id: String { rawValue }
}

enum GameResult: Equatable, Sendable {
    case inProgress
    case draw
    case won(Mark, WinningLine)
}

struct WinningLine: Equatable, Sendable {
    let cells: [Int]

    static let all: [WinningLine] = [
        .init(cells: [0, 1, 2]), .init(cells: [3, 4, 5]), .init(cells: [6, 7, 8]),
        .init(cells: [0, 3, 6]), .init(cells: [1, 4, 7]), .init(cells: [2, 5, 8]),
        .init(cells: [0, 4, 8]), .init(cells: [2, 4, 6])
    ]
}
