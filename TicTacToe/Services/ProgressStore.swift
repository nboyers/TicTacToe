//
//  ProgressStore.swift
//  TicTacToe
//
//  Persistent player progress: coins, XP/level, streaks, achievements, themes.
//  These are the retention loops (daily reward, streaks, levels, goals to buy).
//

import Foundation

enum RoundResult {
    case win, loss, draw
}

struct RoundReward {
    var coins: Int
    var xp: Int
    var leveledUp: Bool
    var newAchievements: [Achievement]
    var points: Int = 0
    var ranksGained: Int = 0
}

struct PlayerData: Codable, Equatable {
    var coins = Economy.startingCoins // small welcome balance so the first hint feels free
    // Coins are also tracked as two totals that only ever grow. They let saves from two devices be
    // merged without losing or duplicating coins (balance = earned - spent). Use credit/debit.
    var coinsEarned = Economy.startingCoins
    var coinsSpent = 0
    var modified = Date.distantPast // when progress last changed; the newer save wins where a merge can't combine
    var xp = 0
    var wins = 0
    var losses = 0
    var draws = 0
    var winStreak = 0
    var bestWinStreak = 0
    var loginStreak = 0
    var impossibleDraws = 0
    var ultimateWins = 0
    var weeklyPoints = 0
    var weekStart: Date?
    var pointsBoostArmed = false // opt-in: the next win earns double leaderboard points
    var adCoinsClaimed = 0 // "free coins" ads watched on adCoinsDay
    var adCoinsDay: Date?
    var streakShields = 0
    var magnetGames = 0 // games left with +50% coins
    var ownedSkins: Set<PieceSkin> = [.classic]
    var selectedSkin: PieceSkin = .classic
    var ownedTitles: Set<PlayerTitle> = []
    var selectedTitle: PlayerTitle?
    var vaultSpent = 0 // lifetime coins spent on Vault items; drives the Collector Rank
    var lastDailyClaim: Date?
    var adsRemoved = false
    var achievements: Set<Achievement> = []
    var ownedThemes: Set<BoardTheme> = [.classic]
    var selectedTheme: BoardTheme = .classic
    
    init() {}
    
    private enum CodingKeys: String, CodingKey {
        case coins, xp, wins, losses, draws, winStreak, bestWinStreak, loginStreak
        case impossibleDraws, ultimateWins, weeklyPoints, weekStart, pointsBoostArmed
        case lastDailyClaim, adsRemoved, achievements, ownedThemes, selectedTheme
        case streakShields, magnetGames, ownedSkins, selectedSkin
        case adCoinsClaimed, adCoinsDay
        case ownedTitles, selectedTitle, vaultSpent
        case coinsEarned, coinsSpent, modified
    }
    
    // Tolerates saves from older versions that don't have newer fields yet
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = PlayerData()
        coins = try container.decodeIfPresent(Int.self, forKey: .coins) ?? defaults.coins
        coinsEarned = try container.decodeIfPresent(Int.self, forKey: .coinsEarned) ?? coins // older saves: the balance counts as earned
        coinsSpent = try container.decodeIfPresent(Int.self, forKey: .coinsSpent) ?? 0
        modified = try container.decodeIfPresent(Date.self, forKey: .modified) ?? .distantPast
        xp = try container.decodeIfPresent(Int.self, forKey: .xp) ?? defaults.xp
        wins = try container.decodeIfPresent(Int.self, forKey: .wins) ?? defaults.wins
        losses = try container.decodeIfPresent(Int.self, forKey: .losses) ?? defaults.losses
        draws = try container.decodeIfPresent(Int.self, forKey: .draws) ?? defaults.draws
        winStreak = try container.decodeIfPresent(Int.self, forKey: .winStreak) ?? defaults.winStreak
        bestWinStreak = try container.decodeIfPresent(Int.self, forKey: .bestWinStreak) ?? defaults.bestWinStreak
        loginStreak = try container.decodeIfPresent(Int.self, forKey: .loginStreak) ?? defaults.loginStreak
        impossibleDraws = try container.decodeIfPresent(Int.self, forKey: .impossibleDraws) ?? defaults.impossibleDraws
        ultimateWins = try container.decodeIfPresent(Int.self, forKey: .ultimateWins) ?? defaults.ultimateWins
        weeklyPoints = try container.decodeIfPresent(Int.self, forKey: .weeklyPoints) ?? defaults.weeklyPoints
        weekStart = try container.decodeIfPresent(Date.self, forKey: .weekStart)
        pointsBoostArmed = try container.decodeIfPresent(Bool.self, forKey: .pointsBoostArmed) ?? defaults.pointsBoostArmed
        ownedTitles = try container.decodeIfPresent(Set<PlayerTitle>.self, forKey: .ownedTitles) ?? defaults.ownedTitles
        selectedTitle = try container.decodeIfPresent(PlayerTitle.self, forKey: .selectedTitle)
        vaultSpent = try container.decodeIfPresent(Int.self, forKey: .vaultSpent) ?? defaults.vaultSpent
        adCoinsClaimed = try container.decodeIfPresent(Int.self, forKey: .adCoinsClaimed) ?? defaults.adCoinsClaimed
        adCoinsDay = try container.decodeIfPresent(Date.self, forKey: .adCoinsDay)
        streakShields = try container.decodeIfPresent(Int.self, forKey: .streakShields) ?? defaults.streakShields
        magnetGames = try container.decodeIfPresent(Int.self, forKey: .magnetGames) ?? defaults.magnetGames
        ownedSkins = try container.decodeIfPresent(Set<PieceSkin>.self, forKey: .ownedSkins) ?? defaults.ownedSkins
        selectedSkin = try container.decodeIfPresent(PieceSkin.self, forKey: .selectedSkin) ?? defaults.selectedSkin
        lastDailyClaim = try container.decodeIfPresent(Date.self, forKey: .lastDailyClaim)
        adsRemoved = try container.decodeIfPresent(Bool.self, forKey: .adsRemoved) ?? defaults.adsRemoved
        achievements = try container.decodeIfPresent(Set<Achievement>.self, forKey: .achievements) ?? defaults.achievements
        ownedThemes = try container.decodeIfPresent(Set<BoardTheme>.self, forKey: .ownedThemes) ?? defaults.ownedThemes
        selectedTheme = try container.decodeIfPresent(BoardTheme.self, forKey: .selectedTheme) ?? defaults.selectedTheme
    }
    
    mutating func credit(_ amount: Int) {
        coins += amount
        coinsEarned += amount
    }
    
    mutating func debit(_ amount: Int) {
        coins -= amount
        coinsSpent += amount
    }
}

@MainActor
final class ProgressStore: ObservableObject {
    static let xpPerLevel = 100
    private static let storageKey = "playerData.v1"
    
    @Published private(set) var data: PlayerData {
        didSet {
            // Every real change stamps the save so merges know which is newer. A merge from iCloud
            // doesn't: stamping it would make the other device think it changed and merge it back, forever.
            if !isApplyingMerge { data.modified = Date() }
            save()
        }
    }
    
    private var isApplyingMerge = false
    private var cloudObserver: Task<Void, Never>?
    
    init() {
        let local: PlayerData
        if let saved = UserDefaults.standard.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(PlayerData.self, from: saved) {
            local = decoded
        } else {
            local = PlayerData()
        }
        
        // Pick up progress backed up in iCloud: this is what restores a reinstalled or new device
        CloudSave.refresh()
        if let cloud = CloudSave.load() {
            data = local.merged(with: cloud)
        } else {
            data = local
        }
        save()
        
        // iCloud delivers changes made on another device (or a late first sync after reinstalling)
        cloudObserver = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: NSUbiquitousKeyValueStore.didChangeExternallyNotification) {
                self?.mergeFromCloud()
            }
        }
    }
    
    deinit {
        cloudObserver?.cancel()
    }
    
    private func mergeFromCloud() {
        guard let cloud = CloudSave.load() else { return }
        let merged = data.merged(with: cloud)
        
        // Only apply it if the progress itself differs, not just the timestamp
        var comparable = merged
        comparable.modified = data.modified
        guard comparable != data else { return }
        
        AppAnalytics.shared.log("cloud_restore", ["coins": merged.coins])
        isApplyingMerge = true
        data = merged
        isApplyingMerge = false
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: Self.storageKey)
        }
        CloudSave.save(data)
    }
    
    // MARK: Derived values
    var coins: Int { data.coins }
    var adsRemoved: Bool { data.adsRemoved }
    var level: Int { data.xp / Self.xpPerLevel + 1 }
    var levelProgress: Double { Double(data.xp % Self.xpPerLevel) / Double(Self.xpPerLevel) }
    var theme: BoardTheme { data.selectedTheme }
    var gamesPlayed: Int { data.wins + data.losses + data.draws }
    
    var stats: PlayerStats {
        PlayerStats(wins: data.wins, losses: data.losses, draws: data.draws,
                    bestWinStreak: data.bestWinStreak, loginStreak: data.loginStreak,
                    impossibleDraws: data.impossibleDraws, ultimateWins: data.ultimateWins)
    }
    
    // MARK: Weekly leaderboard
    var weeklyPoints: Int { data.weeklyPoints }
    var pointsBoostArmed: Bool { data.pointsBoostArmed }
    
    var leaderboard: [LeaderboardEntry] {
        Leaderboard.entries(playerScore: data.weeklyPoints, seed: Leaderboard.weekSeed())
    }
    
    var weeklyRank: Int {
        (leaderboard.firstIndex { $0.isPlayer } ?? 0) + 1
    }
    
    /// The rival directly above the player and the points needed to pass them
    var nextRival: (entry: LeaderboardEntry, gap: Int)? {
        let board = leaderboard
        guard let index = board.firstIndex(where: { $0.isPlayer }), index > 0 else { return nil }
        return (board[index - 1], board[index - 1].score - data.weeklyPoints + 1)
    }
    
    /// Starts a fresh ladder when a new week begins
    func refreshWeek() {
        let start = Leaderboard.weekStart()
        guard data.weekStart != start else { return }
        data.weekStart = start
        data.weeklyPoints = 0
    }
    
    func armPointsBoost() {
        data.pointsBoostArmed = true
    }
    
    // MARK: Daily reward
    var canClaimDaily: Bool {
        guard let last = data.lastDailyClaim else { return true }
        return !Calendar.current.isDateInToday(last)
    }
    
    private var daysSinceLastClaim: Int? {
        guard let last = data.lastDailyClaim else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: last),
                                       to: calendar.startOfDay(for: Date())).day
    }
    
    /// Streak that is still alive: claimed today or yesterday, or saved by a Streak Shield.
    var activeDailyStreak: Int {
        guard let days = daysSinceLastClaim else { return 0 }
        if days <= 1 { return data.loginStreak }
        if days == 2 && data.streakShields > 0 { return data.loginStreak } // one missed day, shield covers it
        return 0
    }
    
    var nextDailyReward: Int {
        Economy.dailyReward(streak: activeDailyStreak)
    }
    
    @discardableResult
    func claimDaily(multiplier: Int = 1) -> Int {
        guard canClaimDaily else { return 0 }
        let reward = nextDailyReward * multiplier
        let streak = activeDailyStreak
        if daysSinceLastClaim == 2 && data.streakShields > 0 { data.streakShields -= 1 } // shield used
        data.loginStreak = streak + 1
        data.lastDailyClaim = Date()
        data.credit(reward)
        AppAnalytics.shared.log(AnalyticsEvent.dailyClaim,
                                ["streak": data.loginStreak, "coins": reward, "multiplier": multiplier])
        _ = unlockAchievements() // streak achievements
        return reward
    }
    
    // MARK: Rounds
    func recordRound(_ result: RoundResult, difficulty: Int?, ultimate: Bool = false) -> RoundReward {
        refreshWeek()
        let levelBefore = level
        let rankBefore = weeklyRank
        var coins = 0
        var xp = 0
        
        switch result {
        case .win:
            data.wins += 1
            data.winStreak += 1
            data.bestWinStreak = max(data.bestWinStreak, data.winStreak)
            coins = Economy.winCoins(difficulty: difficulty ?? 0, streak: data.winStreak)
            xp = 20 + 5 * (difficulty ?? 0)
        case .draw:
            data.draws += 1
            data.winStreak = 0
            coins = Economy.drawCoins
            xp = 10
            if difficulty == 3 { data.impossibleDraws += 1 }
        case .loss:
            data.losses += 1
            data.winStreak = 0
            coins = Economy.lossCoins
            xp = 5
        }
        
        if difficulty == nil { // pass-and-play: no stats farming
            coins = min(coins, Economy.passAndPlayCap)
            xp = min(xp, 5)
        }
        
        if ultimate { // much longer games, so they pay double
            coins *= Economy.ultimateMultiplier
            xp *= 2
            if result == .win { data.ultimateWins += 1 }
        }
        
        if data.magnetGames > 0 { // Coin Magnet: +50% for its remaining games
            coins += (coins + 1) / 2
            data.magnetGames -= 1
        }
        
        var points = Leaderboard.points(for: result, difficulty: difficulty, ultimate: ultimate)
        if result == .win && points > 0 && data.pointsBoostArmed { // the opt-in boost the player chose
            points *= 2
            data.pointsBoostArmed = false
        }
        data.weeklyPoints += points
        
        data.credit(coins)
        data.xp += xp
        let unlocked = unlockAchievements()
        if level > levelBefore {
            AppAnalytics.shared.log(AnalyticsEvent.levelUp, ["level": level, "games_played": gamesPlayed])
        }
        AppAnalytics.shared.setUserProperty(String(level), forName: "level")
        return RoundReward(coins: coins, xp: xp, leveledUp: level > levelBefore, newAchievements: unlocked,
                           points: points, ranksGained: max(0, rankBefore - weeklyRank))
    }
    
    private func unlockAchievements() -> [Achievement] {
        let newlyEarned = Achievement.allCases.filter { !data.achievements.contains($0) && $0.isEarned(by: stats) }
        for achievement in newlyEarned {
            AppAnalytics.shared.log(AnalyticsEvent.achievementUnlocked, ["id": achievement.rawValue])
            data.achievements.insert(achievement)
            data.credit(achievement.rewardCoins)
        }
        return newlyEarned
    }
    
    // MARK: Free coins from ads
    private var adCoinsClaimedToday: Int {
        guard let day = data.adCoinsDay, Calendar.current.isDateInToday(day) else { return 0 }
        return data.adCoinsClaimed
    }
    
    var freeCoinAdsRemaining: Int {
        max(0, Economy.freeCoinAdsPerDay - adCoinsClaimedToday)
    }
    
    /// Pays out after the player chose to watch a "free coins" ad; capped per day
    func claimFreeCoins(coins: Int) {
        guard freeCoinAdsRemaining > 0 else { return }
        data.adCoinsClaimed = adCoinsClaimedToday + 1
        data.adCoinsDay = Date()
        data.credit(coins)
    }
    
    // MARK: Currency
    func add(coins: Int) {
        data.credit(coins)
    }
    
    /// Returns false (and changes nothing) when the player can't afford it.
    func spend(_ amount: Int) -> Bool {
        guard data.coins >= amount else { return false }
        data.debit(amount)
        return true
    }
    
    // MARK: Themes
    func owns(_ theme: BoardTheme) -> Bool { data.ownedThemes.contains(theme) }
    
    func buyOrSelect(_ theme: BoardTheme) -> Bool {
        if owns(theme) {
            data.selectedTheme = theme
            return true
        }
        guard spend(theme.price) else { return false }
        data.ownedThemes.insert(theme)
        data.selectedTheme = theme
        if theme.isVault { data.vaultSpent += theme.price }
        AppAnalytics.shared.log(AnalyticsEvent.cosmeticBought, ["kind": "theme", "id": theme.rawValue, "price": theme.price])
        return true
    }
    
    // MARK: Boosts
    var streakShields: Int { data.streakShields }
    var magnetGames: Int { data.magnetGames }
    
    func owned(of boost: Boost) -> Int {
        switch boost {
        case .coinMagnet: return data.magnetGames
        case .pointsBoost: return data.pointsBoostArmed ? 1 : 0
        case .streakShield: return data.streakShields
        }
    }
    
    /// Points Boost can't be stacked, shields are capped at 3
    func canBuy(_ boost: Boost) -> Bool {
        switch boost {
        case .coinMagnet: return data.magnetGames < 9
        case .pointsBoost: return !data.pointsBoostArmed
        case .streakShield: return data.streakShields < 3
        }
    }
    
    func buy(_ boost: Boost) -> Bool {
        guard canBuy(boost), spend(boost.price) else { return false }
        switch boost {
        case .coinMagnet: data.magnetGames += 3
        case .pointsBoost: data.pointsBoostArmed = true
        case .streakShield: data.streakShields += 1
        }
        AppAnalytics.shared.log(AnalyticsEvent.boostBought, ["boost": boost.rawValue, "price": boost.price])
        return true
    }
    
    // MARK: Piece skins
    var skin: PieceSkin { data.selectedSkin }
    
    func owns(_ skin: PieceSkin) -> Bool { data.ownedSkins.contains(skin) }
    
    func buyOrSelect(_ skin: PieceSkin) -> Bool {
        if owns(skin) {
            data.selectedSkin = skin
            return true
        }
        guard skin.isAvailable, spend(skin.price) else { return false } // retired limited items can't be bought
        data.ownedSkins.insert(skin)
        data.selectedSkin = skin
        if skin.isVault { data.vaultSpent += skin.price }
        AppAnalytics.shared.log(AnalyticsEvent.cosmeticBought, ["kind": "skin", "id": skin.rawValue, "price": skin.price])
        return true
    }
    
    // MARK: The Vault
    var collectorRank: Int { Economy.collectorRank(forSpent: data.vaultSpent) }
    
    /// Vault spending still needed for the next Collector Rank
    var coinsToNextRank: Int { Economy.rankThreshold(collectorRank + 1) - data.vaultSpent }
    
    var rankProgress: Double {
        let low = Economy.rankThreshold(collectorRank)
        let high = Economy.rankThreshold(collectorRank + 1)
        return Double(data.vaultSpent - low) / Double(high - low)
    }
    
    var title: PlayerTitle? { data.selectedTitle }
    
    /// Earned titles unlock automatically from play; bought ones come from the Vault
    func ownsTitle(_ title: PlayerTitle) -> Bool {
        title.isEarned(by: stats) || data.ownedTitles.contains(title)
    }
    
    func equip(_ title: PlayerTitle) {
        guard ownsTitle(title) else { return }
        data.selectedTitle = title
    }
    
    func buyTitle(_ title: PlayerTitle) -> Bool {
        guard let price = title.price, !ownsTitle(title), spend(price) else { return false }
        data.ownedTitles.insert(title)
        data.vaultSpent += price
        data.selectedTitle = title
        AppAnalytics.shared.log(AnalyticsEvent.cosmeticBought, ["kind": "title", "id": title.rawValue, "price": price])
        return true
    }
    
    // MARK: IAP
    func setAdsRemoved() {
        data.adsRemoved = true
        AppAnalytics.shared.setUserProperty("true", forName: "ads_removed")
    }
}
