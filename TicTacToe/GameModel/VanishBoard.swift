//
//  VanishBoard.swift
//  TicTacToe
//
//  Vanish Tic-Tac-Toe: normal 3x3 rules, but each player can only have 3 marks on the board.
//  Placing a 4th mark makes that player's oldest mark vanish. Games never end in a draw.
//

import Foundation

struct VanishBoard: Equatable {
    static let marksPerPlayer = 3
    
    /// Squares each player holds, oldest first
    private(set) var xMoves: [Int] = []
    private(set) var oMoves: [Int] = []
    private(set) var turn: Piece = .X
    private(set) var lastMove: Int?
    
    init() {}
    
    /// A ready-made position, used by the tutorial
    init(x: [Int], o: [Int], turn: Piece = .X) {
        xMoves = x
        oMoves = o
        self.turn = turn
    }
    
    var position: [Piece] {
        var squares = Array(repeating: Piece.E, count: 9)
        xMoves.forEach { squares[$0] = .X }
        oMoves.forEach { squares[$0] = .O }
        return squares
    }
    
    var legalMoves: [Int] {
        guard winner == nil else { return [] }
        let occupied = Set(xMoves + oMoves)
        return (0..<9).filter { !occupied.contains($0) }
    }
    
    /// The marks that will vanish the next time their owner moves
    var fadingSquares: Set<Int> {
        var squares = Set<Int>()
        if xMoves.count == Self.marksPerPlayer, let oldest = xMoves.first { squares.insert(oldest) }
        if oMoves.count == Self.marksPerPlayer, let oldest = oMoves.first { squares.insert(oldest) }
        return squares
    }
    
    func playing(_ square: Int) -> VanishBoard {
        var next = self
        if turn == .X {
            next.xMoves.append(square)
            if next.xMoves.count > Self.marksPerPlayer { next.xMoves.removeFirst() }
        } else {
            next.oMoves.append(square)
            if next.oMoves.count > Self.marksPerPlayer { next.oMoves.removeFirst() }
        }
        next.turn = turn.opposite
        next.lastMove = square
        return next
    }
    
    /// Same position with the other player to move (used to look for blocks)
    func passingTurn() -> VanishBoard {
        var next = self
        next.turn = turn.opposite
        return next
    }
    
    var winningLine: [Int]? {
        for line in UltimateBoard.lines {
            let squares = Set(line)
            if squares == Set(xMoves) || squares == Set(oMoves) { return line }
        }
        return nil
    }
    
    var winner: Piece? {
        guard let line = winningLine else { return nil }
        return Set(line) == Set(xMoves) ? .X : .O
    }
    
    var outcome: GameOutcome? {
        winner.map { .win($0) }
    }
}

// MARK: - Computer opponent
enum VanishAI {
    private static let infinity = 1_000_000
    
    /// 0 random, 1 wins or blocks when it can, 2 looks 4 moves ahead, 3 looks 7 moves ahead
    static func bestMove(for board: VanishBoard, difficulty: Int) -> Int? {
        let moves = board.legalMoves
        guard !moves.isEmpty else { return nil }
        
        switch difficulty {
        case 0:
            return moves.randomElement()
        case 1:
            if let win = moves.first(where: { board.playing($0).winner == board.turn }) { return win }
            if let block = moves.first(where: { board.passingTurn().playing($0).winner == board.turn.opposite }) { return block }
            return moves.randomElement()
        case 2:
            return search(board, moves: moves, depth: 4)
        default:
            return search(board, moves: moves, depth: 7)
        }
    }
    
    /// Picks randomly among equally good moves so the bot isn't predictable
    private static func search(_ board: VanishBoard, moves: [Int], depth: Int) -> Int? {
        var bestScore = -infinity
        var bestMoves: [Int] = []
        for move in moves {
            let score = -negamax(board.playing(move), depth: depth - 1, alpha: -infinity, beta: infinity)
            if score > bestScore {
                bestScore = score
                bestMoves = [move]
            } else if score == bestScore {
                bestMoves.append(move)
            }
        }
        return bestMoves.randomElement()
    }
    
    /// Score from the point of view of the side to move
    private static func negamax(_ board: VanishBoard, depth: Int, alpha: Int, beta: Int) -> Int {
        if board.winner != nil { return -(1_000 + depth) } // the previous mover just won
        if depth <= 0 { return evaluate(board) }
        
        var alpha = alpha
        var best = -infinity
        for move in board.legalMoves {
            let score = -negamax(board.playing(move), depth: depth - 1, alpha: -beta, beta: -alpha)
            best = max(best, score)
            alpha = max(alpha, score)
            if alpha >= beta { break }
        }
        return best
    }
    
    private static func evaluate(_ board: VanishBoard) -> Int {
        let me = board.turn == .X ? board.xMoves : board.oMoves
        let them = board.turn == .X ? board.oMoves : board.xMoves
        var score = 0
        for line in UltimateBoard.lines {
            let mine = line.filter { me.contains($0) }.count
            let theirs = line.filter { them.contains($0) }.count
            if theirs == 0 && mine == 2 { score += 10 }
            if mine == 0 && theirs == 2 { score -= 10 }
        }
        if me.contains(4) { score += 3 }
        if them.contains(4) { score -= 3 }
        return score
    }
}
