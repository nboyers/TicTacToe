//
//  Achievement.swift
//  TicTacToe
//

import Foundation

struct PlayerStats {
    var wins: Int
    var losses: Int
    var draws: Int
    var bestWinStreak: Int
    var loginStreak: Int
    var impossibleDraws: Int
    var ultimateWins: Int
    
    var gamesPlayed: Int { wins + losses + draws }
}

enum Achievement: String, CaseIterable, Identifiable, Codable {
    case firstWin, tenWins, winStreak3, winStreak5, played50, dailyStreak3, dailyStreak7, tamedImpossible
    case ultimateWin, ultimateWins5
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .firstWin: return "First Blood"
        case .tenWins: return "Getting Good"
        case .winStreak3: return "Hat Trick"
        case .winStreak5: return "Unstoppable"
        case .played50: return "Regular"
        case .dailyStreak3: return "Back Again"
        case .dailyStreak7: return "Dedicated"
        case .tamedImpossible: return "Mind Over Machine"
        case .ultimateWin: return "Grand Strategist"
        case .ultimateWins5: return "Board Master"
        }
    }
    
    var detail: String {
        switch self {
        case .firstWin: return "Win your first game"
        case .tenWins: return "Win 10 games"
        case .winStreak3: return "Win 3 games in a row"
        case .winStreak5: return "Win 5 games in a row"
        case .played50: return "Play 50 games"
        case .dailyStreak3: return "Claim your daily reward 3 days in a row"
        case .dailyStreak7: return "Claim your daily reward 7 days in a row"
        case .tamedImpossible: return "Draw against Impossible"
        case .ultimateWin: return "Win a game of Ultimate"
        case .ultimateWins5: return "Win 5 games of Ultimate"
        }
    }
    
    var icon: String {
        switch self {
        case .firstWin: return "flag.checkered"
        case .tenWins: return "star.fill"
        case .winStreak3: return "flame.fill"
        case .winStreak5: return "bolt.fill"
        case .played50: return "gamecontroller.fill"
        case .dailyStreak3: return "calendar"
        case .dailyStreak7: return "calendar.badge.clock"
        case .tamedImpossible: return "brain.head.profile"
        case .ultimateWin: return "square.grid.3x3.fill"
        case .ultimateWins5: return "crown.fill"
        }
    }
    
    var rewardCoins: Int {
        switch self {
        case .firstWin, .winStreak3, .dailyStreak3: return 15
        case .tenWins, .played50, .winStreak5, .dailyStreak7: return 25
        case .ultimateWin: return 40
        case .tamedImpossible, .ultimateWins5: return 50
        }
    }
    
    func isEarned(by stats: PlayerStats) -> Bool {
        switch self {
        case .firstWin: return stats.wins >= 1
        case .tenWins: return stats.wins >= 10
        case .winStreak3: return stats.bestWinStreak >= 3
        case .winStreak5: return stats.bestWinStreak >= 5
        case .played50: return stats.gamesPlayed >= 50
        case .dailyStreak3: return stats.loginStreak >= 3
        case .dailyStreak7: return stats.loginStreak >= 7
        case .tamedImpossible: return stats.impossibleDraws >= 1
        case .ultimateWin: return stats.ultimateWins >= 1
        case .ultimateWins5: return stats.ultimateWins >= 5
        }
    }
}
