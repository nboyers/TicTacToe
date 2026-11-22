//
//  AdManager.swift
//  TicTacToe
//
//  Decides WHEN ads appear and presents them. The presentation here is a
//  placeholder (AdPlaceholderView). To go live, add the Google Mobile Ads SDK and
//  replace the body of `present(_:)` with GADInterstitialAd / GADRewardedAd loads
//  and presents (use Google's test unit IDs until release).
//
//  Policy: interstitials only at natural breaks (between games), frequency capped,
//  never in the first games, never for paying users. Rewarded ads are always opt-in.
//

import Foundation

enum AdKind: Identifiable {
    case interstitial, rewarded
    var id: Self { self }
}

@MainActor
final class AdManager: ObservableObject {
    /// Non-nil while an ad is on screen.
    @Published var presented: AdKind?
    
    /// How many times the base reward a rewarded ad pays out (shown on every button that offers one).
    /// Raise it (e.g. to 3) when a higher-paying ad source is live; drive it from remote config or
    /// your mediation eCPM. The player always sees the real number before choosing to watch.
    @Published var rewardMultiplier = 2
    
    private let gamesBetweenInterstitials = 3
    private let minimumSecondsBetweenInterstitials: TimeInterval = 90
    private let gracePeriodGames = 3
    
    private var gamesSinceInterstitial = 0
    private var lastInterstitial = Date.distantPast
    private var completion: ((Bool) -> Void)?
    
    func registerFinishedGame() {
        gamesSinceInterstitial += 1
    }
    
    /// Shows an interstitial if the frequency cap allows, then always calls `then`.
    func showInterstitialIfDue(adsRemoved: Bool, totalGames: Int, then: @escaping () -> Void) {
        let due = !adsRemoved
            && totalGames > gracePeriodGames
            && gamesSinceInterstitial >= gamesBetweenInterstitials
            && Date().timeIntervalSince(lastInterstitial) >= minimumSecondsBetweenInterstitials
        guard due else {
            then()
            return
        }
        gamesSinceInterstitial = 0
        lastInterstitial = Date()
        present(.interstitial) { _ in then() }
    }
    
    /// Opt-in reward ad. `completion(true)` means the reward should be granted.
    /// Players who bought "Remove Ads" get the reward instantly.
    func showRewarded(adsRemoved: Bool, completion: @escaping (Bool) -> Void) {
        if adsRemoved {
            completion(true)
            return
        }
        present(.rewarded, completion: completion)
    }
    
    private func present(_ kind: AdKind, completion: @escaping (Bool) -> Void) {
        self.completion = completion
        presented = kind
    }
    
    /// Called by the ad view when the ad closes.
    func finishPresentedAd(rewardEarned: Bool) {
        let finished = completion
        completion = nil
        presented = nil
        finished?(rewardEarned)
    }
}
