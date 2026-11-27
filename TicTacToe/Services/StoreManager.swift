//
//  StoreManager.swift
//  TicTacToe
//
//  StoreKit 2 in-app purchases: Remove Ads (non-consumable) and coin packs (consumable).
//  Create these product IDs in App Store Connect (or a local .storekit file for testing).
//

import Foundation
import StoreKit

enum StoreProduct: String, CaseIterable {
    case removeAds = "frent.nobos.TicTacToe.removeads"
    case coins500 = "frent.nobos.TicTacToe.coins500"
    case coins1500 = "frent.nobos.TicTacToe.coins1500"
    case coins5000 = "frent.nobos.TicTacToe.coins5000"
    case coins15000 = "frent.nobos.TicTacToe.coins15000"
    
    var coinAmount: Int {
        switch self {
        case .removeAds: return 0
        case .coins500: return 500
        case .coins1500: return 1_500
        case .coins5000: return 5_000
        case .coins15000: return 15_000
        }
    }
}

@MainActor
final class StoreManager: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var isPurchasing = false
    @Published var errorMessage: String?
    
    private let progress: ProgressStore
    private var updatesTask: Task<Void, Never>?
    
    init(progress: ProgressStore) {
        self.progress = progress
        
        // Catches purchases that finish outside the app (Ask to Buy, interrupted purchases)
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
        
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }
    
    deinit {
        updatesTask?.cancel()
    }
    
    func loadProducts() async {
        do {
            let ids = StoreProduct.allCases.map(\.rawValue)
            products = try await Product.products(for: ids).sorted { $0.price < $1.price }
        } catch {
            errorMessage = "Couldn't load the store. Check your connection."
        }
    }
    
    func purchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }
        AppAnalytics.shared.log(AnalyticsEvent.purchaseStart, ["product_id": product.id])
        do {
            switch try await product.purchase() {
            case .success(let verification):
                await handle(verification)
                if case .verified = verification {
                    AppAnalytics.shared.log(AnalyticsEvent.purchase, [
                        "product_id": product.id,
                        "value": NSDecimalNumber(decimal: product.price).doubleValue,
                        "currency": product.priceFormatStyle.currencyCode
                    ])
                } else {
                    AppAnalytics.shared.log(AnalyticsEvent.purchaseFailed, ["product_id": product.id, "reason": "unverified"])
                }
            case .userCancelled:
                AppAnalytics.shared.log(AnalyticsEvent.purchaseCancelled, ["product_id": product.id])
            case .pending:
                AppAnalytics.shared.log(AnalyticsEvent.purchaseCancelled, ["product_id": product.id, "reason": "pending"])
            @unknown default:
                break
            }
        } catch {
            AppAnalytics.shared.log(AnalyticsEvent.purchaseFailed, ["product_id": product.id, "reason": "error"])
            errorMessage = "Purchase failed. You have not been charged."
        }
    }
    
    func restorePurchases() async {
        AppAnalytics.shared.log(AnalyticsEvent.restorePurchases)
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = "Couldn't restore purchases."
        }
    }
    
    private func refreshEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == StoreProduct.removeAds.rawValue,
               transaction.revocationDate == nil {
                progress.setAdsRemoved()
            }
        }
    }
    
    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        if let product = StoreProduct(rawValue: transaction.productID) {
            if product == .removeAds {
                progress.setAdsRemoved()
            } else {
                progress.add(coins: product.coinAmount)
            }
        }
        await transaction.finish() // only after the goods are delivered
    }
}
