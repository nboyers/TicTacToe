//
//  AdPlaceholderView.swift
//  TicTacToe
//
//  Stand-in for a real AdMob ad so the full ad flow can be tested.
//  Remove once GoogleMobileAds presents real interstitial/rewarded ads.
//

import SwiftUI

struct AdPlaceholderView: View {
    let kind: AdKind
    let onClose: (_ rewardEarned: Bool) -> Void
    
    @State private var secondsLeft = 5
    
    private var isFinished: Bool { secondsLeft <= 0 }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "megaphone.fill").font(.system(size: 60))
                Text(kind == .rewarded ? "TEST REWARDED AD" : "TEST INTERSTITIAL AD")
                    .font(gameFont(26, weight: .black))
                Text(isFinished ? "Done!" : "Ad ends in \(secondsLeft)…")
                    .font(gameFont(16))
                    .foregroundColor(.gray)
                
                if isFinished {
                    Button(kind == .rewarded ? "CLAIM REWARD" : "CLOSE") { onClose(true) }
                        .buttonStyle(ChunkyButtonStyle(palette: .green))
                } else if kind == .rewarded {
                    Button("Skip (no reward)") { onClose(false) }
                        .buttonStyle(ChunkyButtonStyle(palette: .gray, cornerRadius: 14, depth: 4))
                }
            }
            .foregroundColor(.white)
        }
        .task {
            while secondsLeft > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                secondsLeft -= 1
            }
        }
    }
}
