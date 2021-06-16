//
//  GameModel.swift
//  TicTacToe
//
//  Created by Noah Boyers on 6/16/21.
//

import SwiftUI


//MARK: MODELS
enum Player {
    case human, computer
}

struct Move {
    let player : Player
    let boardIndex : Int
    var indicator : String {
        return player == .human ? "xmark" : "circle"
    }
}
