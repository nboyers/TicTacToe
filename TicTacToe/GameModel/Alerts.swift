//
//  Alerts.swift
//  TicTacToe
//
//  Created by Noah Boyers on 6/16/21.
//

import SwiftUI

struct AlertItem: Identifiable {
    let id = UUID()
    var title: Text
    var message: Text
    var buttonTitle: Text
}

struct AlertContext {
    static  let humanWin   = AlertItem(title: Text("YOU WON"),
                                       message: Text("Congrats!"),
                                       buttonTitle: Text("Play Again"))
    
    static let computerWin = AlertItem(title: Text("YOU LOST"),
                                       message: Text("Maybe Next Time"),
                                       buttonTitle: Text("Play Again"))
    
    static let draw        = AlertItem(title: Text("Draw"),
                                       message: Text("Well That Was Disapointing"),
                                       buttonTitle: Text("Play Again"))
}
