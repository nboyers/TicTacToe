//
//  CloudSave.swift
//  TicTacToe
//
//  Backs player progress up to the player's own iCloud (key-value storage), so it survives deleting
//  the app, reinstalling, or moving to a new phone. Nothing is sent to a server we run.
//
//  Limits: it needs the player to be signed in to iCloud, and restores only within one Apple ID.
//  Bought Remove Ads is restored separately by StoreKit; bought coins can only come back through this.
//

import Foundation

enum CloudSave {
    private static let key = "playerData.v1"
    
    /// False when the player isn't signed in to iCloud, i.e. progress is NOT being backed up
    static var isAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }
    
    static func load() -> PlayerData? {
        guard let data = NSUbiquitousKeyValueStore.default.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PlayerData.self, from: data)
    }
    
    static func save(_ player: PlayerData) {
        guard let encoded = try? JSONEncoder().encode(player) else { return }
        NSUbiquitousKeyValueStore.default.set(encoded, forKey: key)
    }
    
    /// Ask iCloud for anything newer
    static func refresh() {
        NSUbiquitousKeyValueStore.default.synchronize()
    }
}

extension PlayerData {
    /// Combines two saves of the same player, e.g. this device and iCloud, without losing progress.
    /// Totals that only grow take the larger value, things owned are unioned, and settings that
    /// can't be combined (selected theme, boosts held) come from whichever save changed most recently.
    func merged(with other: PlayerData) -> PlayerData {
        var result = modified >= other.modified ? self : other
        
        // Coins: both totals only grow, so the larger of each is right, and balance follows from them
        result.coinsEarned = max(coinsEarned, other.coinsEarned)
        result.coinsSpent = max(coinsSpent, other.coinsSpent)
        result.coins = max(0, result.coinsEarned - result.coinsSpent)
        
        // Lifetime progress
        result.xp = max(xp, other.xp)
        result.wins = max(wins, other.wins)
        result.losses = max(losses, other.losses)
        result.draws = max(draws, other.draws)
        result.bestWinStreak = max(bestWinStreak, other.bestWinStreak)
        result.impossibleDraws = max(impossibleDraws, other.impossibleDraws)
        result.ultimateWins = max(ultimateWins, other.ultimateWins)
        result.vaultSpent = max(vaultSpent, other.vaultSpent)
        
        // Things the player owns are never taken away
        result.achievements = achievements.union(other.achievements)
        result.ownedThemes = ownedThemes.union(other.ownedThemes)
        result.ownedSkins = ownedSkins.union(other.ownedSkins)
        result.ownedTitles = ownedTitles.union(other.ownedTitles)
        result.adsRemoved = adsRemoved || other.adsRemoved
        
        // Daily streak: whichever device claimed most recently
        let thisClaim = lastDailyClaim ?? .distantPast
        let otherClaim = other.lastDailyClaim ?? .distantPast
        let dailySource = thisClaim >= otherClaim ? self : other
        result.lastDailyClaim = dailySource.lastDailyClaim
        result.loginStreak = dailySource.loginStreak
        
        // Weekly points belong to a week: the later week wins, the same week takes the higher score
        let thisWeek = weekStart ?? .distantPast
        let otherWeek = other.weekStart ?? .distantPast
        if thisWeek == otherWeek {
            result.weeklyPoints = max(weeklyPoints, other.weeklyPoints)
            result.weekStart = weekStart ?? other.weekStart
        } else {
            let laterWeek = thisWeek > otherWeek ? self : other
            result.weeklyPoints = laterWeek.weeklyPoints
            result.weekStart = laterWeek.weekStart
        }
        
        // Whatever is selected has to be something that is owned
        if !result.ownedThemes.contains(result.selectedTheme) { result.selectedTheme = .classic }
        if !result.ownedSkins.contains(result.selectedSkin) { result.selectedSkin = .classic }
        // (earned titles have no price and aren't stored as owned, since they come from stats)
        if let title = result.selectedTitle, title.price != nil, !result.ownedTitles.contains(title) {
            result.selectedTitle = nil
        }
        
        result.modified = max(modified, other.modified)
        return result
    }
}
