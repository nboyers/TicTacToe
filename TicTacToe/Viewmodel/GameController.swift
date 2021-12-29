//
//  GameController.swift
//  TicTacToe
//
//  Created by Noah Boyers on 12/24/21.
//

import Foundation

class GameViewModel : ObservableObject {
    
    
    @Published var isDisabled = false
    @Published var gameBoard: Board
    
    init(position: [Piece], turn: Piece, lastMove: Int) {
        gameBoard = Board(position: position, turn: turn, lastMove: lastMove)
    }
    
    // the legal moves in a position are all of the empty squares

    func processGame(_ location: Move) {
        if gameBoard.position[location] == .E {
            gameBoard = gameBoard.move(location)
           isDisabled.toggle()
        }
        
        let computerMove = gameBoard.findBestMove(gameBoard)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            gameBoard = gameBoard.move(computerMove)
            isDisabled.toggle()
            
        }
    }
    
    func resetGame() {
        gameBoard =  Board(position: [.E, .E, .E, .E, .E, .E, .E, .E, .E], turn: .X, lastMove: -1)
    }
}
