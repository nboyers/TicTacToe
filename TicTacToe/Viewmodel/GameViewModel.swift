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
        bestMove(Board: moves)
    }
    
    //        func determainMovePosition(in moves: [Move?]) -> Int {
    //            // MARK: IF AI Can win, win -- MEDUIM
    //            let computerMoves = moves.compactMap { $0 }.filter{$0.player == .computer}
    //            let computerPostion = Set(computerMoves.map{ $0.boardIndex }) // filters to see only the Computer's move / placement
    //
    //            for pattern in winPatterns {
    //                let winPostions: Set<Int> = pattern.subtracting(computerPostion)
    //                if winPostions.count == 1 {
    //                    let isAvaiable = !isSquareOccupied(in: moves, forIndex: winPostions.first!)
    //                    if isAvaiable { return winPostions.first! }
    //                }
    //            }
    //            //MARK: If AI can't win, block
    //            let humanMoves = moves.compactMap { $0 }.filter{$0.player == .human}
    //            let humanPostion = Set(humanMoves.map{ $0.boardIndex })
    //
    //            for pattern in winPatterns {
    //                let winPostions = pattern.subtracting(humanPostion)
    //                if winPostions.count == 1 {
    //                    let isAvaiable = !isSquareOccupied(in: moves, forIndex: winPostions.first!)
    //                    if isAvaiable { return winPostions.first! }
    //                }
    //            }
    //
    //            //MARK: If AI can't block, take middle spot
    //            let centerSquare = 4
    //            if !isSquareOccupied(in: moves, forIndex: centerSquare) {
    //                return centerSquare
    //            }
    //
    //            //MARK: If AI can't take middle square, random avaible square -- EASY
    //            var movePostion = Int.random(in: 0..<9)
    //
    //            repeat  {
    //                movePostion = Int.random(in: 0..<9)
    //            } while isSquareOccupied(in: moves, forIndex: movePostion)
    //            return movePostion
    //        }
    //
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
    
    
    private func minimax(board: [Move?], depth: Int, maximizingPlayer: Bool) -> Int {
        if checkWinCondition(for: .computer, in: board){ return 1 }
        if checkForDraw(in: board) { return 0 }
        if(checkWinCondition(for: .human, in: board)){ return -1 }
        
        if maximizingPlayer {
            var bestScore = Int.min
            for i in 0...8 {
                // Is the spot available?
                if !isSquareOccupied(in: board, forIndex: i) {
                    moves[i] = Move(player: .computer, boardIndex: i) // IS A SINGLE MOVE
                    let score = minimax(board: board, depth: depth + 1, maximizingPlayer: false);
                    moves[i] = nil
                    bestScore = max(score, bestScore)
                }
            }
            return bestScore
            
        } else {
            var worstScore = Int.max
            for i in 0...8 {
                if !isSquareOccupied(in: board, forIndex: i) {
                    moves[i] = Move(player: .human, boardIndex: i)
                    let score = minimax(board: board, depth: depth + 1, maximizingPlayer: true);
                    moves[i] = nil
                    worstScore = min(score, worstScore)
                }
            }
            return worstScore
        }
    }
    
    func bestMove(Board: [Move?])  {
        var bestScore = Int.min
        var move = 0
        for i in 0...8 {
            if !isSquareOccupied(in: Board, forIndex: i) {
                let score = minimax(board: Board, depth: 0, maximizingPlayer: true);
                if (score > bestScore) {
                    bestScore = score;
                    move = i
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
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
            moves[move] = Move(player: .computer, boardIndex: move)
            
            isGameBoardDisabled = false
        }
    }
}

