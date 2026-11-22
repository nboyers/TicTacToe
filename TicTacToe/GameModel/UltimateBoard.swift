//
//  UltimateBoard.swift
//  TicTacToe
//
//  Ultimate Tic-Tac-Toe: a 3x3 grid of 3x3 mini-boards.
//  - Winning a mini-board claims that big square.
//  - Three claimed big squares in a row wins the game.
//  - The cell you play inside a mini-board decides which mini-board your opponent
//    must play in next. If that board is already decided, they may play anywhere open.
//  - The game is a draw when every mini-board is decided and nobody has three in a row.
//

import Foundation

struct UltimateMove: Hashable {
    let board: Int // which mini-board, 0-8
    let cell: Int  // which cell inside it, 0-8
}

enum MiniResult: Equatable {
    case open
    case won(Piece)
    case draw
}

struct UltimateBoard: Equatable {
    static let lines: [[Int]] = [[0, 1, 2], [3, 4, 5], [6, 7, 8],
                                 [0, 3, 6], [1, 4, 7], [2, 5, 8],
                                 [0, 4, 8], [2, 4, 6]]
    
    /// Cell contents, indexed board * 9 + cell
    private(set) var cells: [Piece] = Array(repeating: .E, count: 81)
    private(set) var results: [MiniResult] = Array(repeating: .open, count: 9)
    private(set) var turn: Piece = .X
    /// The mini-board the current player must play in, or nil for a free choice
    private(set) var forcedBoard: Int?
    private(set) var lastMove: UltimateMove?
    
    init() {}
    
    func piece(board: Int, cell: Int) -> Piece {
        cells[board * 9 + cell]
    }
    
    func isPlayable(_ board: Int) -> Bool {
        results[board] == .open && (forcedBoard == nil || forcedBoard == board)
    }
    
    func isLegal(_ move: UltimateMove) -> Bool {
        winner == nil && isPlayable(move.board) && piece(board: move.board, cell: move.cell) == .E
    }
    
    var legalMoves: [UltimateMove] {
        guard winner == nil else { return [] }
        var moves: [UltimateMove] = []
        for board in 0..<9 where isPlayable(board) {
            for cell in 0..<9 where cells[board * 9 + cell] == .E {
                moves.append(UltimateMove(board: board, cell: cell))
            }
        }
        return moves
    }
    
    func playing(_ move: UltimateMove) -> UltimateBoard {
        var next = self
        let base = move.board * 9
        next.cells[base + move.cell] = turn
        
        if Self.lines.contains(where: { line in line.allSatisfy { next.cells[base + $0] == turn } }) {
            next.results[move.board] = .won(turn)
        } else if (0..<9).allSatisfy({ next.cells[base + $0] != .E }) {
            next.results[move.board] = .draw
        }
        
        next.forcedBoard = next.results[move.cell] == .open ? move.cell : nil
        next.turn = turn.opposite
        next.lastMove = move
        return next
    }
    
    /// The three big squares that won the game
    var winningLine: [Int]? {
        for line in Self.lines {
            if case .won(let piece) = results[line[0]],
               line.allSatisfy({ results[$0] == .won(piece) }) {
                return line
            }
        }
        return nil
    }
    
    var winner: Piece? {
        guard let line = winningLine, case .won(let piece) = results[line[0]] else { return nil }
        return piece
    }
    
    var outcome: GameOutcome? {
        if let winner { return .win(winner) }
        return legalMoves.isEmpty ? .draw : nil
    }
    
    func boardsWon(by piece: Piece) -> Int {
        results.filter { $0 == .won(piece) }.count
    }
}

// MARK: - Computer opponent
enum UltimateAI {
    private static let infinity = 1_000_000
    
    /// 0 random, 1 greedy, 2 looks 3 moves ahead, 3 looks 4 moves ahead
    static func bestMove(for board: UltimateBoard, difficulty: Int) -> UltimateMove? {
        let moves = board.legalMoves
        guard !moves.isEmpty else { return nil }
        
        switch difficulty {
        case 0: return moves.randomElement()
        case 1: return search(board, moves: moves, depth: 1, jitter: 8)
        case 2: return search(board, moves: moves, depth: 3, jitter: 0)
        default: return search(board, moves: moves, depth: 4, jitter: 0)
        }
    }
    
    private static func search(_ board: UltimateBoard, moves: [UltimateMove], depth: Int, jitter: Int) -> UltimateMove? {
        var bestMove = moves[0]
        var bestScore = -infinity
        for move in moves {
            // With jitter we need exact scores for every move, so no root pruning
            let window = jitter == 0 ? bestScore : -infinity
            let score = -negamax(board.playing(move), depth: depth - 1, alpha: -infinity, beta: -window)
                + (jitter > 0 ? Int.random(in: 0...jitter) : 0)
            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }
        return bestMove
    }
    
    /// Score from the point of view of the side to move
    private static func negamax(_ board: UltimateBoard, depth: Int, alpha: Int, beta: Int) -> Int {
        if board.winner != nil { return -(100_000 + depth) } // the previous mover just won
        let moves = board.legalMoves
        if moves.isEmpty { return 0 }
        if depth <= 0 { return evaluate(board) }
        
        var alpha = alpha
        var best = -infinity
        for move in moves {
            let score = -negamax(board.playing(move), depth: depth - 1, alpha: -beta, beta: -alpha)
            best = max(best, score)
            alpha = max(alpha, score)
            if alpha >= beta { break }
        }
        return best
    }
    
    /// Heuristic from the point of view of the side to move
    private static func evaluate(_ board: UltimateBoard) -> Int {
        let me = board.turn
        var score = 0
        let lineValue = [0, 12, 70, 0]
        let localValue = [0, 1, 5, 0]
        
        // Progress on the big board
        for line in UltimateBoard.lines {
            var mine = 0
            var theirs = 0
            for index in line {
                if case .won(let piece) = board.results[index] {
                    if piece == me { mine += 1 } else { theirs += 1 }
                }
            }
            if theirs == 0 { score += lineValue[mine] }
            if mine == 0 { score -= lineValue[theirs] }
        }
        
        for index in 0..<9 {
            switch board.results[index] {
            case .won(let piece):
                let weight = index == 4 ? 30 : (index % 2 == 0 ? 18 : 12) // center and corners matter most
                score += piece == me ? weight : -weight
            case .open:
                let base = index * 9
                for line in UltimateBoard.lines {
                    var mine = 0
                    var theirs = 0
                    for offset in line {
                        let piece = board.cells[base + offset]
                        if piece == me { mine += 1 } else if piece != .E { theirs += 1 }
                    }
                    if theirs == 0 { score += localValue[mine] }
                    if mine == 0 { score -= localValue[theirs] }
                }
                let center = board.cells[base + 4]
                if center == me { score += 2 } else if center != .E { score -= 2 }
            case .draw:
                break
            }
        }
        
        if board.forcedBoard == nil { score += 6 } // a free choice is an advantage
        return score
    }
}
