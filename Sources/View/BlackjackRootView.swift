//
//  BlackjackRootView.swift
//  BlackJack
//
//  Created by Curtis Bollinger on 11/30/25.
//

import SwiftUI

struct BlackjackRootView: View {
    @StateObject private var viewModel = BlackjackGameViewModel()

    var body: some View {
        TabView {
            NavigationStack {
                BlackjackGameView()
                    .environmentObject(viewModel)
            }
            .tabItem {
                Label("Table", systemImage: "suit.club.fill")
            }

            NavigationStack {
                StatsView(viewModel: viewModel)
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar.fill")
            }

            NavigationStack {
                SettingsView(viewModel: viewModel)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
    }
}

#Preview {
    BlackjackRootView()
}
