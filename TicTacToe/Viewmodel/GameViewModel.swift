//
//  GameViewModel.swift
//  TicTacToe
//
//  Created by Noah Boyers on 6/16/21.
//

import SwiftUI

final class GameViewModel : ObservableObject {
    
    @Published var isDisabled = false
    @State var isHumanTurn = true
    
    let column: [GridItem] = [GridItem(.flexible()),
                              GridItem(.flexible()),
                              GridItem(.flexible()),]
    
    @Published var model: Board
    
    init(start: Board){
        model = start
    }
    
    
    func processGame(_ location: Move) {
        if model.position[location] == .E || isHumanTurn {
            model = model.move(location)
            isDisabled.toggle()
        }
        procressAI(model)
    }
    
    private func minimax(_ board: Board, maximizing: Bool, originalPlayer: Piece) -> Int {
        // Base case - evaluate the position if it is a win or a draw
        if board.isWin && originalPlayer == board.turn.opposite { return 1 } // win
        else if board.isWin && originalPlayer != board.turn.opposite { return -1 } // loss
        else if board.isDraw { return 0 } // draw
        
        // Recursive case - maximize your gains or minimize the opponent's gains
        if maximizing {
            var bestScore = Int.min
            for move in board.legalMoves { // find the move with the highest evaluation
                let score = minimax(board.move(move), maximizing: false, originalPlayer: originalPlayer)
                bestScore = max(score, bestScore)
            }
            return bestScore
        } else { // minimizing
            var worstScore = Int.max
            for move in board.legalMoves {
                let score = minimax(board.move(move), maximizing: true, originalPlayer: originalPlayer)
                worstScore = min(score, worstScore)
            }
            return worstScore
        }
    }
    
    // Run minimax on every possible move to find the best one
    private func findBestMove(_ board: Board) -> Move {
        var bestScore = Int.min
        var bestMove = -1
        for moveOption in board.legalMoves {
            let score = minimax(board.move(moveOption), maximizing: true, originalPlayer: model.turn)
            if score > bestScore {
                bestScore = score
                bestMove = moveOption
            }
        }
        return bestMove
    }
    
    private  func resetGame() {
        model = .init()
    }
    
    private func procressAI(_ board: Board) {
        let toWinHardPosition: [Piece] = model.position
        
        let currentBoard: Board = Board(position: toWinHardPosition, turn: board.turn, lastMove: board.lastMove)
        model = board.move(findBestMove(currentBoard))
        
        isDisabled.toggle()
    }
}

