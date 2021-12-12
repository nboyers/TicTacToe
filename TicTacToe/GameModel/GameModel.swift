//
//  GameModel.swift
//  TicTacToe
//
//  Created by Noah Boyers on 6/16/21.
//

import SwiftUI


//MARK: MODELS
enum Player: Int {
    case human = -1
    case blank = 0
    case computer = 1
}

struct Move {
    let player : Player
    let boardIndex : Int
    var indicator : String {
        return player == .human ? "xmark" : "circle"
    }
}
