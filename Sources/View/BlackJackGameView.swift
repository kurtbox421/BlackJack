//
//  BlackJackGameView.swift
//  BlackJack
//
//  Created by Curtis Bollinger on 11/30/25.
//

import SwiftUI

struct BlackjackGameView: View {
    @EnvironmentObject var viewModel: BlackjackGameViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                bankrollHeader
                dealerSection
                playerSection
                actionSection
            }
            .padding()
        }
        .navigationTitle("Blackjack")
    }

    private var bankrollHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bankroll")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("$\(viewModel.bankroll)")
                    .font(.largeTitle.weight(.bold))
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    private var dealerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dealer")
                .font(.headline)
            cardRow(for: viewModel.dealerHand.cards)
            if viewModel.phase != .betting {
                Text(viewModel.dealerTotalDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var playerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Player")
                .font(.headline)
            cardRow(for: viewModel.playerHand.cards)
            if viewModel.phase != .betting {
                Text(viewModel.playerTotalDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var actionSection: some View {
        switch viewModel.phase {
        case .betting:
            bettingControls
        case .playerTurn:
            playerControls
        case .dealerTurn:
            dealerPlaying
        case .roundOver:
            roundResultView
        }
    }

    private var bettingControls: some View {
        VStack(spacing: 12) {
            Text("Current Bet: $\(viewModel.bet)")
                .font(.headline)

            HStack(spacing: 12) {
                chipButton(amount: 5)
                chipButton(amount: 25)
                chipButton(amount: 100)
                Button("Min") { viewModel.setMinimumBet() }
                    .buttonStyle(.bordered)
                Button("Clear") { viewModel.clearBet() }
                    .buttonStyle(.bordered)
            }

            Stepper("Adjust Bet", value: $viewModel.bet, in: 0...viewModel.bankroll)
                .disabled(viewModel.bankroll == 0 || viewModel.phase != .betting)

            Button(action: viewModel.deal) {
                Text("Deal")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canDeal)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    private func chipButton(amount: Int) -> some View {
        Button(action: { viewModel.adjustBet(by: amount) }) {
            VStack {
                Text("+$\(amount)")
                    .font(.body.weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color(.systemGray5)))
        }
        .disabled(viewModel.bet >= viewModel.bankroll)
    }

    private var playerControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button("Hit", action: viewModel.hit)
                    .buttonStyle(.borderedProminent)
                Button("Stand", action: viewModel.stand)
                    .buttonStyle(.bordered)
                Button("Double", action: viewModel.doubleDown)
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.canDoubleDown)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    private var dealerPlaying: some View {
        VStack(spacing: 8) {
            ProgressView("Dealer is playing…")
                .progressViewStyle(.linear)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    private var roundResultView: some View {
        VStack(spacing: 12) {
            if let text = viewModel.resultText {
                Text(text)
                    .font(.title2.weight(.semibold))
            }

            Button(action: viewModel.nextHand) {
                Text("Next Hand")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    private func cardRow(for cards: [Card]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(cards) { card in
                    cardView(card)
                }
            }
        }
    }

    private func cardView(_ card: Card) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray6))
            .frame(width: 60, height: 90)
            .overlay(
                Text(card.displayName)
                    .font(.headline)
                    .foregroundStyle(card.suit.color == "red" ? .red : .primary)
            )
            .shadow(radius: 1)
    }
}

#Preview {
    BlackjackGameView()
        .environmentObject(BlackjackGameViewModel())
}
