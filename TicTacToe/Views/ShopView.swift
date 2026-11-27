//
//  ShopView.swift
//  TicTacToe
//

import SwiftUI
import StoreKit

struct ShopView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var ads: AdManager
    @Environment(\.dismiss) private var dismiss
    
    private let themeColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    
    private struct PendingPurchase: Identifiable {
        let id = UUID()
        let name: String
        let price: Int
        let action: () -> Void
    }
    @State private var pendingPurchase: PendingPurchase?
    @State private var shortfall: Int?
    
    /// Big purchases ask "are you sure?" first. Not having enough coins explains what's missing
    /// (and is logged, since it's the moment a coin pack makes sense).
    private func attemptPurchase(name: String, price: Int, action: @escaping () -> Void) {
        guard progress.coins >= price else {
            shortfall = price - progress.coins
            Haptics.failure()
            AppAnalytics.shared.log(AnalyticsEvent.lowCoinsPrompt, ["kind": "shop_\(name.lowercased())", "coins": progress.coins, "cost": price])
            return
        }
        if price >= Economy.confirmPurchaseThreshold {
            pendingPurchase = PendingPurchase(name: name, price: price, action: action)
        } else {
            action()
        }
    }
    
    var body: some View {
        ZStack {
            AnimatedBackdrop()
            
            VStack(spacing: 0) {
                HStack {
                    Text("SHOP")
                        .font(gameFont(36, weight: .black))
                        .foregroundColor(GamePalette.gold)
                        .outlined(GamePalette.goldEdge, width: 2.5)
                    Spacer()
                    CoinPill(amount: progress.coins)
                    CloseButton { dismiss() }
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 16) {
                        RibbonTitle(text: "COINS & PERKS")
                        
                        freeCoinsCard
                        
                        if store.products.isEmpty {
                            Text("Loading offers…")
                                .font(gameFont(16))
                                .foregroundColor(.white.opacity(0.8))
                                .padding()
                        }
                        ForEach(store.products, id: \.id) { product in
                            productCard(product)
                        }
                        
                        Button("RESTORE PURCHASES") {
                            Task { await store.restorePurchases() }
                        }
                        .font(gameFont(13))
                        .foregroundColor(.white.opacity(0.8))
                        
                        if ads.privacyOptionsRequired {
                            Button("AD PRIVACY CHOICES") {
                                Task { await ads.presentPrivacyOptions() }
                            }
                            .font(gameFont(13))
                            .foregroundColor(.white.opacity(0.8))
                        }
                        
                        RibbonTitle(text: "BOOSTS")
                            .padding(.top, 8)
                        
                        ForEach(Boost.allCases) { boost in
                            boostCard(boost)
                        }
                        
                        RibbonTitle(text: "PIECE SKINS")
                            .padding(.top, 8)
                        
                        LazyVGrid(columns: themeColumns, spacing: 12) {
                            ForEach(PieceSkin.allCases.filter { !$0.isVault }) { skin in
                                skinCard(skin)
                            }
                        }
                        
                        RibbonTitle(text: "BOARD THEMES")
                            .padding(.top, 8)
                        
                        LazyVGrid(columns: themeColumns, spacing: 12) {
                            ForEach(BoardTheme.allCases.filter { !$0.isVault }) { theme in
                                themeCard(theme)
                            }
                        }
                        
                        vaultSection
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
                .alert("Not enough coins", isPresented: Binding(get: { shortfall != nil },
                                                                set: { if !$0 { shortfall = nil } })) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("You need \((shortfall ?? 0).formatted()) more coins. Earn them by playing, or pick up a coin pack above.")
                }
            }
        }
        .confirmationDialog("Buy \(pendingPurchase?.name ?? "")?",
                            isPresented: Binding(get: { pendingPurchase != nil },
                                                 set: { if !$0 { pendingPurchase = nil } }),
                            titleVisibility: .visible, presenting: pendingPurchase) { purchase in
            Button("Spend \(purchase.price.formatted()) coins") { purchase.action() }
            Button("Cancel", role: .cancel) {}
        } message: { purchase in
            Text("This costs \(purchase.price.formatted()) coins. You have \(progress.coins.formatted()).")
        }
        .disabled(store.isPurchasing)
        .onAppear { AppAnalytics.shared.screen("shop") }
        .overlay {
            if store.isPurchasing {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView().scaleEffect(1.6).tint(.white)
                }
            }
        }
        .alert("Store", isPresented: Binding(get: { store.errorMessage != nil },
                                              set: { if !$0 { store.errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.errorMessage ?? "")
        }
    }
    
    // MARK: The Vault
    private var vaultSection: some View {
        VStack(spacing: 14) {
            RibbonTitle(text: "THE VAULT", palette: .gold)
                .padding(.top, 16)
            
            Text("Rare. Expensive. Yours forever.")
                .font(gameFont(13))
                .foregroundColor(GamePalette.gold)
            
            collectorCard
            
            Text("LEGENDARY SKINS")
                .font(gameFont(14))
                .foregroundColor(.white.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: themeColumns, spacing: 12) {
                ForEach(PieceSkin.allCases.filter { $0.isVault }) { skin in
                    skinCard(skin)
                }
            }
            
            Text("LEGENDARY THEMES")
                .font(gameFont(14))
                .foregroundColor(.white.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: themeColumns, spacing: 12) {
                ForEach(BoardTheme.allCases.filter { $0.isVault }) { theme in
                    themeCard(theme)
                }
            }
            
            Text("TITLES")
                .font(gameFont(14))
                .foregroundColor(.white.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(PlayerTitle.allCases) { title in
                titleRow(title)
            }
        }
    }
    
    /// Collector Rank never tops out: each rank costs more Vault spending than the last
    private var collectorCard: some View {
        let rank = progress.collectorRank
        return VStack(spacing: 8) {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 26, weight: .black))
                    .foregroundColor(GamePalette.gold)
                Text(rank == 0 ? "COLLECTOR RANK" : "COLLECTOR RANK \(rank)")
                    .font(gameFont(18, weight: .black))
                    .foregroundColor(.white)
                    .outlined(GamePalette.ink, width: 1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
            }
            ProgressView(value: min(max(progress.rankProgress, 0), 1))
                .tint(GamePalette.gold)
            Text("\(progress.coinsToNextRank.formatted()) coins in the Vault to reach rank \(rank + 1)")
                .font(gameFont(12, weight: .semibold))
                .foregroundColor(.white.opacity(0.75))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .gamePanel(cornerRadius: 22)
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(GamePalette.gold.opacity(0.6), lineWidth: 2))
    }
    
    private func titleRow(_ title: PlayerTitle) -> some View {
        let owned = progress.ownsTitle(title)
        let equipped = progress.title == title
        
        return HStack(spacing: 12) {
            Image(systemName: title.icon)
                .font(.system(size: 20, weight: .black))
                .foregroundColor(owned ? GamePalette.gold : .white.opacity(0.4))
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.black.opacity(0.3)))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title.name.uppercased())
                    .font(gameFont(16, weight: .black))
                    .foregroundColor(.white)
                Text(title.requirement)
                    .font(gameFont(12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)
            
            Spacer(minLength: 4)
            
            if equipped {
                Label("EQUIPPED", systemImage: "checkmark")
                    .font(gameFont(12))
                    .foregroundColor(ButtonPalette.green.top)
                    .fixedSize()
            } else if owned {
                Button { progress.equip(title) } label: {
                    Text("EQUIP").font(gameFont(14)).fixedSize()
                }
                .buttonStyle(ChunkyButtonStyle(palette: .blue, cornerRadius: 14, depth: 4, horizontalPadding: 12))
            } else if let price = title.price {
                Button {
                    attemptPurchase(name: title.name, price: price) {
                        if !progress.buyTitle(title) { Haptics.failure() }
                    }
                } label: {
                    HStack(spacing: 4) {
                        CoinIcon(size: 18)
                        Text(price.formatted()).font(gameFont(14)).lineLimit(1)
                    }
                    .fixedSize()
                }
                .buttonStyle(ChunkyButtonStyle(palette: .orange, cornerRadius: 14, depth: 4, horizontalPadding: 10))
            } else {
                Label("EARN IT", systemImage: "lock.fill")
                    .font(gameFont(11))
                    .foregroundColor(.white.opacity(0.5))
                    .fixedSize()
            }
        }
        .padding(12)
        .gamePanel(cornerRadius: 20, fill: equipped ? GamePalette.panelLight : GamePalette.panel)
        .overlay(RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(equipped ? GamePalette.gold : Color.clear, lineWidth: 3))
    }
    
    // MARK: Free coins
    private var freeCoinsCard: some View {
        let remaining = progress.freeCoinAdsRemaining
        let canWatch = remaining > 0 && ads.canOfferRewarded(adsRemoved: progress.adsRemoved)
        
        return HStack(spacing: 12) {
            CoinIcon(size: 44)
                .frame(width: 52, height: 52)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("FREE COINS")
                    .font(gameFont(18, weight: .black))
                    .foregroundColor(.white)
                    .outlined(GamePalette.ink, width: 1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(remaining > 0 ? "\(remaining) left today" : "Come back tomorrow")
                    .font(gameFont(12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(1)
                if remaining > 0 && !progress.adsRemoved {
                    Text("Watch an ad")
                        .font(gameFont(12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                        .lineLimit(1)
                }
            }
            .layoutPriority(1)
            
            Spacer(minLength: 4)
            
            if canWatch {
                Button {
                    ads.showRewarded(adsRemoved: progress.adsRemoved, placement: "free_coins") { earned in
                        if earned {
                            progress.claimFreeCoins(coins: ads.lastFreeCoins) // set by what the ad paid
                            Haptics.success()
                        }
                    }
                } label: {
                    // One tidy line: icon then the coin range. fixedSize stops it wrapping or stacking.
                    HStack(spacing: 5) {
                        Image(systemName: "play.rectangle.fill")
                        Text(ads.freeCoinsLabel(adsRemoved: progress.adsRemoved))
                            .lineLimit(1)
                        CoinIcon(size: 20)
                    }
                    .fixedSize()
                }
                .buttonStyle(ChunkyButtonStyle(palette: .green, cornerRadius: 16, depth: 5, horizontalPadding: 12))
            }
        }
        .padding(14)
        .gamePanel(cornerRadius: 22)
    }
    
    // MARK: Products
    private func productCard(_ product: Product) -> some View {
        let kind = StoreProduct(rawValue: product.id)
        let owned = kind == .removeAds && progress.adsRemoved
        let bestValue = kind == .coins15000
        
        return HStack(spacing: 14) {
            ZStack {
                if kind == .removeAds {
                    Image(systemName: "nosign")
                        .font(.system(size: 36, weight: .black))
                        .foregroundColor(ButtonPalette.red.top)
                } else {
                    CoinIcon(size: kind == .coins15000 ? 56 : (kind == .coins5000 ? 50 : 44))
                }
            }
            .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(product.displayName.uppercased())
                    .font(gameFont(18, weight: .black))
                    .foregroundColor(.white)
                    .outlined(GamePalette.ink, width: 1)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(product.description)
                    .font(gameFont(12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true) // wrap onto as many lines as it needs
            }
            .layoutPriority(1) // the text gets its room first; the price button stays compact
            
            Spacer(minLength: 4)
            
            if owned {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(ButtonPalette.green.top)
            } else {
                Button { Task { await store.purchase(product) } } label: {
                    Text(product.displayPrice).lineLimit(1).fixedSize()
                }
                .buttonStyle(ChunkyButtonStyle(palette: .green, cornerRadius: 16, depth: 5, horizontalPadding: 12))
            }
        }
        .padding(14)
        .gamePanel(cornerRadius: 22, fill: bestValue ? GamePalette.panelLight : GamePalette.panel)
        .overlay(alignment: .topLeading) {
            if bestValue {
                Text("BEST VALUE")
                    .font(gameFont(11, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(ButtonPalette.red.bottom))
                    .rotationEffect(.degrees(-6))
                    .offset(x: -6, y: -10)
            }
        }
    }
    
    // MARK: Boosts
    private func boostCard(_ boost: Boost) -> some View {
        let count = progress.owned(of: boost)
        let canBuy = progress.canBuy(boost)
        
        return HStack(spacing: 14) {
            Image(systemName: boost.icon)
                .font(.system(size: 26, weight: .black))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Circle().fill(ButtonPalette.orange.bottom))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(boost.title.uppercased())
                    .font(gameFont(17, weight: .black))
                    .foregroundColor(.white)
                    .outlined(GamePalette.ink, width: 1)
                Text(boost.detail)
                    .font(gameFont(12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
                if count > 0 {
                    Text(boost == .coinMagnet ? "\(count) games left" : "Active: \(count)")
                        .font(gameFont(11))
                        .foregroundColor(GamePalette.gold)
                }
            }
            .layoutPriority(1)
            
            Spacer(minLength: 4)
            
            Button {
                if !progress.buy(boost) { Haptics.failure() }
            } label: {
                HStack(spacing: 4) {
                    CoinIcon(size: 20)
                    Text(boost.price.formatted()).lineLimit(1)
                }
                .fixedSize() // never squeeze the price: it keeps its natural width
            }
            .buttonStyle(ChunkyButtonStyle(palette: .orange, cornerRadius: 14, depth: 4, horizontalPadding: 12))
            .disabled(!canBuy || progress.coins < boost.price)
            .layoutPriority(2) // the button wins space over the description, which can wrap instead
        }
        .padding(14)
        .gamePanel(cornerRadius: 22)
    }
    
    // MARK: Skins
    private func skinCard(_ skin: PieceSkin) -> some View {
        let equipped = progress.skin == skin
        let owned = progress.owns(skin)
        
        // Limited items show how long they can still be bought; other Vault items are marked legendary
        let caption: String = {
            if !owned, let days = skin.daysLeft { return skin.isAvailable ? "LIMITED · \(days)d LEFT" : "RETIRED" }
            return skin.isVault ? "LEGENDARY" : ""
        }()
        
        return VStack(spacing: 8) {
            HStack(spacing: 10) {
                skinPreview(skin, piece: .X).frame(width: 48, height: 48)
                skinPreview(skin, piece: .O).frame(width: 48, height: 48)
            }
            .frame(height: 56)
            
            cardLabels(name: skin.name, caption: caption,
                       captionColor: caption.hasPrefix("LIMITED") ? ButtonPalette.red.top : GamePalette.gold)
            
            // Same height whichever state the card is in, so every card in the grid matches
            ZStack {
                if equipped {
                    equippedLabel
                } else if owned {
                    equipButton { _ = progress.buyOrSelect(skin) }
                } else if !skin.isAvailable {
                    Text("NO LONGER AVAILABLE")
                        .font(gameFont(11))
                        .foregroundColor(.white.opacity(0.5))
                } else {
                    priceButton(skin.price) {
                        attemptPurchase(name: skin.name, price: skin.price) {
                            if !progress.buyOrSelect(skin) { Haptics.failure() }
                        }
                    }
                }
            }
            .frame(height: Self.cardActionHeight)
        }
        .padding(12)
        .gamePanel(cornerRadius: 22, fill: equipped ? GamePalette.panelLight : GamePalette.panel)
        .overlay(RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(equipped ? GamePalette.gold : Color.clear, lineWidth: 3))
    }
    
    // MARK: Shared pieces of the skin and theme cards
    private static let cardActionHeight: CGFloat = 52
    
    /// Name plus a caption line that always takes up space, even when empty
    private func cardLabels(name: String, caption: String, captionColor: Color) -> some View {
        VStack(spacing: 2) {
            Text(name.uppercased())
                .font(gameFont(16, weight: .black))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(caption.isEmpty ? " " : caption)
                .font(gameFont(11, weight: .black))
                .foregroundColor(captionColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
    
    private var equippedLabel: some View {
        Label("EQUIPPED", systemImage: "checkmark")
            .font(gameFont(13))
            .foregroundColor(ButtonPalette.green.top)
    }
    
    private func equipButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("EQUIP").font(gameFont(15)).frame(maxWidth: .infinity)
        }
        .buttonStyle(ChunkyButtonStyle(palette: .blue, cornerRadius: 14, depth: 4, horizontalPadding: 8))
    }
    
    private func priceButton(_ price: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                CoinIcon(size: 20)
                Text(price.formatted()).font(gameFont(15)).lineLimit(1).minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ChunkyButtonStyle(palette: .orange, cornerRadius: 14, depth: 4, horizontalPadding: 8))
    }
    
    @ViewBuilder
    private func skinPreview(_ skin: PieceSkin, piece: Piece) -> some View {
        if let glyph = skin.glyph(for: piece) {
            Text(glyph).font(.system(size: 40))
        } else if piece == .X {
            XMark()
                .stroke(BoardTheme.classic.xColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 34, height: 34)
        } else {
            Circle()
                .strokeBorder(BoardTheme.classic.oColor, lineWidth: 8)
                .frame(width: 38, height: 38)
        }
    }
    
    // MARK: Themes
    private func themeCard(_ theme: BoardTheme) -> some View {
        let equipped = progress.theme == theme
        let owned = progress.owns(theme)
        
        return VStack(spacing: 8) {
            ZStack {
                LinearGradient(colors: theme.background, startPoint: .top, endPoint: .bottom)
                HStack(spacing: 8) {
                    miniTile(symbol: "xmark", color: theme.xColor, theme: theme)
                    miniTile(symbol: "circle", color: theme.oColor, theme: theme)
                }
            }
            .frame(height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            
            cardLabels(name: theme.name, caption: theme.isVault ? "LEGENDARY" : "", captionColor: GamePalette.gold)
            
            ZStack {
                if equipped {
                    equippedLabel
                } else if owned {
                    equipButton { _ = progress.buyOrSelect(theme) }
                } else {
                    priceButton(theme.price) {
                        attemptPurchase(name: theme.name, price: theme.price) {
                            if !progress.buyOrSelect(theme) { Haptics.failure() }
                        }
                    }
                }
            }
            .frame(height: Self.cardActionHeight)
        }
        .padding(12)
        .gamePanel(cornerRadius: 22, fill: equipped ? GamePalette.panelLight : GamePalette.panel)
        .overlay(RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(equipped ? GamePalette.gold : Color.clear, lineWidth: 3))
    }
    
    private func miniTile(symbol: String, color: Color, theme: BoardTheme) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [theme.tileTop, theme.tileBottom], startPoint: .top, endPoint: .bottom))
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .black))
                .foregroundColor(color)
        }
        .frame(width: 40, height: 40)
        .background(RoundedRectangle(cornerRadius: 8).fill(theme.tileEdge).offset(y: 3))
    }
}
