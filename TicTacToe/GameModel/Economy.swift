//
//  Economy.swift
//  TicTacToe
//
//  Every coin number in one place. Playing earns coins slowly on purpose, so that watching
//  an ad or buying a coin pack is the quickest way to get more. The numbers are the same for
//  every player; tune them here once you have real data on how long players take to reach
//  their first purchase.
//
//  Rough pacing for a casual player (about 6 games and a daily claim per day) is 30-50 coins a day:
//    first boost (60)      ~ 1-2 days        Ocean theme (150)   ~ 3-5 days
//    a skin (200-500)      ~ 1-2 weeks       a 500-coin pack      = about 10 days of play
//

import Foundation

enum Economy {
    static let startingCoins = 30
    
    // MARK: Earning by playing
    static func winCoins(difficulty: Int, streak: Int) -> Int {
        6 + 3 * difficulty + min(max(streak - 1, 0), 5) // streak bonus caps at +5
    }
    static let drawCoins = 2
    static let lossCoins = 1 // losing still pays a little so it never feels pointless
    static let passAndPlayCap = 2
    static let ultimateMultiplier = 2 // much longer games
    
    static func dailyReward(streak: Int) -> Int {
        15 + 5 * min(streak, 6) // grows every consecutive day, caps on day 7
    }
    
    // MARK: Opt-in ads
    // Rewards scale with what the ad the player watched actually paid. The lowest tier is the
    // guaranteed minimum, and every button shows the full range before the ad starts.
    /// eCPM (US$ per 1000 impressions) at which a rewarded ad moves up a tier
    static let tierEcpmThresholds: [Double] = [5, 15]
    /// Multiplier for the "x2" placements (double coins, daily claim) per tier
    static let adMultipliers = [2, 3, 4]
    /// Coins from the Shop's "free coins" ad per tier
    static let freeCoinsByTier = [15, 20, 30]
    static let freeCoinAdsPerDay = 5
    
    static func tier(forEcpm ecpm: Double) -> Int {
        if ecpm >= tierEcpmThresholds[1] { return 2 }
        if ecpm >= tierEcpmThresholds[0] { return 1 }
        return 0
    }
    
    // MARK: Spending
    static let hintCost = 15
    static let undoCost = 10
    
    // MARK: The Vault: rare, expensive, status items
    /// Anything priced at or above this counts as a Vault item and raises the Collector Rank
    static let vaultMinimumPrice = 2_500
    /// Purchases this big ask "are you sure?" first
    static let confirmPurchaseThreshold = 1_000
    
    /// Total Vault spending needed for Collector Rank n: 2,500 x (1 + 2 + ... + n).
    /// It gets steeper forever, so there is always a next rank and nobody "finishes".
    static func rankThreshold(_ rank: Int) -> Int {
        rank <= 0 ? 0 : vaultMinimumPrice * rank * (rank + 1) / 2
    }
    
    static func collectorRank(forSpent spent: Int) -> Int {
        var rank = 0
        while rankThreshold(rank + 1) <= spent { rank += 1 }
        return rank
    }
}
