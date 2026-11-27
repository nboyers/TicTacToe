//
//  AppAnalytics.swift
//  TicTacToe
//
//  One entry point for analytics. The app only ever calls AppAnalytics.shared; backends plug in behind it.
//  - Debug builds print every event to the console so you can verify instrumentation.
//  - Firebase Analytics turns on when the FirebaseAnalytics package is added AND a
//    GoogleService-Info.plist is in the app. Until then nothing is sent anywhere.
//
//  Privacy: events describe gameplay and purchases only. Never put names, emails or other
//  personal data in an event. Collection is switched on only after the consent flow allows it.
//

import Foundation
import OSLog
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

/// Event names in one place so they can't drift apart or get typo'd. snake_case, 40 characters max.
enum AnalyticsEvent {
    static let screenView = "screen_view"
    
    // Gameplay funnel
    static let gameStart = "game_start"
    static let gameEnd = "game_end"
    static let tutorialStart = "tutorial_start"
    static let tutorialExit = "tutorial_exit"
    static let helperUsed = "helper_used"
    static let lowCoinsPrompt = "low_coins_prompt"
    
    // Retention and progression
    static let dailyClaim = "daily_claim"
    static let levelUp = "level_up"
    static let achievementUnlocked = "achievement_unlocked"
    
    // Economy
    static let boostBought = "boost_bought"
    static let cosmeticBought = "cosmetic_bought"
    
    // Ads
    static let rewardedRequested = "rewarded_requested"
    static let rewardedResult = "rewarded_result"
    static let interstitialShown = "interstitial_shown"
    static let interstitialNoFill = "interstitial_no_fill"
    static let adImpression = "ad_impression"
    
    // Purchases
    static let purchaseStart = "purchase_start"
    static let purchase = "purchase" // Firebase's standard purchase event
    static let purchaseCancelled = "purchase_cancelled"
    static let purchaseFailed = "purchase_failed"
    static let restorePurchases = "restore_purchases"
}

protocol AnalyticsBackend: AnyObject {
    func start()
    func log(_ name: String, parameters: [String: Any])
    func setUserProperty(_ value: String?, forName name: String)
    func setCollectionEnabled(_ enabled: Bool)
}

final class AppAnalytics: @unchecked Sendable {
    static let shared = AppAnalytics()
    
    private var backends: [AnalyticsBackend] = []
    
    private init() {
        #if DEBUG
        backends.append(ConsoleAnalyticsBackend())
        #endif
        #if canImport(FirebaseAnalytics)
        backends.append(FirebaseAnalyticsBackend())
        #endif
    }
    
    func start() {
        backends.forEach { $0.start() }
    }
    
    /// Turn collection on or off, e.g. from the consent result
    func setCollectionEnabled(_ enabled: Bool) {
        backends.forEach { $0.setCollectionEnabled(enabled) }
    }
    
    func log(_ event: String, _ parameters: [String: Any] = [:]) {
        let cleaned = Self.sanitized(parameters)
        backends.forEach { $0.log(event, parameters: cleaned) }
    }
    
    func screen(_ name: String) {
        log(AnalyticsEvent.screenView, ["screen_name": name])
    }
    
    func setUserProperty(_ value: String?, forName name: String) {
        backends.forEach { $0.setUserProperty(value, forName: name) }
    }
    
    /// Analytics services only accept strings and numbers, and strings are capped at 100 characters
    private static func sanitized(_ parameters: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in parameters {
            switch value {
            case let string as String: result[key] = String(string.prefix(100))
            case let bool as Bool: result[key] = bool ? 1 : 0
            case let int as Int: result[key] = int
            case let double as Double: result[key] = double
            default: break
            }
        }
        return result
    }
}

// MARK: - Names for game values
extension GameMode {
    var analyticsName: String {
        switch self {
        case .twoPlayer: return "two_player"
        case .computer(let difficulty): return ["easy", "medium", "hard", "impossible"][min(max(difficulty, 0), 3)]
        }
    }
}

// MARK: - Debug console backend
final class ConsoleAnalyticsBackend: AnalyticsBackend {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TicTacToe", category: "analytics")
    
    func start() {}
    func setCollectionEnabled(_ enabled: Bool) {
        logger.debug("📊 collection enabled: \(enabled)")
    }
    
    func log(_ name: String, parameters: [String: Any]) {
        let details = parameters.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
        logger.debug("📊 \(name) \(details)")
    }
    
    func setUserProperty(_ value: String?, forName name: String) {
        logger.debug("📊 user property \(name)=\(value ?? "nil")")
    }
}

// MARK: - Firebase backend (compiled only when the package is added)
#if canImport(FirebaseAnalytics)
final class FirebaseAnalyticsBackend: AnalyticsBackend {
    private var isConfigured = false
    
    func start() {
        // Firebase crashes at launch without its config file, so only start when it's present
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else { return }
        if FirebaseApp.app() == nil { FirebaseApp.configure() }
        isConfigured = true
    }
    
    func setCollectionEnabled(_ enabled: Bool) {
        guard isConfigured else { return }
        Analytics.setAnalyticsCollectionEnabled(enabled)
    }
    
    func log(_ name: String, parameters: [String: Any]) {
        guard isConfigured else { return }
        Analytics.logEvent(name, parameters: parameters)
    }
    
    func setUserProperty(_ value: String?, forName name: String) {
        guard isConfigured else { return }
        Analytics.setUserProperty(value, forName: name)
    }
}
#endif
