//
//  MainMenuView.swift
//  TicTacToe
//
//  Created by Noah Boyers on 12/10/21.
//

import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var ads: AdManager
    
    @State private var selectedMode: GameMode = .computer(difficulty: 0)
    @State private var selectedVariant: GameVariant = .classic
    @State private var isPlaying = false
    @State private var showShop = false
    @State private var showProgress = false
    @State private var showRanks = false
    @State private var showDaily = false
    
    private let modes: [(mode: GameMode, icon: String, palette: ButtonPalette)] = [
        (.computer(difficulty: 0), "tortoise.fill", .green),
        (.computer(difficulty: 1), "hare.fill", .blue),
        (.computer(difficulty: 2), "flame.fill", .orange),
        (.computer(difficulty: 3), "brain.head.profile", .red),
        (.twoPlayer, "person.2.fill", .purple)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackdrop()
                
                VStack(spacing: 0) {
                    topHUD
                    Spacer()
                    logo
                    Spacer()
                    variantPicker
                        .padding(.bottom, 12)
                    modePicker
                    playButton
                        .padding(.top, 18)
                    rivalStrip
                        .padding(.top, 12)
                    Spacer()
                    bottomBar
                }
                .padding(.horizontal)
                
                if showDaily {
                    dailyPopup
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $isPlaying) {
                GameView(mode: selectedMode, variant: selectedVariant)
            }
            .sheet(isPresented: $showShop) { ShopView() }
            .sheet(isPresented: $showProgress) { AchievementsView() }
            .sheet(isPresented: $showRanks) { LeaderboardView() }
            .onAppear { progress.refreshWeek() }
        }
        .fullScreenCover(item: $ads.presented) { kind in
            AdPlaceholderView(kind: kind) { earned in
                ads.finishPresentedAd(rewardEarned: earned)
            }
        }
    }
    
    // MARK: Top HUD
    private var topHUD: some View {
        HStack(spacing: 10) {
            LevelBadge(level: progress.level, progress: progress.levelProgress)
            
            Spacer()
            
            if progress.activeDailyStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill").foregroundColor(.orange)
                    Text("\(progress.activeDailyStreak)")
                        .font(gameFont(18))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.black.opacity(0.35))
                                .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 2)))
            }
            
            CoinPill(amount: progress.coins) { showShop = true }
        }
        .padding(.top, 8)
    }
    
    // MARK: Logo
    private var logo: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                logoTile(symbol: "xmark", color: BoardTheme.classic.xColor, delay: 0)
                logoTile(symbol: "circle", color: BoardTheme.classic.oColor, delay: 0.3)
                logoTile(symbol: "xmark", color: BoardTheme.classic.xColor, delay: 0.6)
            }
            Text("TIC TAC TOE")
                .font(gameFont(46, weight: .black))
                .foregroundStyle(LinearGradient(colors: [Color(red: 1.0, green: 0.97, blue: 0.6), GamePalette.goldDeep],
                                                startPoint: .top, endPoint: .bottom))
                .outlined(GamePalette.goldEdge, width: 3)
                .shadow(color: Color.black.opacity(0.4), radius: 0, x: 0, y: 6)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text("TAP · WIN · RISE")
                .font(gameFont(14))
                .foregroundColor(.white)
                .kerning(3)
                .outlined(GamePalette.ink, width: 1)
        }
    }
    
    private func logoTile(symbol: String, color: Color, delay: Double) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(LinearGradient(colors: [BoardTheme.classic.tileTop, BoardTheme.classic.tileBottom],
                                     startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.white.opacity(0.6), lineWidth: 2))
            Image(systemName: symbol)
                .font(.system(size: 38, weight: .black))
                .foregroundColor(color)
        }
        .frame(width: 76, height: 76)
        .background(RoundedRectangle(cornerRadius: 18).fill(BoardTheme.classic.tileEdge).offset(y: 6))
        .bobbing(distance: 5, delay: delay)
    }
    
    // MARK: Variant
    private var variantPicker: some View {
        HStack(spacing: 10) {
            variantButton(title: "CLASSIC", subtitle: "3×3", variant: .classic, palette: .blue)
            variantButton(title: "ULTIMATE", subtitle: "9×9 STRATEGY", variant: .ultimate, palette: .purple)
        }
    }
    
    private func variantButton(title: String, subtitle: String, variant: GameVariant,
                               palette: ButtonPalette) -> some View {
        let selected = selectedVariant == variant
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { selectedVariant = variant }
        } label: {
            VStack(spacing: 0) {
                Text(title).font(gameFont(18, weight: .black))
                Text(subtitle).font(gameFont(10)).opacity(0.85)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ChunkyButtonStyle(palette: selected ? palette : .gray, cornerRadius: 16, depth: 5))
        .overlay(RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(selected ? Color.white : Color.clear, lineWidth: 3)
                    .padding(.bottom, 5))
        .overlay(alignment: .topTrailing) {
            if variant == .ultimate {
                Text("NEW")
                    .font(gameFont(10, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(ButtonPalette.red.bottom))
                    .rotationEffect(.degrees(8))
                    .offset(x: 6, y: -8)
            }
        }
        .scaleEffect(selected ? 1.03 : 0.97)
    }
    
    // MARK: Modes
    private var modePicker: some View {
        HStack(spacing: 8) {
            ForEach(modes, id: \.mode) { item in
                let selected = item.mode == selectedMode
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { selectedMode = item.mode }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.icon).font(.system(size: 22, weight: .black))
                        Text(item.mode == .twoPlayer ? "2P" : item.mode.title.uppercased())
                            .font(gameFont(9))
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(palette: selected ? item.palette : .gray, cornerRadius: 16, depth: 5))
                .overlay(RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(selected ? Color.white : Color.clear, lineWidth: 3)
                            .padding(.bottom, 5))
                .scaleEffect(selected ? 1.1 : 0.95)
                .zIndex(selected ? 1 : 0)
            }
        }
        .padding(12)
        .gamePanel()
    }
    
    private var playButton: some View {
        Button { isPlaying = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                Text("PLAY")
            }
            .font(gameFont(38, weight: .black))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ChunkyButtonStyle(palette: .green, cornerRadius: 28, depth: 10))
        .pulsing(1.03)
    }
    
    // MARK: Rival strip
    @ViewBuilder
    private var rivalStrip: some View {
        Button { showRanks = true } label: {
            HStack(spacing: 8) {
                Text("#\(progress.weeklyRank)")
                    .font(gameFont(18, weight: .black))
                    .foregroundColor(GamePalette.gold)
                if let rival = progress.nextRival {
                    Text("\(rival.gap) pts to pass \(rival.entry.name.uppercased())")
                        .font(gameFont(14))
                        .foregroundColor(.white)
                } else {
                    Text("TOP OF THE LADDER")
                        .font(gameFont(14))
                        .foregroundColor(.white)
                }
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .black)).foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.black.opacity(0.35))
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 2)))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: Bottom bar
    private var bottomBar: some View {
        HStack(spacing: 14) {
            navButton(title: "SHOP", icon: "cart.fill", palette: .orange) { showShop = true }
            navButton(title: "DAILY", icon: "gift.fill", palette: .purple, badge: progress.canClaimDaily) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) { showDaily = true }
            }
            navButton(title: "RANKS", icon: "list.number", palette: .green) { showRanks = true }
            navButton(title: "PROGRESS", icon: "trophy.fill", palette: .blue) { showProgress = true }
        }
        .padding(12)
        .gamePanel()
        .padding(.bottom, 8)
    }
    
    private func navButton(title: String, icon: String, palette: ButtonPalette, badge: Bool = false,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon).font(.system(size: 22, weight: .black))
                Text(title).font(gameFont(10)).minimumScaleFactor(0.7).lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ChunkyButtonStyle(palette: palette, cornerRadius: 16, depth: 5))
        .overlay(alignment: .topTrailing) {
            if badge {
                Circle()
                    .fill(ButtonPalette.red.bottom)
                    .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))
                    .frame(width: 18, height: 18)
                    .offset(x: 6, y: -6)
                    .pulsing(1.2)
            }
        }
    }
    
    // MARK: Daily reward popup
    private var dailyPopup: some View {
        let todayIndex = min(progress.activeDailyStreak, 6)
        
        return ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .onTapGesture { closeDaily() }
            
            VStack(spacing: 16) {
                Text("DAILY REWARD")
                    .font(gameFont(30, weight: .black))
                    .foregroundColor(GamePalette.gold)
                    .outlined(GamePalette.goldEdge, width: 2.5)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(0..<7, id: \.self) { day in
                        dayTile(day: day, todayIndex: todayIndex)
                    }
                }
                
                if progress.canClaimDaily {
                    Button {
                        progress.claimDaily()
                        Haptics.success()
                        closeDaily()
                    } label: {
                        Text("CLAIM").font(gameFont(26, weight: .black)).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ChunkyButtonStyle(palette: .green, cornerRadius: 22, depth: 8))
                    
                    Button {
                        ads.showRewarded(adsRemoved: progress.adsRemoved) { earned in
                            progress.claimDaily(multiplier: earned ? ads.rewardMultiplier : 1)
                            Haptics.success()
                            closeDaily()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "play.rectangle.fill")
                            Text("CLAIM ×\(ads.rewardMultiplier)")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ChunkyButtonStyle(palette: .orange, cornerRadius: 18))
                } else {
                    Text("Come back tomorrow for more!")
                        .font(gameFont(16))
                        .foregroundColor(.white.opacity(0.85))
                    Button { closeDaily() } label: {
                        Text("OK").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ChunkyButtonStyle(palette: .blue))
                }
            }
            .padding(20)
            .gamePanel(cornerRadius: 30)
            .padding(.horizontal, 24)
            .overlay(alignment: .topTrailing) {
                CloseButton { closeDaily() }
                    .padding(.trailing, 16)
                    .offset(y: -16)
            }
        }
    }
    
    private func dayTile(day: Int, todayIndex: Int) -> some View {
        let claimedAlready = progress.canClaimDaily ? day < todayIndex : day <= todayIndex
        let isToday = progress.canClaimDaily && day == todayIndex
        let amount = 25 + 15 * day
        
        return VStack(spacing: 4) {
            Text("DAY \(day + 1)").font(gameFont(11)).foregroundColor(.white.opacity(0.9))
            if claimedAlready {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(ButtonPalette.green.top)
            } else {
                CoinIcon(size: 28)
            }
            Text("\(amount)").font(gameFont(15)).foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14)
                        .fill(isToday ? GamePalette.panelLight : Color.black.opacity(0.25)))
        .overlay(RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isToday ? GamePalette.gold : Color.clear, lineWidth: 3))
        .scaleEffect(isToday ? 1.05 : 1)
        .opacity(claimedAlready ? 0.6 : 1)
    }
    
    private func closeDaily() {
        withAnimation(.easeOut(duration: 0.2)) { showDaily = false }
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
            .environmentObject(ProgressStore())
            .environmentObject(AdManager())
    }
}
