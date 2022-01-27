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
    @Published var formattedWinRate: String = "0"
    private var numberOfGames: Double = 0
    private var winRate: Double = 0
    
    init(position: [Piece], turn: Piece, lastMove: Int) {
        gameBoard = Board(position: position, turn: turn, lastMove: lastMove)
    }
    
    //MARK: the legal moves in a position are all of the empty squares
    func processGame(_ location: Move, diffculty: Int) {
        //Human move
        if gameBoard.position[location] == .E {
            isDisabled.toggle()
            gameBoard = gameBoard.move(location)
            if checkForGameOver(for: .X, in: gameBoard) { return }
        } else {
            alertItem = AlertContext.inValidMove
           return
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) { [self] in
            gameBoard = gameBoard.move(computerMove)
            if checkForGameOver(for: .O, in: gameBoard) { return }
            isDisabled.toggle()
        }
    }
    
    func checkForGameOver(for piece: Piece, in moves: Board) -> Bool {
        if gameBoard.isDraw {
            alertItem = AlertContext.draw
            return true
        }
        
        if gameBoard.isWin {
            if piece == .X { // human
                numberOfGames+=1
                humanWin+=1
                winRate = ((Double(humanWin) / numberOfGames) * 100)
                formattedWinRate =  String(format: "%.0f", winRate)
                alertItem = AlertContext.humanWin
                return true
            } else { // computer
                numberOfGames+=1
                computerWin+=1
                winRate = ((Double(humanWin) / numberOfGames) * 100)
                formattedWinRate =  String(format: "%.0f", winRate)
                alertItem = AlertContext.computerWin
                return true
            }
        }
        return false
    }
    
    func resetGame() {
        if gameBoard.isWin || gameBoard.isDraw {
            gameBoard =  Board(position: [.E, .E, .E, .E, .E, .E, .E, .E, .E],
                               turn: .X,
                               lastMove: -1)
        }
        isDisabled = false
    }
}
