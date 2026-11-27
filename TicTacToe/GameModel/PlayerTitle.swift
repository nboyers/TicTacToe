//
//  PlayerTitle.swift
//  TicTacToe
//
//  Titles shown next to the player's name on the menu and the leaderboard.
//  Some are bought in the Vault; the others can only be earned by playing, so they say something coins can't.
//

import Foundation

enum PlayerTitle: String, CaseIterable, Identifiable, Codable {
    // Bought in the Vault
    case collector, tycoon, mogul, legend
    // Earned by playing, never for sale
    case centurion, strategist, unstoppable, veteran
    
    var id: String { rawValue }
    
    var name: String { rawValue.capitalized }
    
    /// nil means this title can't be bought
    var price: Int? {
        switch self {
        case .collector: return 3_000
        case .tycoon: return 10_000
        case .mogul: return 30_000
        case .legend: return 75_000
        default: return nil
        }
    }
    
    var icon: String {
        switch self {
        case .collector: return "star.circle.fill"
        case .tycoon: return "banknote.fill"
        case .mogul: return "building.columns.fill"
        case .legend: return "crown.fill"
        case .centurion: return "shield.lefthalf.filled"
        case .strategist: return "square.grid.3x3.fill"
        case .unstoppable: return "bolt.fill"
        case .veteran: return "medal.fill"
        }
    }
    
    var requirement: String {
        switch self {
        case .collector, .tycoon, .mogul, .legend: return "Bought in the Vault"
        case .centurion: return "Win 100 games"
        case .strategist: return "Win 50 games of Ultimate"
        case .unstoppable: return "Win 15 games in a row"
        case .veteran: return "Play 500 games"
        }
    }
    
    func isEarned(by stats: PlayerStats) -> Bool {
        switch self {
        case .centurion: return stats.wins >= 100
        case .strategist: return stats.ultimateWins >= 50
        case .unstoppable: return stats.bestWinStreak >= 15
        case .veteran: return stats.gamesPlayed >= 500
        default: return false
        }
    }
}
