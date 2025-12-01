//
//  StatsView.swift
//  BlackJack
//
//  Created by Curtis Bollinger on 11/30/25.
//

import SwiftUI

struct StatsView: View {
    @ObservedObject var viewModel: BlackjackGameViewModel

    var body: some View {
        List {
            Section(header: Text("Bankroll")) {
                statRow(title: "Total", value: "$\(viewModel.bankroll)")
            }

            Section(header: Text("Hands")) {
                statRow(title: "Total Hands", value: "\(viewModel.totalHands)")
                statRow(title: "Wins", value: "\(viewModel.wins)")
                statRow(title: "Losses", value: "\(viewModel.losses)")
                statRow(title: "Pushes", value: "\(viewModel.pushes)")
                statRow(title: "Blackjacks", value: "\(viewModel.blackjacks)")
            }
        }
        .navigationTitle("Stats")
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        StatsView(viewModel: BlackjackGameViewModel())
    }
}
