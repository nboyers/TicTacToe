//
//  Leaderboard.swift
//  TicTacToe
//
//  Weekly ladder. Rivals are computer-controlled "bots" and are labelled as such in the UI.
//  Their scores are fixed for the whole week (seeded by the week), so they never react to
//  how the player plays or spends. Replace with Game Center (GKLeaderboard) for real players.
//

import Foundation

struct LeaderboardEntry: Identifiable, Equatable {
    let id: String
    let name: String
    let score: Int
    let isPlayer: Bool
}

struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

enum Leaderboard {
    private static let botNames = ["Nova", "Blaze", "Pixel", "Echo", "Rogue", "Zephyr", "Comet", "Ember",
                                   "Vortex", "Shadow", "Lumen", "Titan", "Rex", "Misty", "Jinx", "Orbit",
                                   "Frost", "Havoc", "Sprout", "Cipher", "Turbo", "Ripple", "Maverick", "Quill"]
    
    static func weekStart(for date: Date = Date()) -> Date? {
        Calendar.current.dateInterval(of: .weekOfYear, for: date)?.start
    }
    
    static func weekSeed(for date: Date = Date()) -> Int {
        Int(weekStart(for: date)?.timeIntervalSince1970 ?? 0) / 604_800
    }
    
    /// Points a finished game is worth on the weekly ladder
    static func points(for result: RoundResult, difficulty: Int?, ultimate: Bool) -> Int {
        guard let difficulty else { return 0 } // pass-and-play doesn't count
        var points: Int
        switch result {
        case .win: points = 30 + 10 * difficulty
        case .draw: points = 10
        case .loss: points = 3
        }
        if ultimate { points *= 2 }
        return points
    }
    
    /// Everyone on this week's ladder, best first. Ties go to the bot.
    static func entries(playerScore: Int, seed: Int) -> [LeaderboardEntry] {
        var rng = SeededGenerator(state: UInt64(truncatingIfNeeded: seed) &* 7919 &+ 17)
        var names = botNames
        names.shuffle(using: &rng)
        
        var score = 20
        var list: [LeaderboardEntry] = []
        for (index, name) in names.enumerated() {
            score += Int.random(in: 25...95, using: &rng)
            list.append(LeaderboardEntry(id: "bot\(index)", name: name, score: score, isPlayer: false))
        }
        list.append(LeaderboardEntry(id: "player", name: "You", score: playerScore, isPlayer: true))
        
        return list.sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            return !lhs.isPlayer && rhs.isPlayer
        }
    }
}
