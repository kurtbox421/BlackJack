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
        ZStack {
            TableBackground()

            VStack(spacing: 24) {
                header
                dealerSection
                playerSection
                resultSection
                controlArea
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Bankroll")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Text("$\(viewModel.bankroll)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Current Bet: $\(viewModel.bet)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text("Blackjack")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Vegas Table")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 8)
        )
    }

    private var dealerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Dealer")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(viewModel.dealerHand.cards.enumerated()), id: \.offset) { index, card in
                        CardView(card: card, isFaceDown: shouldHideDealerCard(at: index))
                    }
                }
                .padding(.vertical, 4)
            }

            if viewModel.phase != .betting && !showingDealerFaceDown {
                Text("Total: \(viewModel.dealerHand.total)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
            } else if showingDealerFaceDown {
                Text("Total hidden until you stand")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.yellow.opacity(0.9))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tableCardContainer())
    }

    private var playerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Player")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.playerHand.cards) { card in
                        CardView(card: card)
                    }
                }
                .padding(.vertical, 4)
            }

            if viewModel.phase != .betting {
                Text("Total: \(viewModel.playerHand.total)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tableCardContainer())
    }

    private var resultSection: some View {
        Group {
            if let result = viewModel.roundResult {
                let text = viewModel.resultText ?? ""
                Text(text)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(resultColor(for: result))
                    .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private var controlArea: some View {
        switch viewModel.phase {
        case .betting:
            bettingControls
        case .playerTurn:
            playerControls
        case .dealerTurn:
            dealerProcessing
        case .roundOver:
            roundOverControls
        }
    }

    private var bettingControls: some View {
        VStack(spacing: 18) {
            Text("Place your bet")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            HStack(spacing: 16) {
                ChipButton(amount: 5, label: "+5") { viewModel.placeBet(5) }
                ChipButton(amount: 25, label: "+25") { viewModel.placeBet(25) }
                ChipButton(amount: 100, label: "+100") { viewModel.placeBet(100) }
                ChipButton(amount: 0, label: "Clear") { viewModel.clearBet() }
            }

            Button(action: viewModel.deal) {
                Text("Deal Cards")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.4, green: 0.75, blue: 0.3), Color(red: 0.23, green: 0.5, blue: 0.18)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(!viewModel.canDeal)
            .opacity(viewModel.canDeal ? 1 : 0.5)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(tableCardContainer())
    }

    private var playerControls: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                actionButton(title: "Hit", colors: [Color.blue.opacity(0.8), Color.blue]) {
                    viewModel.hit()
                }
                actionButton(title: "Stand", colors: [Color.gray.opacity(0.8), Color.gray]) {
                    viewModel.stand()
                }
                actionButton(title: "Double", colors: [Color.orange.opacity(0.85), Color.orange]) {
                    viewModel.doubleDown()
                }
                .opacity(viewModel.canDoubleDown ? 1 : 0.4)
                .disabled(!viewModel.canDoubleDown)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(tableCardContainer())
    }

    private var dealerProcessing: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(.yellow)
            Text("Dealer is drawing…")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(tableCardContainer())
    }

    private var roundOverControls: some View {
        VStack(spacing: 16) {
            Text("Round complete")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
            Button(action: viewModel.nextRound) {
                Text("Next Round")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.42, green: 0.72, blue: 0.28), Color(red: 0.24, green: 0.5, blue: 0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(tableCardContainer())
    }

    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
            Capsule()
                .fill(Color.white.opacity(0.12))
                .frame(width: 60, height: 4)
        }
    }

    private func tableCardContainer() -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 8)
    }

    private func shouldHideDealerCard(at index: Int) -> Bool {
        showingDealerFaceDown && index == 0
    }

    private var showingDealerFaceDown: Bool {
        viewModel.phase == .playerTurn && viewModel.dealerHand.cards.count > 0
    }

    private func resultColor(for result: RoundResult) -> Color {
        switch result {
        case .win, .blackjack:
            return Color.green
        case .push:
            return Color.yellow
        case .lose:
            return Color.red
        }
    }

    private func actionButton(title: String, colors: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

#Preview {
    BlackjackGameView()
        .environmentObject(BlackjackGameViewModel())
}
