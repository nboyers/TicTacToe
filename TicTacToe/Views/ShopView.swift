//
//  ShopView.swift
//  TicTacToe
//

import SwiftUI
import StoreKit

struct ShopView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var store: StoreManager
    @Environment(\.dismiss) private var dismiss
    
    private let themeColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    
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
                        
                        RibbonTitle(text: "BOOSTS")
                            .padding(.top, 8)
                        
                        ForEach(Boost.allCases) { boost in
                            boostCard(boost)
                        }
                        
                        RibbonTitle(text: "PIECE SKINS")
                            .padding(.top, 8)
                        
                        LazyVGrid(columns: themeColumns, spacing: 12) {
                            ForEach(PieceSkin.allCases) { skin in
                                skinCard(skin)
                            }
                        }
                        
                        RibbonTitle(text: "BOARD THEMES")
                            .padding(.top, 8)
                        
                        LazyVGrid(columns: themeColumns, spacing: 12) {
                            ForEach(BoardTheme.allCases) { theme in
                                themeCard(theme)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
        .disabled(store.isPurchasing)
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
    
    // MARK: Products
    private func productCard(_ product: Product) -> some View {
        let kind = StoreProduct(rawValue: product.id)
        let owned = kind == .removeAds && progress.adsRemoved
        let bestValue = kind == .coins1500
        
        return HStack(spacing: 14) {
            ZStack {
                if kind == .removeAds {
                    Image(systemName: "nosign")
                        .font(.system(size: 36, weight: .black))
                        .foregroundColor(ButtonPalette.red.top)
                } else {
                    CoinIcon(size: kind == .coins1500 ? 54 : 44)
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
                    .lineLimit(2)
            }
            
            Spacer(minLength: 4)
            
            if owned {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(ButtonPalette.green.top)
            } else {
                Button { Task { await store.purchase(product) } } label: {
                    Text(product.displayPrice).frame(minWidth: 56)
                }
                .buttonStyle(ChunkyButtonStyle(palette: .green, cornerRadius: 16, depth: 5))
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
                .frame(width: 56, height: 56)
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
            
            Spacer(minLength: 4)
            
            Button {
                if !progress.buy(boost) { Haptics.failure() }
            } label: {
                HStack(spacing: 4) {
                    CoinIcon(size: 20)
                    Text("\(boost.price)")
                }
            }
            .buttonStyle(ChunkyButtonStyle(palette: .orange, cornerRadius: 14, depth: 4))
            .disabled(!canBuy || progress.coins < boost.price)
        }
        .padding(14)
        .gamePanel(cornerRadius: 22)
    }
    
    // MARK: Skins
    private func skinCard(_ skin: PieceSkin) -> some View {
        let equipped = progress.skin == skin
        let owned = progress.owns(skin)
        
        return VStack(spacing: 10) {
            HStack(spacing: 14) {
                skinPreview(skin, piece: .X)
                skinPreview(skin, piece: .O)
            }
            .frame(height: 56)
            
            Text(skin.name.uppercased())
                .font(gameFont(16, weight: .black))
                .foregroundColor(.white)
            
            if equipped {
                Label("EQUIPPED", systemImage: "checkmark")
                    .font(gameFont(13))
                    .foregroundColor(ButtonPalette.green.top)
                    .frame(height: 38)
            } else if owned {
                Button { _ = progress.buyOrSelect(skin) } label: {
                    Text("EQUIP").font(gameFont(15)).frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(palette: .blue, cornerRadius: 14, depth: 4))
            } else {
                Button {
                    if !progress.buyOrSelect(skin) { Haptics.failure() }
                } label: {
                    HStack(spacing: 4) {
                        CoinIcon(size: 20)
                        Text("\(skin.price)").font(gameFont(15))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(palette: .orange, cornerRadius: 14, depth: 4))
                .disabled(progress.coins < skin.price)
            }
        }
        .padding(12)
        .gamePanel(cornerRadius: 22, fill: equipped ? GamePalette.panelLight : GamePalette.panel)
        .overlay(RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(equipped ? GamePalette.gold : Color.clear, lineWidth: 3))
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
        
        return VStack(spacing: 10) {
            ZStack {
                LinearGradient(colors: theme.background, startPoint: .top, endPoint: .bottom)
                HStack(spacing: 8) {
                    miniTile(symbol: "xmark", color: theme.xColor, theme: theme)
                    miniTile(symbol: "circle", color: theme.oColor, theme: theme)
                }
            }
            .frame(height: 78)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            
            Text(theme.name.uppercased())
                .font(gameFont(16, weight: .black))
                .foregroundColor(.white)
            
            if equipped {
                Label("EQUIPPED", systemImage: "checkmark")
                    .font(gameFont(13))
                    .foregroundColor(ButtonPalette.green.top)
                    .frame(height: 38)
            } else if owned {
                Button { _ = progress.buyOrSelect(theme) } label: {
                    Text("EQUIP").font(gameFont(15)).frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(palette: .blue, cornerRadius: 14, depth: 4))
            } else {
                Button {
                    if !progress.buyOrSelect(theme) { Haptics.failure() }
                } label: {
                    HStack(spacing: 4) {
                        CoinIcon(size: 20)
                        Text("\(theme.price)").font(gameFont(15))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(palette: .orange, cornerRadius: 14, depth: 4))
                .disabled(progress.coins < theme.price)
            }
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
