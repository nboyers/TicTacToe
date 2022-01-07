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
    @Published var alertItem: AlertItem?
    
    init(position: [Piece], turn: Piece, lastMove: Int) {
        gameBoard = Board(position: position, turn: turn, lastMove: lastMove)
    }
    
    //MARK: the legal moves in a position are all of the empty squares
    func processGame(_ location: Move, diffculty: Int) {
        //FIXME: If user clicks on taken spot, app will choose next spot and disable the board, locking the entire thing
        if gameBoard.position[location] == .E {
            gameBoard = gameBoard.move(location)
            if checkForGameOver(for: .X, in: gameBoard) {
                return
            }
            isDisabled.toggle()
        }
        
        switch(diffculty) {
        case 0:
            let computerMove = gameBoard.easyMode(gameBoard)
            updateUI(computerMove: computerMove)
            break
            
        case 1:
            let computerMove = gameBoard.mediumMode(gameBoard)
            updateUI(computerMove: computerMove)
            break
            
        case 2:
            let computerMove = gameBoard.hardMode(gameBoard)
            updateUI(computerMove: computerMove)
            break
            
        case 3:
            let computerMove = gameBoard.findBestMove(gameBoard)
            updateUI(computerMove: computerMove)
            break
            
        default:
            let computerMove = gameBoard.easyMode(gameBoard)
            updateUI(computerMove: computerMove)
            break
        }
    }
    
    private func updateUI(computerMove: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            gameBoard = gameBoard.move(computerMove)
            if checkForGameOver(for: .O, in: gameBoard) {
                isDisabled.toggle()
                return
            }
            isDisabled.toggle()
        }
    }
    
    func checkForGameOver(for piece: Piece, in moves: Board) -> Bool {
        if gameBoard.isDraw {
            alertItem = AlertContext.draw
            return true
        }
        if gameBoard.isWin {
            if piece == .X {
                alertItem = AlertContext.humanWin
                return true
            } else {
                alertItem = AlertContext.computerWin
                return true
            }
        }
        
        return false
    }
    
    func resetGame() {
        gameBoard =  Board(position: [.E, .E, .E, .E, .E, .E, .E, .E, .E],
                           turn: .X,
                           lastMove: -1)
    }
}
