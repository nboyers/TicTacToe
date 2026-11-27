//
//  AdManager.swift
//  TicTacToe
//
//  Decides WHEN ads appear and presents them through Google AdMob.
//
//  Policy: interstitials only at natural breaks (between games), frequency capped,
//  never in the first games, never for paying users. Rewarded ads are always opt-in.
//
//  Setup: add both Swift packages in Xcode (File > Add Package Dependencies)
//    https://github.com/googleads/swift-package-manager-google-mobile-ads.git   (GoogleMobileAds)
//    https://github.com/googleads/swift-package-manager-google-user-messaging-platform.git   (UserMessagingPlatform)
//  Until they are added this file builds without them: Debug builds show the placeholder ad,
//  Release builds show no ads and never block the player.
//

import Foundation
import UIKit
import AppTrackingTransparency
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif
#if canImport(UserMessagingPlatform)
import UserMessagingPlatform
#endif

enum AdKind: Identifiable {
    case interstitial, rewarded
    var id: Self { self }
}

enum AdConfig {
    #if DEBUG
    // Google's published sample unit IDs: they always return test ads.
    static let interstitialUnitID = "ca-app-pub-3940256099942544/4411468910"
    static let rewardedUnitID = "ca-app-pub-3940256099942544/1712485313"
    #else
    // Release builds use the real ad units. Debug builds above always use Google's sample IDs,
    // so you never risk invalid traffic by tapping your own live ads while developing.
    static let interstitialUnitID = "ca-app-pub-7542723422099323/3924452116"
    static let rewardedUnitID = "ca-app-pub-7542723422099323/5833737913" // "Rewarded - Coin Boost"
    #endif
}

@MainActor
final class AdManager: NSObject, ObservableObject {
    /// Non-nil while the DEBUG placeholder ad is on screen (only used when the SDK isn't linked).
    @Published var presented: AdKind?
    
    /// Which reward tier the last rewarded ad earned (0 = lowest). It comes from what that ad
    /// actually paid, so a higher-paying ad gives the player more coins. Tiers live in `Economy`.
    @Published private(set) var lastRewardTier = 0
    private var pendingTier: Int?
    
    var minRewardMultiplier: Int { Economy.adMultipliers.first ?? 2 }
    var maxRewardMultiplier: Int { Economy.adMultipliers.last ?? 2 }
    var lastRewardMultiplier: Int { Economy.adMultipliers[min(lastRewardTier, Economy.adMultipliers.count - 1)] }
    var lastFreeCoins: Int { Economy.freeCoinsByTier[min(lastRewardTier, Economy.freeCoinsByTier.count - 1)] }
    
    /// What buttons show before the ad: the full range, or the top value for Remove Ads buyers
    func rewardLabel(adsRemoved: Bool) -> String {
        adsRemoved ? "×\(maxRewardMultiplier)" : "×\(minRewardMultiplier)–×\(maxRewardMultiplier)"
    }
    
    func freeCoinsLabel(adsRemoved: Bool) -> String {
        let low = Economy.freeCoinsByTier.first ?? 0
        let high = Economy.freeCoinsByTier.last ?? 0
        return adsRemoved ? "+\(high)" : "+\(low)–\(high)"
    }
    
    /// True when a rewarded ad can be shown right now.
    @Published private(set) var isRewardedReady = false
    
    /// True when the EU/UK privacy options entry point must be offered (e.g. in Settings or the Shop).
    @Published private(set) var privacyOptionsRequired = false
    
    private let gamesBetweenInterstitials = 3
    private let minimumSecondsBetweenInterstitials: TimeInterval = 90
    private let gracePeriodGames = 3
    
    private var gamesSinceInterstitial = 0
    private var lastInterstitial = Date.distantPast
    private var completion: ((Bool) -> Void)?
    private var rewardEarned = false
    
    #if canImport(GoogleMobileAds)
    private var interstitial: InterstitialAd?
    private var rewarded: RewardedAd?
    #endif
    
    override init() {
        super.init()
        #if DEBUG && !canImport(GoogleMobileAds)
        isRewardedReady = true // placeholder ads are always available while developing
        #endif
    }
    
    // MARK: Startup: consent -> tracking permission -> SDK
    /// Call once at launch. Order matters: consent first, then the tracking prompt, then start the SDK.
    func start() async {
        await requestConsent()
        AppAnalytics.shared.setCollectionEnabled(canRequestAds) // analytics follows the same consent
        guard canRequestAds else { return }
        #if canImport(GoogleMobileAds)
        await requestTrackingPermission() // only ask when ads will actually use the identifier
        _ = await MobileAds.shared.start()
        await preloadAds()
        #endif
    }
    
    private var canRequestAds: Bool {
        #if canImport(UserMessagingPlatform)
        return ConsentInformation.shared.canRequestAds
        #else
        return true
        #endif
    }
    
    private func requestConsent() async {
        #if canImport(UserMessagingPlatform)
        do {
            // Must run on every launch, even if consent was collected before
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters())
            try await ConsentForm.loadAndPresentIfRequired(from: topViewController())
        } catch {
            // Fall through: canRequestAds still reflects any consent saved from a previous launch
        }
        privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
        #endif
    }
    
    /// Shows the "Ad privacy choices" form so players can change their consent.
    func presentPrivacyOptions() async {
        #if canImport(UserMessagingPlatform)
        try? await ConsentForm.presentPrivacyOptionsForm(from: topViewController())
        #endif
    }
    
    private func requestTrackingPermission() async {
        // The ATT prompt only appears while the app is active
        var waited = 0
        while UIApplication.shared.applicationState != .active && waited < 50 {
            try? await Task.sleep(nanoseconds: 200_000_000)
            waited += 1
        }
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }
    }
    
    // MARK: Loading
    func preloadAds() async {
        #if canImport(GoogleMobileAds)
        await loadInterstitial()
        await loadRewarded()
        #endif
    }
    
    #if canImport(GoogleMobileAds)
    private func loadInterstitial() async {
        guard interstitial == nil else { return }
        do {
            let ad = try await InterstitialAd.load(with: AdConfig.interstitialUnitID, request: Request())
            ad.fullScreenContentDelegate = self
            interstitial = ad
        } catch {
            interstitial = nil // no fill or offline: the game just continues without an ad
        }
    }
    
    private func loadRewarded() async {
        guard rewarded == nil else { return }
        do {
            let ad = try await RewardedAd.load(with: AdConfig.rewardedUnitID, request: Request())
            ad.fullScreenContentDelegate = self
            rewarded = ad
        } catch {
            rewarded = nil
        }
        isRewardedReady = rewarded != nil
    }
    #endif
    
    private var isInterstitialReady: Bool {
        #if canImport(GoogleMobileAds)
        return interstitial != nil
        #elseif DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// Whether a button offering a rewarded ad should be shown. Players who bought
    /// "Remove Ads" get the reward instantly, so they always see it.
    func canOfferRewarded(adsRemoved: Bool) -> Bool {
        adsRemoved || isRewardedReady
    }
    
    // MARK: Policy
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
        guard isInterstitialReady else { // nothing loaded: don't make the player wait
            AppAnalytics.shared.log(AnalyticsEvent.interstitialNoFill)
            Task { await preloadAds() }
            then()
            return
        }
        AppAnalytics.shared.log(AnalyticsEvent.interstitialShown, ["games_played": totalGames])
        gamesSinceInterstitial = 0
        lastInterstitial = Date()
        present(.interstitial) { _ in then() }
    }
    
    /// Opt-in reward ad. `completion(true)` means the reward should be granted.
    /// Players who bought "Remove Ads" get the reward instantly.
    /// `placement` names where the offer appeared (e.g. "double_coins") so analytics can compare them.
    func showRewarded(adsRemoved: Bool, placement: String, completion: @escaping (Bool) -> Void) {
        AppAnalytics.shared.log(AnalyticsEvent.rewardedRequested,
                                ["placement": placement, "instant": adsRemoved, "ready": isRewardedReady])
        if adsRemoved {
            lastRewardTier = Economy.adMultipliers.count - 1 // no ad to measure, so Remove Ads buyers get the top reward
            AppAnalytics.shared.log(AnalyticsEvent.rewardedResult,
                                    ["placement": placement, "earned": true, "instant": true, "tier": lastRewardTier])
            completion(true)
            return
        }
        pendingTier = nil
        present(.rewarded) { [weak self] earned in
            AppAnalytics.shared.log(AnalyticsEvent.rewardedResult, [
                "placement": placement, "earned": earned, "instant": false, "tier": self?.lastRewardTier ?? 0
            ])
            completion(earned)
        }
    }
    
    // MARK: Presenting
    private func present(_ kind: AdKind, completion: @escaping (Bool) -> Void) {
        #if canImport(GoogleMobileAds)
        guard let viewController = topViewController() else {
            completion(false)
            return
        }
        self.completion = completion
        rewardEarned = false
        switch kind {
        case .interstitial:
            guard let ad = interstitial else { finishCurrentAd(); return }
            interstitial = nil
            ad.present(from: viewController)
        case .rewarded:
            guard let ad = rewarded else { finishCurrentAd(); return }
            rewarded = nil
            isRewardedReady = false
            ad.present(from: viewController) { [weak self] in
                self?.rewardEarned = true
            }
        }
        #elseif DEBUG
        self.completion = completion
        presented = kind
        #else
        completion(false) // no SDK linked in a Release build: show nothing, grant nothing
        #endif
    }
    
    /// Called by the DEBUG placeholder ad view when it closes.
    func finishPresentedAd(rewardEarned: Bool) {
        self.rewardEarned = rewardEarned
        presented = nil
        finishCurrentAd()
    }
    
    private func finishCurrentAd() {
        let finished = completion
        let earned = rewardEarned
        if earned {
            // The payout is reported while the ad plays. If it never arrived, the player still
            // gets the guaranteed minimum. Debug builds pick a random tier so every one can be seen.
            #if DEBUG
            lastRewardTier = pendingTier ?? Int.random(in: 0..<Economy.adMultipliers.count)
            #else
            lastRewardTier = pendingTier ?? 0
            #endif
        }
        pendingTier = nil
        completion = nil
        rewardEarned = false
        finished?(earned)
        Task { await preloadAds() }
    }
    
    private func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.keyWindow?.rootViewController
        while let next = top?.presentedViewController {
            top = next
        }
        return top
    }
}

#if canImport(GoogleMobileAds)
extension AdManager: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in finishCurrentAd() }
    }
    
    /// Reports what each ad impression earned, so you can see revenue per player and per placement.
    nonisolated func ad(_ ad: FullScreenPresentingAd, didRecordPaidEventWith adValue: AdValue) {
        let ecpm = adValue.value.doubleValue * 1000 // revenue per impression -> per 1000 impressions
        AppAnalytics.shared.log(AnalyticsEvent.adImpression, [
            "ad_platform": "admob",
            "ad_format": ad is RewardedAd ? "rewarded" : "interstitial",
            "value": adValue.value.doubleValue,
            "currency": adValue.currencyCode,
            "ecpm": ecpm
        ])
        if ad is RewardedAd {
            Task { @MainActor in pendingTier = Economy.tier(forEcpm: ecpm) }
        }
    }
    
    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            rewardEarned = false
            finishCurrentAd()
        }
    }
}
#endif
