import XCTest
@testable import TicTacToeEasyGo

final class GameEngineTests: XCTestCase {
    func testDetectsRowWin() {
        let board: [Mark?] = [.x, .x, .x, nil, .o, nil, .o, nil, nil]
        XCTAssertEqual(GameEngine.result(for: board), .won(.x, .init(cells: [0, 1, 2])))
    }

    func testBeginnerTakesWinningMove() {
        let board: [Mark?] = [.o, .o, nil, .x, .x, nil, nil, nil, nil]
        XCTAssertEqual(GameEngine.beginnerMove(on: board, random: { 0.9 }), 2)
    }

    func testProfessionalBlocksImmediateLoss() {
        let board: [Mark?] = [.x, .x, nil, nil, .o, nil, nil, nil, nil]
        XCTAssertEqual(GameEngine.professionalMove(on: board), 2)
    }
}
