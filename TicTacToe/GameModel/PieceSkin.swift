//
//  PieceSkin.swift
//  TicTacToe
//
//  Cosmetic X/O replacements bought with coins. The expensive ones live in the Vault.
//

import Foundation

enum PieceSkin: String, CaseIterable, Identifiable, Codable {
    case classic, space, pets, fire, food
    case diamond, dragon, royal // Vault
    case founder // Vault, limited: retires for good on `availableUntil`
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .classic: return "Classic"
        case .space: return "Space"
        case .pets: return "Pets"
        case .fire: return "Fire & Ice"
        case .food: return "Snacks"
        case .diamond: return "Diamond"
        case .dragon: return "Dragon"
        case .royal: return "Royal"
        case .founder: return "Founder"
        }
    }
    
    var price: Int {
        switch self {
        case .classic: return 0
        case .space: return 200
        case .pets: return 300
        case .fire: return 400
        case .food: return 500
        case .founder: return 2_500
        case .diamond: return 5_000
        case .dragon: return 12_000
        case .royal: return 30_000
        }
    }
    
    var isVault: Bool { price >= Economy.vaultMinimumPrice }
    
    /// Limited items can only be bought until this date. Owners keep them forever, which is what makes them rare.
    var availableUntil: Date? {
        switch self {
        case .founder: return Calendar.current.date(from: DateComponents(year: 2027, month: 3, day: 1))
        default: return nil
        }
    }
    
    var isAvailable: Bool {
        guard let until = availableUntil else { return true }
        return Date() < until
    }
    
    var daysLeft: Int? {
        guard let until = availableUntil else { return nil }
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: until).day ?? 0)
    }
    
    /// nil means "draw the normal X or O"
    func glyph(for piece: Piece) -> String? {
        guard piece != .E, let pair = glyphs else { return nil }
        return piece == .X ? pair.x : pair.o
    }
    
    private var glyphs: (x: String, o: String)? {
        switch self {
        case .classic: return nil
        case .space: return ("⭐️", "🌙")
        case .pets: return ("🐱", "🐶")
        case .fire: return ("🔥", "❄️")
        case .food: return ("🍕", "🍔")
        case .diamond: return ("💎", "🔮")
        case .dragon: return ("🐉", "🐲")
        case .royal: return ("👑", "💍")
        case .founder: return ("🏅", "🎖️")
        }
    }
}
