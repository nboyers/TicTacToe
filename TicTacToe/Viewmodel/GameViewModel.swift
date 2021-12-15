//
//  GameViewModel.swift
//  TicTacToe
//
//  Created by Noah Boyers on 6/16/21.
//

import SwiftUI

final class GameViewModel : ObservableObject {
    
    
    let column: [GridItem] = [GridItem(.flexible()),
                              GridItem(.flexible()),
                              GridItem(.flexible()),]
    
    @Published var moves : [Move?] = Array(repeating: nil, count: 9)
    @Published var isGameBoardDisabled = false
    @Published var alertItem : AlertItem?
    private let winPatterns: Set<Set<Int>> = [[0,1,2],[3,4,5],
                                              [6,7,8],[0,3,6],
                                              [1,4,7],[2,5,8],
                                              [0,4,8],[2,4,6]]
    
    //MARK: Functions
    
    func processPlayerMove(for postion: Int) {
        // makes so the user cannot go in occupied space
        if isSquareOccupied(in: moves, forIndex: postion) { return }
        
        // Marks where the user is and disables the board until the Computer's turn is over
        moves[postion] = Move(player: .human, boardIndex: postion)
        isGameBoardDisabled = true
        
        //MARK: CHECK FOR WIN CONDITION OR DRAW
        if(checkWinCondition(for: .human, in: moves)){
            alertItem = AlertContext.humanWin
            isGameBoardDisabled = false
            return
        }
        
        if checkForDraw(in: moves) {
            alertItem = AlertContext.draw
            isGameBoardDisabled = false
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            let computerPostion = findBestMove()
            
            moves[computerPostion] = Move(player: .computer, boardIndex: computerPostion) //UPDATES THE BOARD GAME OF THE UI
            
            if checkWinCondition(for: .computer, in: moves){
                alertItem = AlertContext.computerWin
                isGameBoardDisabled = false
                return
            }
            
            if checkForDraw(in: moves) {
                alertItem = AlertContext.draw
                isGameBoardDisabled = false
                return
            }
            
            isGameBoardDisabled = false
            
        }
    }
    
    //    func determainMovePosition(in moves: [Move?]) -> Int {
    //        // MARK: IF AI Can win, win -- MEDUIM
    //        let computerMoves = moves.compactMap { $0 }.filter{$0.player == .computer}
    //        let computerPostion = Set(computerMoves.map{ $0.boardIndex }) // filters to see only the Computer's move / placement
    //
    //        for pattern in winPatterns {
    //            let winPostions: Set<Int> = pattern.subtracting(computerPostion)
    //            if winPostions.count == 1 {
    //                let isAvaiable = !isSquareOccupied(in: moves, forIndex: winPostions.first!)
    //                if isAvaiable { return winPostions.first! }
    //            }
    //        }
    //        //MARK: If AI can't win, block
    //        let humanMoves = moves.compactMap { $0 }.filter{$0.player == .human}
    //        let humanPostion = Set(humanMoves.map{ $0.boardIndex })
    //
    //        for pattern in winPatterns {
    //            let winPostions = pattern.subtracting(humanPostion)
    //            if winPostions.count == 1 {
    //                let isAvaiable = !isSquareOccupied(in: moves, forIndex: winPostions.first!)
    //                if isAvaiable { return winPostions.first! }
    //            }
    //        }
    //
    //        //MARK: If AI can't block, take middle spot
    //        let centerSquare = 4
    //        if !isSquareOccupied(in: moves, forIndex: centerSquare) {
    //            return centerSquare
    //        }
    //
    //        //MARK: If AI can't take middle square, random avaible square -- EASY
    //        var movePostion = Int.random(in: 0..<9)
    //
    //        repeat  {
    //            movePostion = Int.random(in: 0..<9)
    //        } while isSquareOccupied(in: moves, forIndex: movePostion)
    //        return movePostion
    //    }
    
    func checkWinCondition(for player: Player, in moves: [Move?]) -> Bool {
        let playerMoves = moves.compactMap{ $0 }.filter{ $0.player == player }
        let playerPostion = Set(playerMoves.map{ $0.boardIndex })
        
        for pattern in winPatterns where pattern.isSubset(of: playerPostion) { return true }
        
        return false
    }
    
    func checkForDraw(in moves: [Move?]) -> Bool {
        return moves.compactMap{ $0 }.count == 9
    }
    
    func isSquareOccupied(in moves: [Move?], forIndex index: Int) -> Bool {
        return moves.contains(where: {$0?.boardIndex == index})
    }
    
    func resetGame() {
        moves = Array(repeating: nil, count: 9)
    }
    
    
    //FIXME:
    private func minimax(Board: [Move?], depth: Int, alpha: Int, beta: Int, maximizingPlayer: Bool) -> Int {
        if checkWinCondition(for: .computer, in: moves) || checkForDraw(in: moves) { return  0 }
        var score = -1
        var bestScore = 0
        
        
        if maximizingPlayer {
            bestScore = Int.min
            score = minimax(Board: Board, depth: depth + 1, alpha: alpha, beta: beta, maximizingPlayer: false)
            //            var alpha = max(alpha,eval)
            //            if beta <= alpha {
            //                break
            //            }
            return max(bestScore,score)
            
        } else {
            
            bestScore = Int.max
            score = minimax(Board: Board, depth: depth + 1, alpha: alpha, beta: beta, maximizingPlayer: true)
            //            var beta = min(beta,eval)
            //            if beta <= alpha {
            //                break
            //            }
            
            return min(bestScore, score)
        }
    }
    
    func findBestMove() -> Int {
        let bestScore = Int.min
        var movePiece = 0
        var occupidedSpace = 0
        
        if !isSquareOccupied(in: moves, forIndex: occupidedSpace) {
            occupidedSpace += 1
        } else {
            let score = minimax(Board: moves, depth: 0, alpha: 0, beta: 0, maximizingPlayer: true)
            if score > bestScore {
                movePiece = occupidedSpace
            }
        }
        return movePiece
    }
}


