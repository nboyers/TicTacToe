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
    
    var coinAmount: Int {
        switch self {
        case .removeAds: return 0
        case .coins500: return 500
        case .coins1500: return 1500
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
        do {
            switch try await product.purchase() {
            case .success(let verification):
                await handle(verification)
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = "Purchase failed. You have not been charged."
        }
    }
    
    func restorePurchases() async {
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
        switch StoreProduct(rawValue: transaction.productID) {
        case .removeAds:
            progress.setAdsRemoved()
        case .coins500, .coins1500:
            progress.add(coins: StoreProduct(rawValue: transaction.productID)?.coinAmount ?? 0)
        case nil:
            break
        }
        await transaction.finish() // only after the goods are delivered
    }
}
