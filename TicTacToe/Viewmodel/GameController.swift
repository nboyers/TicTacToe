//
//  GameController.swift
//  TicTacToe
//
//  Created by Noah Boyers on 12/24/21.
//

import Foundation
import SwiftUI

class GameViewModel : ObservableObject {
    
    
    @Published var isDisabled = false
    @Published var gameBoard: Board
    @Published var alertItem: AlertItem?
    @Published var humanWin: Int  = 0
    @Published var computerWin: Int  = 0
    @Published var winRate: Double = 0
    @Published private var numberOfGames: Double   = 0
    

    init(position: [Piece], turn: Piece, lastMove: Int) {
        gameBoard = Board(position: position, turn: turn, lastMove: lastMove)
    }
    
    //MARK: the legal moves in a position are all of the empty squares
    func processGame(_ location: Move, diffculty: Int) {
        if gameBoard.position[location] == .E {
            gameBoard = gameBoard.move(location)
            if checkForGameOver(for: .X, in: gameBoard) { return }
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
            numberOfGames+=1
            winRate = ((Double(humanWin) / numberOfGames) * 100)
            alertItem = AlertContext.draw
            return true
        }
        
        if gameBoard.isWin {
            if piece == .X {
                numberOfGames+=1
                humanWin+=1
                winRate = ((Double(humanWin) / numberOfGames) * 100)
                alertItem = AlertContext.humanWin
                return true
            } else {
                numberOfGames+=1
                computerWin+=1
                winRate = ((Double(humanWin) / numberOfGames) * 100)
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
