//
//  GameController.swift
//  TicTacToe
//
//  Created by Noah Boyers on 12/24/21.
//
import Foundation
import SwiftUI
import UIKit

enum GameMode: Hashable {
    case computer(difficulty: Int)
    case twoPlayer
    
    var title: String {
        switch self {
        case .twoPlayer: return "Two Player"
        case .computer(let difficulty):
            return ["Easy", "Medium", "Hard", "Impossible"][min(max(difficulty, 0), 3)]
        }
    }
    
    var difficulty: Int? {
        if case .computer(let difficulty) = self { return difficulty }
        return nil
    }
}

enum GameVariant: Hashable {
    case classic
    case ultimate
}

enum GameOutcome: Equatable {
    case win(Piece)
    case draw
}

@MainActor
final class GameViewModel: ObservableObject {
    
    @Published private(set) var gameBoard = GameViewModel.emptyBoard
    @Published private(set) var ultimateBoard = UltimateBoard()
    @Published private(set) var isDisabled = false
    @Published private(set) var outcome: GameOutcome?
    @Published private(set) var hintSquare: Int?
    @Published private(set) var ultimateHint: UltimateMove?
    @Published private(set) var playerWins = 0   // X
    @Published private(set) var opponentWins = 0 // O (computer or player two)
    @Published private(set) var draws = 0
    
    let mode: GameMode
    let variant: GameVariant
    private var history: [Board] = []
    private var ultimateHistory: [UltimateBoard] = []
    private var computerTask: Task<Void, Never>?
    
    private static var emptyBoard: Board {
        Board(position: Array(repeating: .E, count: 9), turn: .X, lastMove: -1)
    }
    
    init(mode: GameMode, variant: GameVariant = .classic) {
        self.mode = mode
        self.variant = variant
    }
    
    var gamesInSeries: Int { playerWins + opponentWins + draws }
    
    var winRate: Int {
        gamesInSeries == 0 ? 0 : Int((Double(playerWins) / Double(gamesInSeries) * 100).rounded())
    }
    
    var currentTurn: Piece {
        variant == .ultimate ? ultimateBoard.turn : gameBoard.turn
    }
    
    var statusText: String {
        if let outcome {
            switch outcome {
            case .draw: return "Draw"
            case .win(let piece): return mode == .twoPlayer ? "\(piece == .X ? "X" : "O") wins!" : (piece == .X ? "You win!" : "You lose")
            }
        }
        if isDisabled { return "Thinking…" }
        return mode == .twoPlayer ? "\(currentTurn == .X ? "X" : "O")'s turn" : "Your turn"
    }
    
    // Hints and undo only make sense against the computer, on the human's turn
    var canUseHelpers: Bool {
        mode != .twoPlayer && outcome == nil && !isDisabled
    }
    
    var canUndo: Bool {
        canUseHelpers && (variant == .ultimate ? ultimateHistory.count : history.count) >= 2
    }
    
    //MARK: Human move, then the computer replies after a short pause
    func play(_ square: Move) {
        guard variant == .classic, outcome == nil, !isDisabled,
              gameBoard.isAvailable(in: gameBoard, forIndex: square) else { return }
        
        hintSquare = nil
        apply(square)
        
        guard outcome == nil, let difficulty = mode.difficulty else { return }
        
        isDisabled = true
        computerTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled, let self else { return }
            self.apply(self.computerMove(difficulty: difficulty))
            self.isDisabled = false
        }
    }
    
    func playUltimate(_ move: UltimateMove) {
        guard variant == .ultimate, outcome == nil, !isDisabled, ultimateBoard.isLegal(move) else { return }
        
        ultimateHint = nil
        applyUltimate(move)
        
        guard outcome == nil, let difficulty = mode.difficulty else { return }
        
        isDisabled = true
        let snapshot = ultimateBoard
        computerTask = Task { [weak self] in
            // Search off the main thread so the UI stays smooth on the deeper levels
            let move = await Task.detached(priority: .userInitiated) {
                UltimateAI.bestMove(for: snapshot, difficulty: difficulty)
            }.value
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled, let self else { return }
            if let move { self.applyUltimate(move) }
            self.isDisabled = false
        }
    }
    
    func showHint() {
        guard canUseHelpers else { return }
        if variant == .ultimate {
            ultimateHint = UltimateAI.bestMove(for: ultimateBoard, difficulty: 2)
        } else {
            hintSquare = gameBoard.findBestMove(gameBoard)
        }
    }
    
    /// Takes back the human's last move and the computer's reply
    func undo() {
        guard canUndo else { return }
        if variant == .ultimate {
            ultimateBoard = ultimateHistory[ultimateHistory.count - 2]
            ultimateHistory.removeLast(2)
            ultimateHint = nil
        } else {
            gameBoard = history[history.count - 2]
            history.removeLast(2)
            hintSquare = nil
        }
    }
    
    func resetGame() {
        computerTask?.cancel()
        history = []
        ultimateHistory = []
        gameBoard = Self.emptyBoard
        ultimateBoard = UltimateBoard()
        outcome = nil
        hintSquare = nil
        ultimateHint = nil
        isDisabled = false
    }
    
    private func apply(_ square: Move) {
        history.append(gameBoard)
        gameBoard = gameBoard.move(square)
        Haptics.tap()
        evaluate()
    }
    
    private func applyUltimate(_ move: UltimateMove) {
        ultimateHistory.append(ultimateBoard)
        ultimateBoard = ultimateBoard.playing(move)
        Haptics.tap()
        if let result = ultimateBoard.outcome { finish(result) }
    }
    
    private func evaluate() {
        if gameBoard.isWin {
            finish(.win(gameBoard.turn.opposite)) // the player who just moved
        } else if gameBoard.isDraw {
            finish(.draw)
        }
    }
    
    private func finish(_ result: GameOutcome) {
        outcome = result
        switch result {
        case .win(.X): playerWins += 1
        case .win: opponentWins += 1
        case .draw: draws += 1
        }
    }
    
    private func computerMove(difficulty: Int) -> Move {
        switch difficulty {
        case 1: return gameBoard.mediumMode(gameBoard)
        case 2: return gameBoard.hardMode(gameBoard)
        case 3: return gameBoard.findBestMove(gameBoard)
        default: return gameBoard.easyMode(gameBoard)
        }
    }
}

enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    static func failure() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
