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
    case X = "X"
    case O = "O"
    case E = " "
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
    let position: [Piece]
    
    let turn: Piece
    let lastMove: Move
    // by default the board is empty and X goes first
    // lastMove being -1 is a marker of a start position
    init(position: [Piece] = [.E, .E, .E, .E, .E, .E, .E, .E, .E], turn: Piece = .X, lastMove: Int = -1) {
        self.position = position
        self.turn = turn
        self.lastMove = lastMove
    }
}



