//
//  ContentView.swift
//  TicTacToe
//
//  Created by Noah Boyers on 6/15/21.
//

import SwiftUI

struct GameView: View {
    
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var ads: AdManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: GameViewModel
    
    @State private var reward: RoundReward?
    @State private var rewardDoubled = false
    @State private var showResult = false
    @State private var pendingPerk: Perk?
    @State private var showShop = false
    @State private var showRules = false
    @AppStorage("seenUltimateRules") private var seenRules = false
    
    private let hintCost = 15
    private let undoCost = 10
    private let column: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
    
    enum Perk: Identifiable {
        case hint, undo
        var id: Self { self }
    }
    
    init(mode: GameMode, variant: GameVariant = .classic) {
        _viewModel = StateObject(wrappedValue: GameViewModel(mode: mode, variant: variant))
    }
    
    private var theme: BoardTheme { progress.theme }
    private var isUltimate: Bool { viewModel.variant == .ultimate }
    private var isTwoPlayer: Bool { viewModel.mode == .twoPlayer }
    
    private var isVictory: Bool {
        guard case .win(let piece) = viewModel.outcome else { return false }
        return isTwoPlayer || piece == .X
    }
    
    /// Fewer moves to win = more stars
    private var stars: Int {
        switch viewModel.outcome {
        case .none: return 0
        case .draw: return 1
        case .win(let piece):
            if isTwoPlayer { return 3 }
            if piece != .X { return 0 }
            if isUltimate { // fewer big squares lost = more stars
                let lost = viewModel.ultimateBoard.boardsWon(by: .O)
                return lost <= 1 ? 3 : (lost <= 3 ? 2 : 1)
            }
            let moves = viewModel.gameBoard.position.filter { $0 == .X }.count
            return moves <= 3 ? 3 : (moves == 4 ? 2 : 1)
        }
    }
    
    var body: some View {
        ZStack {
            AnimatedBackdrop(colors: theme.background)
            
            VStack(spacing: 14) {
                topBar
                versusBanner
                statusPill
                boardPanel
                helperButtons
                Spacer(minLength: 0)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            if showRules { rulesOverlay }
            
            if showResult, viewModel.outcome != nil {
                resultOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
                if isVictory { ConfettiView() }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if isUltimate && !seenRules {
                seenRules = true
                showRules = true
            }
        }
        .onChange(of: viewModel.outcome) { _, outcome in
            if let outcome { finish(with: outcome) }
        }
        .confirmationDialog("Need a boost?", isPresented: Binding(get: { pendingPerk != nil },
                                                                  set: { if !$0 { pendingPerk = nil } }),
                            titleVisibility: .visible) {
            Button("Watch a short ad") {
                if let perk = pendingPerk { watchAd(for: perk) }
            }
            Button("Get coins") { showShop = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You don't have enough coins for that.")
        }
        .sheet(isPresented: $showShop) { ShopView() }
    }
    
    // MARK: Header
    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left").font(.system(size: 18, weight: .black))
            }
            .buttonStyle(ChunkyButtonStyle(palette: .blue, cornerRadius: 14, depth: 4))
            
            Spacer()
            VStack(spacing: 0) {
                Text(viewModel.mode.title.uppercased())
                    .font(gameFont(22, weight: .black))
                    .foregroundColor(.white)
                    .outlined(GamePalette.ink, width: 2)
                if isUltimate {
                    Text("ULTIMATE")
                        .font(gameFont(12, weight: .black))
                        .foregroundColor(GamePalette.gold)
                        .outlined(GamePalette.goldEdge, width: 1)
                }
            }
            Spacer()
            
            if isUltimate {
                Button { withAnimation { showRules = true } } label: {
                    Image(systemName: "questionmark").font(.system(size: 18, weight: .black))
                }
                .buttonStyle(ChunkyButtonStyle(palette: .purple, cornerRadius: 14, depth: 4))
            }
            CoinPill(amount: progress.coins) { showShop = true }
        }
    }
    
    private var versusBanner: some View {
        HStack(spacing: 8) {
            playerCard(symbol: "xmark", color: theme.xColor, name: isTwoPlayer ? "PLAYER 1" : "YOU",
                       score: viewModel.playerWins, active: viewModel.outcome == nil && viewModel.currentTurn == .X)
            
            VStack(spacing: 2) {
                Text("VS")
                    .font(gameFont(26, weight: .black))
                    .foregroundColor(GamePalette.gold)
                    .outlined(GamePalette.goldEdge, width: 2)
                if !isTwoPlayer {
                    Text("\(viewModel.winRate)%")
                        .font(gameFont(14))
                        .foregroundColor(.white)
                    Text("WIN RATE")
                        .font(gameFont(9))
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    Text("\(viewModel.draws) DRAWS")
                        .font(gameFont(10))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(width: 70)
            
            playerCard(symbol: "circle", color: theme.oColor, name: isTwoPlayer ? "PLAYER 2" : "CPU",
                       score: viewModel.opponentWins, active: viewModel.outcome == nil && viewModel.currentTurn == .O)
        }
    }
    
    private func playerCard(symbol: String, color: Color, name: String, score: Int, active: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 26, weight: .black))
                .foregroundColor(color)
                .frame(width: 52, height: 52)
                .background(Circle().fill(Color.white).overlay(Circle().strokeBorder(color, lineWidth: 4)))
            Text(name)
                .font(gameFont(13))
                .foregroundColor(.white)
                .outlined(GamePalette.ink, width: 1)
            Text("\(score)")
                .font(gameFont(26, weight: .black))
                .foregroundColor(GamePalette.gold)
                .outlined(GamePalette.goldEdge, width: 1.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .gamePanel(cornerRadius: 20, fill: active ? GamePalette.panelLight : GamePalette.panel)
        .overlay(RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(active ? GamePalette.gold : Color.clear, lineWidth: 4))
        .scaleEffect(active ? 1.06 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: active)
    }
    
    private var statusPill: some View {
        Text(viewModel.statusText.uppercased())
            .font(gameFont(18))
            .foregroundColor(.white)
            .outlined(GamePalette.ink, width: 1.5)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.black.opacity(0.35))
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 2)))
            .animation(.none, value: viewModel.statusText)
    }
    
    // MARK: Board
    @ViewBuilder
    private var boardPanel: some View {
        if isUltimate { ultimatePanel } else { classicPanel }
    }
    
    private var ultimatePanel: some View {
        UltimateBoardView(board: viewModel.ultimateBoard, theme: theme, skin: progress.skin, hint: viewModel.ultimateHint,
                          interactive: !viewModel.isDisabled) { viewModel.playUltimate($0) }
            .padding(10)
            .gamePanel(cornerRadius: 24)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.ultimateBoard)
    }
    
    private var rulesOverlay: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
                .onTapGesture { withAnimation { showRules = false } }
            
            VStack(spacing: 14) {
                Text("ULTIMATE RULES")
                    .font(gameFont(28, weight: .black))
                    .foregroundColor(GamePalette.gold)
                    .outlined(GamePalette.goldEdge, width: 2)
                
                VStack(alignment: .leading, spacing: 10) {
                    ruleRow("1", "Every big square holds its own mini tic-tac-toe board.")
                    ruleRow("2", "Where you play inside a mini-board decides which mini-board your opponent must play in next.")
                    ruleRow("3", "Win a mini-board to claim that big square.")
                    ruleRow("4", "Claim three big squares in a row to win the game.")
                    ruleRow("5", "Sent to a board that is already decided? Play anywhere open.")
                }
                
                Button { withAnimation { showRules = false } } label: {
                    Text("GOT IT").font(gameFont(24, weight: .black)).frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(palette: .green, cornerRadius: 22, depth: 8))
            }
            .padding(20)
            .gamePanel(cornerRadius: 28)
            .padding(.horizontal, 24)
        }
        .transition(.opacity)
    }
    
    private func ruleRow(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(gameFont(16, weight: .black))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(ButtonPalette.purple.bottom))
            Text(text)
                .font(gameFont(15, weight: .semibold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var classicPanel: some View {
        let winningLine = viewModel.gameBoard.winningLine ?? []
        return LazyVGrid(columns: column, spacing: 10) {
            ForEach(0..<9, id: \.self) { i in
                tile(i, winning: winningLine.contains(i))
            }
        }
        .padding(14)
        .gamePanel(cornerRadius: 28)
        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: viewModel.gameBoard.position)
        .disabled(viewModel.isDisabled)
    }
    
    private func tile(_ i: Int, winning: Bool) -> some View {
        let piece = viewModel.gameBoard.position[i]
        let radius: CGFloat = 16
        let top = winning ? Color(red: 1.0, green: 0.95, blue: 0.5) : theme.tileTop
        let bottom = winning ? GamePalette.goldDeep : theme.tileBottom
        
        return ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(Color.white.opacity(0.6), lineWidth: 2))
            
            if viewModel.hintSquare == i {
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(GamePalette.gold, lineWidth: 5)
                    .pulsing(1.05)
            }
            
            if let glyph = progress.skin.glyph(for: piece) {
                Text(glyph)
                    .font(.system(size: 56))
                    .minimumScaleFactor(0.4)
                    .shadow(color: Color.black.opacity(0.25), radius: 0, x: 0, y: 4)
                    .transition(.scale(scale: 0.1).combined(with: .opacity))
            } else if piece == .X {
                XMark()
                    .stroke(theme.xColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .padding(30)
                    .shadow(color: Color.black.opacity(0.25), radius: 0, x: 0, y: 4)
                    .transition(.scale(scale: 0.1).combined(with: .opacity))
            } else if piece == .O {
                Circle()
                    .strokeBorder(theme.oColor, lineWidth: 16)
                    .padding(26)
                    .shadow(color: Color.black.opacity(0.25), radius: 0, x: 0, y: 4)
                    .transition(.scale(scale: 0.1).combined(with: .opacity))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .background(RoundedRectangle(cornerRadius: radius)
                        .fill(winning ? GamePalette.goldEdge : theme.tileEdge)
                        .offset(y: 5))
        .padding(.bottom, 5)
        .scaleEffect(winning ? 1.06 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: winning)
        .contentShape(Rectangle())
        .onTapGesture { viewModel.play(i) }
        .accessibilityLabel(piece == .E ? "Empty square \(i + 1)" : "\(piece == .X ? "X" : "O") in square \(i + 1)")
    }
    
    // MARK: Boosters
    @ViewBuilder
    private var helperButtons: some View {
        if !isTwoPlayer {
            HStack(spacing: 28) {
                booster(title: "HINT", icon: "lightbulb.fill", cost: hintCost, palette: .orange,
                        enabled: viewModel.canUseHelpers) { use(.hint) }
                booster(title: "UNDO", icon: "arrow.uturn.backward", cost: undoCost, palette: .purple,
                        enabled: viewModel.canUndo) { use(.undo) }
            }
            .padding(.top, 6)
        }
    }
    
    private func booster(title: String, icon: String, cost: Int, palette: ButtonPalette,
                         enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon).font(.system(size: 24, weight: .black))
                Text(title).font(gameFont(12))
            }
            .frame(width: 62)
        }
        .buttonStyle(ChunkyButtonStyle(palette: palette, cornerRadius: 20, depth: 6))
        .disabled(!enabled)
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 2) {
                CoinIcon(size: 14)
                Text("\(cost)").font(gameFont(12)).foregroundColor(.white)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.black.opacity(0.65)))
            .offset(x: 14, y: -8)
        }
    }
    
    // MARK: Result
    private var resultTitle: String {
        if isTwoPlayer {
            if case .win = viewModel.outcome { return viewModel.statusText.uppercased() }
            return "DRAW"
        }
        switch viewModel.outcome {
        case .win(.X): return "VICTORY!"
        case .win: return "DEFEAT"
        default: return "DRAW"
        }
    }
    
    private var resultSubtitle: String {
        if isTwoPlayer { return "Great match!" }
        switch viewModel.outcome {
        case .win(.X): return "Nice one, champ."
        case .win: return "So close — one more round?"
        default: return "A solid defence."
        }
    }
    
    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            if isVictory { RaysView() }
            
            ScrollView {
                VStack(spacing: 14) {
                    Text(resultTitle)
                        .font(gameFont(48, weight: .black))
                        .foregroundColor(isVictory ? GamePalette.gold : Color(red: 0.7, green: 0.8, blue: 1.0))
                        .outlined(isVictory ? GamePalette.goldEdge : GamePalette.ink, width: 3)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .pulsing(1.04)
                    
                    Text(resultSubtitle)
                        .font(gameFont(16))
                        .foregroundColor(.white.opacity(0.85))
                    
                    StarRow(count: stars)
                        .padding(.vertical, 4)
                    
                    if let reward {
                        rewardPanel(reward)
                    }
                    
                    resultButtons
                }
                .padding(24)
            }
        }
    }
    
    private func rewardPanel(_ reward: RoundReward) -> some View {
        let coins = rewardDoubled ? reward.coins * ads.rewardMultiplier : reward.coins
        return VStack(spacing: 10) {
            HStack(spacing: 24) {
                HStack(spacing: 6) {
                    CoinIcon(size: 34)
                    Text("+\(coins)")
                        .font(gameFont(28, weight: .black))
                        .foregroundColor(.white)
                        .outlined(GamePalette.ink, width: 1.5)
                }
                HStack(spacing: 6) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(ButtonPalette.blue.top)
                    Text("+\(reward.xp) XP")
                        .font(gameFont(22, weight: .black))
                        .foregroundColor(.white)
                        .outlined(GamePalette.ink, width: 1.5)
                }
            }
            
            if reward.points > 0 {
                Label("+\(reward.points) weekly pts" + (reward.ranksGained > 0 ? "  ·  ▲\(reward.ranksGained) rank" : ""),
                      systemImage: "chart.bar.fill")
                    .font(gameFont(15))
                    .foregroundColor(.white)
            }
            
            if reward.leveledUp {
                Text("LEVEL UP!  LV \(progress.level)")
                    .font(gameFont(20, weight: .black))
                    .foregroundColor(.white)
                    .outlined(ButtonPalette.orange.edge, width: 1.5)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(ButtonPalette.orange.bottom))
                    .pulsing(1.08)
            }
            
            ForEach(reward.newAchievements) { achievement in
                HStack {
                    Image(systemName: achievement.icon).foregroundColor(GamePalette.gold)
                    Text(achievement.title.uppercased()).font(gameFont(14)).foregroundColor(.white)
                    Spacer()
                    Text("+\(achievement.rewardCoins)").font(gameFont(14)).foregroundColor(.white)
                    CoinIcon(size: 18)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.12)))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .gamePanel()
    }
    
    private var resultButtons: some View {
        VStack(spacing: 12) {
            if let reward, reward.coins > 0, !rewardDoubled {
                Button {
                    ads.showRewarded(adsRemoved: progress.adsRemoved) { earned in
                        if earned {
                            progress.add(coins: reward.coins * (ads.rewardMultiplier - 1)) // base was already paid
                            rewardDoubled = true
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "play.rectangle.fill")
                        Text("COLLECT ×\(ads.rewardMultiplier)")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(palette: .orange, cornerRadius: 22))
                .pulsing(1.03)
            }
            
            Button { playAgain() } label: {
                Text("PLAY AGAIN")
                    .font(gameFont(26, weight: .black))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ChunkyButtonStyle(palette: .green, cornerRadius: 24, depth: 8))
            
            Button { dismiss() } label: {
                Text("MENU").frame(maxWidth: .infinity)
            }
            .buttonStyle(ChunkyButtonStyle(palette: .blue, cornerRadius: 18, depth: 5))
        }
    }
    
    // MARK: Actions
    private func finish(with outcome: GameOutcome) {
        let result: RoundResult
        switch outcome {
        case .draw: result = .draw
        case .win(let piece): result = piece == .X || isTwoPlayer ? .win : .loss
        }
        
        reward = progress.recordRound(result, difficulty: viewModel.mode.difficulty, ultimate: isUltimate)
        rewardDoubled = false
        ads.registerFinishedGame()
        
        if result == .loss { Haptics.failure() } else { Haptics.success() }
        
        // Let the player see the winning line before the overlay appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) { showResult = true }
        }
    }
    
    private func playAgain() {
        ads.showInterstitialIfDue(adsRemoved: progress.adsRemoved, totalGames: progress.gamesPlayed) {
            withAnimation { showResult = false }
            reward = nil
            viewModel.resetGame()
        }
    }
    
    private func use(_ perk: Perk) {
        let cost = perk == .hint ? hintCost : undoCost
        if progress.spend(cost) {
            perform(perk)
        } else {
            pendingPerk = perk
        }
    }
    
    private func watchAd(for perk: Perk) {
        ads.showRewarded(adsRemoved: progress.adsRemoved) { earned in
            if earned { perform(perk) }
        }
    }
    
    private func perform(_ perk: Perk) {
        switch perk {
        case .hint: viewModel.showHint()
        case .undo: viewModel.undo()
        }
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            GameView(mode: .computer(difficulty: 0))
                .environmentObject(ProgressStore())
                .environmentObject(AdManager())
        }
    }
}
