//
//  SettingsView.swift
//  BlackJack
//
//  Created by Curtis Bollinger on 11/30/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: BlackjackGameViewModel
    @State private var showingResetAlert = false

    var body: some View {
        List {
            Section {
                Button(role: .destructive) {
                    showingResetAlert = true
                } label: {
                    Text("Reset Bankroll & Stats")
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Reset everything?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                viewModel.resetBankrollAndStats()
            }
        } message: {
            Text("This will restore your bankroll to $1000 and clear all recorded stats.")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(viewModel: BlackjackGameViewModel())
    }
}
