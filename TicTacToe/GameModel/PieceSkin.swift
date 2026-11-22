//
//  PieceSkin.swift
//  TicTacToe
//
//  Cosmetic X/O replacements bought with coins.
//

import Foundation

enum PieceSkin: String, CaseIterable, Identifiable, Codable {
    case classic, space, pets, fire, food
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .classic: return "Classic"
        case .space: return "Space"
        case .pets: return "Pets"
        case .fire: return "Fire & Ice"
        case .food: return "Snacks"
        }
    }
    
    var price: Int {
        switch self {
        case .classic: return 0
        case .space: return 200
        case .pets: return 300
        case .fire: return 400
        case .food: return 500
        }
    }
    
    /// nil means "draw the normal X or O"
    func glyph(for piece: Piece) -> String? {
        guard self != .classic, piece != .E else { return nil }
        switch (self, piece) {
        case (.space, .X): return "⭐️"
        case (.space, _): return "🌙"
        case (.pets, .X): return "🐱"
        case (.pets, _): return "🐶"
        case (.fire, .X): return "🔥"
        case (.fire, _): return "❄️"
        case (.food, .X): return "🍕"
        default: return "🍔"
        }
    }
}
