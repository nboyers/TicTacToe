//
//  GameModel.swift
//  TicTacToe
//
//  Created by Noah Boyers on 6/16/21.
//

import SwiftUI


//MARK: MODELS
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
typealias Move = Int
