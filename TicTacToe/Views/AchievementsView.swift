//
//  AchievementsView.swift
//  TicTacToe
//

import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AnimatedBackdrop()
            
            VStack(spacing: 0) {
                HStack {
                    Text("PROGRESS")
                        .font(gameFont(34, weight: .black))
                        .foregroundColor(GamePalette.gold)
                        .outlined(GamePalette.goldEdge, width: 2.5)
                    Spacer()
                    CloseButton { dismiss() }
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 14) {
                        HStack(spacing: 10) {
                            statTile("GAMES", progress.gamesPlayed, "gamecontroller.fill")
                            statTile("WINS", progress.data.wins, "crown.fill")
                            statTile("BEST STREAK", progress.data.bestWinStreak, "flame.fill")
                        }
                        
                        RibbonTitle(text: "ACHIEVEMENTS")
                        
                        ForEach(Achievement.allCases) { achievement in
                            achievementRow(achievement)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
    }
    
    private func statTile(_ title: String, _ value: Int, _ icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .black))
                .foregroundColor(GamePalette.gold)
            Text("\(value)")
                .font(gameFont(28, weight: .black))
                .foregroundColor(.white)
                .outlined(GamePalette.ink, width: 1.5)
            Text(title)
                .font(gameFont(10))
                .foregroundColor(.white.opacity(0.75))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .gamePanel(cornerRadius: 20)
    }
    
    private func achievementRow(_ achievement: Achievement) -> some View {
        let earned = progress.data.achievements.contains(achievement)
        
        return HStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Circle().fill(earned
                                          ? LinearGradient(colors: [ButtonPalette.gold.top, ButtonPalette.gold.bottom],
                                                           startPoint: .top, endPoint: .bottom)
                                          : LinearGradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                                                           startPoint: .top, endPoint: .bottom)))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title.uppercased())
                    .font(gameFont(16, weight: .black))
                    .foregroundColor(.white)
                Text(achievement.detail)
                    .font(gameFont(12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            if earned {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(ButtonPalette.green.top)
            } else {
                HStack(spacing: 4) {
                    Text("+\(achievement.rewardCoins)").font(gameFont(15)).foregroundColor(.white)
                    CoinIcon(size: 22)
                }
            }
        }
        .padding(12)
        .gamePanel(cornerRadius: 20, fill: earned ? GamePalette.panelLight : GamePalette.panel)
        .opacity(earned ? 1 : 0.85)
    }
}
