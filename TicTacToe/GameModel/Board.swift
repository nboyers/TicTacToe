//
//  Board.swift
//  TicTacToe
//
//  Created by Noah Boyers on 12/14/21.
//

import Foundation

// a move is an integer 0-8 indicating a place to put a piece
typealias Move = Int

enum Piece: String {
    case X = "xmark"
    case O = "circle"
    case E = ""
    
    var opposite: Piece {
        switch self {
        case .X:
            return .O
            
        case .O:
            return .X
            
        case .E:
            return .E
        }
    }
}

struct Board {
    var position: [Piece]
    let turn: Piece
    let lastMove: Move
    // by default the board is empty and X goes first
    // lastMove being -1 is a marker of a start position
    init(position: [Piece], turn: Piece, lastMove: Int) {
        self.position = position
        self.turn = turn
        self.lastMove = lastMove
    }
    
    var winPositions: Set<Set<Int>> = [ [0,1,2],[3,4,5],
                                        [6,7,8],[0,3,6],
                                        [1,4,7],[2,5,8],
                                        [0,4,8],[2,4,6] ]
    var legalMoves: [Move] {
        return position.indices.filter { position[$0] == .E }
    }
    var isDraw: Bool {
        return !isWin && legalMoves.count == 0
    }
    
    var isWin: Bool {
        position[0] == position[1] && position[0] == position[2] && position[0] != .E || // row 0
        position[3] == position[4] && position[3] == position[5] && position[3] != .E || // row 1
        position[6] == position[7] && position[6] == position[8] && position[6] != .E || // row 2
        position[0] == position[3] && position[0] == position[6] && position[0] != .E || // col 0
        position[1] == position[4] && position[1] == position[7] && position[1] != .E || // col 1
        position[2] == position[5] && position[2] == position[8] && position[2] != .E || // col 2
        position[0] == position[4] && position[0] == position[8] && position[0] != .E || // diag 0
        position[2] == position[4] && position[2] == position[6] && position[2] != .E    // diag 1
        
    }
    var winPosition: Set<Set<Int>> = [[0,1,2],[3,4,5],[6,7,8],
                                      [0,3,6],[1,4,7],[2,5,8],
                                      [0,4,8],[2,4,6]]
    
    func move(_ location: Move) -> Board {
        var tempPosition = position
        tempPosition[location] = turn
        return Board(position: tempPosition, turn: turn.opposite, lastMove: location)
    }
    
    //MARK: Find the best possible outcome for originalPlayer
    func minimax(_ board: Board, maximizing: Bool, originalPlayer: Piece, alpha: Int, beta: Int) -> Int {
        // Base case - evaluate the position if it is a win or a draw
        if board.isWin && originalPlayer == board.turn.opposite { return 1 } // win
        else if board.isWin && originalPlayer != board.turn.opposite { return -1 } // loss
        else if board.isDraw { return 0 } // draw
        
        var alpha = alpha
        var beta = beta
        //MARK: Recursive case - maximize your gains or minimize the opponent's gains
        if maximizing {
            var bestScore = Int.min
            for moveOption in board.legalMoves { // find the move with the highest evaluation
                let result = minimax(board.move(moveOption), maximizing: false, originalPlayer: originalPlayer, alpha: alpha,beta: beta)
                bestScore = max(result, bestScore)
                alpha = max(alpha, result)
                if beta <= alpha { break }
            }
            return bestScore
        } else { // minimizing
            var worstScore = Int.max
            for moveOption in board.legalMoves {
                let result = minimax(board.move(moveOption), maximizing: true, originalPlayer: originalPlayer, alpha: alpha, beta: beta)
                worstScore = min(result, worstScore)
                beta = min(beta,worstScore)
                if beta <= alpha { break }
            }
            return worstScore
        }
    }
    
    //MARK: Run minimax on every possible move to find the best one
    func findBestMove(_ board: Board) -> Move {
        var bestScore = Int.min
        var bestMove = -1
        for moveOption in board.legalMoves {
            let result = minimax(board.move(moveOption), maximizing: false, originalPlayer: board.turn, alpha: Int.min, beta: Int.max)
            if result > bestScore {
                bestScore = result
                bestMove = moveOption
            }
        }
        return bestMove
    }
    
    //MARK: Picks a random spot that is open
    func easyMode(_ board: Board) -> Move {
        var AImove = Int.random(in: 0..<9)
        
        
        while(position[AImove] != .E){ AImove = Int.random(in: 0..<9) }
        return AImove
    }
    
    //MARK: IF CAN WIN, WIN
    func mediumMode(_ board: Board) -> Move {
        var AImove = Int.random(in: 0..<9)
        if position[4] == .E { return 4 }
        
        
        while(position[AImove] != .E){ AImove = Int.random(in: 0..<9) }
        return AImove
    }
    
    //MARK: IF CAN WIN, WIN, ELSE BLOCK
    func hardMode(_ board: Board) -> Move {
        var AImove = Int.random(in: 0..<9)
        if position[4] == .E { return 4 }
        
        
        while(position[AImove] != .E){ AImove = Int.random(in: 0..<9) }
        return AImove
    }
}



