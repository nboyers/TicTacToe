//
//  Boost.swift
//  TicTacToe
//
//  Consumables bought with coins. Every boost does exactly what its description says.
//

import Foundation

enum Boost: String, CaseIterable, Identifiable {
    case coinMagnet, pointsBoost, streakShield
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .coinMagnet: return "Coin Magnet"
        case .pointsBoost: return "Points Boost"
        case .streakShield: return "Streak Shield"
        }
    }
    
    var detail: String {
        switch self {
        case .coinMagnet: return "+50% coins from your next 3 games"
        case .pointsBoost: return "2× leaderboard points on your next win"
        case .streakShield: return "Saves your daily streak if you miss a day"
        }
    }
    
    var icon: String {
        switch self {
        case .coinMagnet: return "magnet"
        case .pointsBoost: return "bolt.fill"
        case .streakShield: return "shield.fill"
        }
    }
    
    var price: Int {
        switch self {
        case .coinMagnet: return 60
        case .pointsBoost: return 80
        case .streakShield: return 120
        }
    }
}
