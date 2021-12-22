//
//  GameViewModel.swift
//  TicTacToe
//
//  Created by Noah Boyers on 6/16/21.
//

import SwiftUI

final class GameViewModel : ObservableObject {
    
    var isDisabled = false
    
    let column: [GridItem] = [GridItem(.flexible()),
                              GridItem(.flexible()),
                              GridItem(.flexible()),]

    @Published var model  = Board.init()
    
    
    // the legal moves in a position are all of the empty squares
    var legalMoves: [Move] {
        return model.position.indices.filter { model.position[$0] == .E }
    }
    var isDraw: Bool {
        return !isWin && legalMoves.count == 0
    }
    
    var isWin: Bool {
        model.position[0] == model.position[1] && model.position[0] == model.position[2] && model.position[0] != .E || // row 0
        model.position[3] == model.position[4] && model.position[3] == model.position[5] && model.position[3] != .E || // row 1
        model.position[6] == model.position[7] && model.position[6] == model.position[8] && model.position[6] != .E || // row 2
        model.position[0] == model.position[3] && model.position[0] == model.position[6] && model.position[0] != .E || // col 0
        model.position[1] == model.position[4] && model.position[1] == model.position[7] && model.position[1] != .E || // col 1
        model.position[2] == model.position[5] && model.position[2] == model.position[8] && model.position[2] != .E || // col 2
        model.position[0] == model.position[4] && model.position[0] == model.position[8] && model.position[0] != .E || // diag 0
        model.position[2] == model.position[4] && model.position[2] == model.position[6] && model.position[2] != .E    // diag 1
        
    }
    
    func processGame(_ location: Move) {
        if model.position[location] == .E {
            model = move(location)
        }
    }
    
    
    // location can be 0-8, indicating where to move
    // return a new board with the move played
    func move(_ location: Move) -> Board {
        var tempPosition = model.position
        tempPosition[location] = model.turn
        return Board(position: tempPosition, turn: model.turn.opposite, lastMove: location)
    }
    
    // Find the best possible outcome for originalPlayer
    private func minimax(_ board: Board, maximizing: Bool, originalPlayer: Piece) -> Int {
        // Base case - evaluate the position if it is a win or a draw
        if isWin && originalPlayer == model.turn.opposite { return 1 } // win
        else if isWin && originalPlayer != model.turn.opposite { return -1 } // loss
        else if isDraw { return 0 } // draw
        
        // Recursive case - maximize your gains or minimize the opponent's gains
        if maximizing {
            var bestScore = Int.min
            for moveOption in legalMoves { // find the move with the highest evaluation
                let score = minimax(move(moveOption), maximizing: false, originalPlayer: originalPlayer)
                bestScore = max(score, bestScore)
            }
            return bestScore
        } else { // minimizing
            var worstScore = Int.max
            for moveOption in legalMoves {
                let score = minimax(move(moveOption), maximizing: true, originalPlayer: originalPlayer)
                worstScore = min(score, worstScore)
            }
            return worstScore
        }
    }
    
    // Run minimax on every possible move to find the best one
    private func findBestMove(_ board: Board) -> Move {
        var bestScore = Int.min
        var bestMove = -1
        for moveOption in legalMoves {
            let score = minimax(move(moveOption), maximizing: false, originalPlayer: model.turn)
            if score > bestScore {
                bestScore = score
                bestMove = moveOption
            }
        }
        return bestMove
    }
    
    func resetGame() {
       model = .init()
    }
}

