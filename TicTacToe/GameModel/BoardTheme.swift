//
//  BoardTheme.swift
//  TicTacToe
//
//  Cosmetic themes. Unlocked with coins (earned by playing or bought via IAP),
//  which gives players a long-term goal to play toward.
//

import SwiftUI

enum BoardTheme: String, CaseIterable, Identifiable, Codable {
    case classic, ocean, sunset, neon
    
    var id: String { rawValue }
    
    var name: String { rawValue.capitalized }
    
    var price: Int {
        switch self {
        case .classic: return 0
        case .ocean: return 150
        case .sunset: return 300
        case .neon: return 600
        }
    }
    
    var background: [Color] {
        switch self {
        case .classic: return [GamePalette.skyTop, GamePalette.skyBottom]
        case .ocean: return [Color(red: 0.0, green: 0.68, blue: 0.85), Color(red: 0.0, green: 0.30, blue: 0.65)]
        case .sunset: return [Color(red: 1.0, green: 0.55, blue: 0.25), Color(red: 0.75, green: 0.15, blue: 0.5)]
        case .neon: return [Color(red: 0.08, green: 0.02, blue: 0.2), Color(red: 0.30, green: 0.05, blue: 0.5)]
        }
    }
    
    var tileTop: Color {
        switch self {
        case .classic: return Color(red: 0.98, green: 0.98, blue: 1.0)
        case .ocean: return Color(red: 0.85, green: 1.0, blue: 1.0)
        case .sunset: return Color(red: 1.0, green: 0.95, blue: 0.85)
        case .neon: return Color(red: 0.25, green: 0.15, blue: 0.5)
        }
    }
    
    var tileBottom: Color {
        switch self {
        case .classic: return Color(red: 0.82, green: 0.86, blue: 1.0)
        case .ocean: return Color(red: 0.6, green: 0.9, blue: 0.95)
        case .sunset: return Color(red: 1.0, green: 0.82, blue: 0.65)
        case .neon: return Color(red: 0.15, green: 0.08, blue: 0.35)
        }
    }
    
    var tileEdge: Color {
        switch self {
        case .classic: return Color(red: 0.45, green: 0.50, blue: 0.80)
        case .ocean: return Color(red: 0.1, green: 0.5, blue: 0.6)
        case .sunset: return Color(red: 0.7, green: 0.35, blue: 0.2)
        case .neon: return Color(red: 0.05, green: 0.02, blue: 0.15)
        }
    }
    
    var xColor: Color {
        switch self {
        case .classic: return Color(red: 0.95, green: 0.25, blue: 0.35)
        case .ocean: return Color(red: 1.0, green: 0.5, blue: 0.2)
        case .sunset: return Color(red: 0.75, green: 0.1, blue: 0.35)
        case .neon: return Color(red: 0.2, green: 1.0, blue: 0.5)
        }
    }
    
    var oColor: Color {
        switch self {
        case .classic: return Color(red: 0.15, green: 0.55, blue: 1.0)
        case .ocean: return Color(red: 0.0, green: 0.35, blue: 0.8)
        case .sunset: return Color(red: 0.45, green: 0.2, blue: 0.75)
        case .neon: return Color(red: 1.0, green: 0.3, blue: 0.9)
        }
    }
}
