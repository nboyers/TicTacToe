//
//  TicTacToeApp.swift
//  TicTacToe
//
//  Created by Noah Boyers on 6/15/21.
//

import SwiftUI

@main
struct TicTacToeApp: App {
    @StateObject private var progress: ProgressStore
    @StateObject private var store: StoreManager
    @StateObject private var ads = AdManager()
    
    init() {
        // The store needs the progress store to deliver purchases
        let progress = ProgressStore()
        _progress = StateObject(wrappedValue: progress)
        _store = StateObject(wrappedValue: StoreManager(progress: progress))
        AppAnalytics.shared.start()
        DiagnosticsCollector.shared.start() // Apple's crash and performance reports
    }
    
    var body: some Scene {
        WindowGroup {
            MainMenuView()
                .environmentObject(progress)
                .environmentObject(store)
                .environmentObject(ads)
                .task { await ads.start() } // consent, tracking prompt, then the ad SDK
        }
    }
}
