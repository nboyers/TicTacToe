//
//  LeaderboardView.swift
//  TicTacToe
//

import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var ads: AdManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AnimatedBackdrop()
            
            VStack(spacing: 0) {
                header
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            let entries = progress.leaderboard
                            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                                row(rank: index + 1, entry: entry)
                                    .id(entry.id)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    }
                    .onAppear {
                        proxy.scrollTo("player", anchor: .center)
                    }
                }
                
                footer
            }
        }
        .onAppear { progress.refreshWeek() }
    }
    
    private var header: some View {
        VStack(spacing: 4) {
            HStack {
                Text("LEADERBOARD")
                    .font(gameFont(32, weight: .black))
                    .foregroundColor(GamePalette.gold)
                    .outlined(GamePalette.goldEdge, width: 2.5)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Spacer()
                CloseButton { dismiss() }
            }
            Text("WEEKLY · RESETS MONDAY")
                .font(gameFont(11))
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
    
    private func row(rank: Int, entry: LeaderboardEntry) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(gameFont(18, weight: .black))
                .foregroundColor(rank <= 3 ? GamePalette.gold : .white)
                .frame(width: 34)
            
            Text(String(entry.name.prefix(1)))
                .font(gameFont(18, weight: .black))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(entry.isPlayer ? ButtonPalette.green.bottom : ButtonPalette.blue.bottom))
            
            Text(entry.name.uppercased())
                .font(gameFont(17, weight: .black))
                .foregroundColor(.white)
                        
            Spacer()
            
            Text("\(entry.score)")
                .font(gameFont(18, weight: .black))
                .foregroundColor(entry.isPlayer ? GamePalette.gold : .white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .gamePanel(cornerRadius: 18, fill: entry.isPlayer ? GamePalette.panelLight : GamePalette.panel)
        .overlay(RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(entry.isPlayer ? GamePalette.gold : Color.clear, lineWidth: 3))
    }
    
    private var footer: some View {
        VStack(spacing: 10) {
            if let rival = progress.nextRival {
                Text("\(rival.gap) pts to pass \(rival.entry.name.uppercased())")
                    .font(gameFont(18, weight: .black))
                    .foregroundColor(.white)
                    .outlined(GamePalette.ink, width: 1.5)
            } else {
                Text("YOU'RE #1 THIS WEEK!")
                    .font(gameFont(20, weight: .black))
                    .foregroundColor(GamePalette.gold)
                    .outlined(GamePalette.goldEdge, width: 1.5)
            }
            
            if progress.pointsBoostArmed {
                Label("2× POINTS ON YOUR NEXT WIN", systemImage: "bolt.fill")
                    .font(gameFont(14))
                    .foregroundColor(GamePalette.gold)
            } else {
                Button {
                    ads.showRewarded(adsRemoved: progress.adsRemoved) { earned in
                        if earned { progress.armPointsBoost() }
                    }
                } label: {
                    HStack {
                        Image(systemName: "play.rectangle.fill")
                        Text("2× POINTS NEXT WIN")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ChunkyButtonStyle(palette: .orange, cornerRadius: 18))
                
                Text("Optional: watch an ad to double the points from your next win.")
                    .font(gameFont(11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.3).ignoresSafeArea(edges: .bottom))
    }
}
