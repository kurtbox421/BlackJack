//
//  BlackjackGameViewModel.swift
//  BlackJack
//
//  Created by Curtis Bollinger on 11/30/25.
//

import Foundation

@MainActor
final class BlackjackGameViewModel: ObservableObject {
    // MARK: - Published game state

    @Published private(set) var playerHand: Hand = Hand()
    @Published private(set) var dealerHand: Hand = Hand()
    @Published var bet: Int = 10
    @Published var bankroll: Int {
        didSet { persistIfNeeded() }
    }
    @Published private(set) var phase: GamePhase = .betting
    @Published private(set) var roundResult: RoundResult?

    // MARK: - Published stats

    @Published var totalHands: Int {
        didSet { persistIfNeeded() }
    }
    @Published var wins: Int {
        didSet { persistIfNeeded() }
    }
    @Published var losses: Int {
        didSet { persistIfNeeded() }
    }
    @Published var pushes: Int {
        didSet { persistIfNeeded() }
    }
    @Published var blackjacks: Int {
        didSet { persistIfNeeded() }
    }

    // MARK: - Private properties

    private let defaultBankroll = 1000
    private let defaultBet = 10
    private var deck = Deck()
    private let userDefaults: UserDefaults
    private var isRestoringState = false

    // MARK: - Lifecycle

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        isRestoringState = true
        let saved = Self.loadPersistedState(from: userDefaults, defaultBankroll: defaultBankroll)
        bankroll = saved.bankroll
        totalHands = saved.totalHands
        wins = saved.wins
        losses = saved.losses
        pushes = saved.pushes
        blackjacks = saved.blackjacks
        bet = max(defaultBet, min(bankroll, bet))
        isRestoringState = false
    }

    // MARK: - Computed properties

    var dealerTotalDescription: String {
        "Total: \(dealerHand.total)"
    }

    var playerTotalDescription: String {
        "Total: \(playerHand.total)"
    }

    var resultText: String? {
        guard let roundResult else { return nil }
        switch roundResult {
        case .win:
            return "You win!"
        case .lose:
            return "You lose."
        case .push:
            return "Push."
        case .blackjack:
            return "Blackjack!"
        }
    }

    var canDeal: Bool {
        phase == .betting && bet > 0 && bet <= bankroll
    }

    var canDoubleDown: Bool {
        phase == .playerTurn && playerHand.cards.count == 2 && bet * 2 <= bankroll
    }

    // MARK: - Betting controls

    func adjustBet(by amount: Int) {
        guard phase == .betting else { return }
        bet = max(0, min(bankroll, bet + amount))
    }

    func clearBet() {
        guard phase == .betting else { return }
        bet = 0
    }

    func setMinimumBet() {
        guard phase == .betting else { return }
        bet = min(defaultBet, bankroll)
    }

    // MARK: - Game flow

    func deal() {
        guard canDeal else { return }
        roundResult = nil
        deck = Deck()
        playerHand = Hand()
        dealerHand = Hand()
        phase = .playerTurn

        dealInitialCards()
        evaluateForBlackjackIfNeeded()
    }

    func hit() {
        guard phase == .playerTurn, let card = deck.drawCard() else { return }
        playerHand.addCard(card)

        if playerHand.isBust {
            settleRound(with: .lose)
        }
    }

    func stand() {
        guard phase == .playerTurn else { return }
        phase = .dealerTurn
        playDealerHand()
    }

    func doubleDown() {
        guard canDoubleDown else { return }
        bet *= 2
        if let card = deck.drawCard() {
            playerHand.addCard(card)
        }

        if playerHand.isBust {
            settleRound(with: .lose)
        } else {
            stand()
        }
    }

    func nextHand() {
        roundResult = nil
        playerHand = Hand()
        dealerHand = Hand()
        phase = .betting
        bet = min(max(defaultBet, bet), bankroll)
    }

    func resetBankrollAndStats() {
        bankroll = defaultBankroll
        totalHands = 0
        wins = 0
        losses = 0
        pushes = 0
        blackjacks = 0
        bet = min(defaultBet, bankroll)
        playerHand = Hand()
        dealerHand = Hand()
        roundResult = nil
        phase = .betting
    }

    // MARK: - Private helpers

    private func dealInitialCards() {
        if let card1 = deck.drawCard() { playerHand.addCard(card1) }
        if let card2 = deck.drawCard() { dealerHand.addCard(card2) }
        if let card3 = deck.drawCard() { playerHand.addCard(card3) }
        if let card4 = deck.drawCard() { dealerHand.addCard(card4) }
    }

    private func evaluateForBlackjackIfNeeded() {
        if playerHand.isBlackjack {
            if dealerHand.isBlackjack {
                settleRound(with: .push)
            } else {
                settleRound(with: .blackjack)
            }
        } else if dealerHand.isBlackjack {
            settleRound(with: .lose)
        }
    }

    private func playDealerHand() {
        while dealerHand.total < 17 {
            if let card = deck.drawCard() {
                dealerHand.addCard(card)
            }
        }
        concludeRound()
    }

    private func concludeRound() {
        if playerHand.isBust {
            settleRound(with: .lose)
            return
        }

        if dealerHand.isBust {
            settleRound(with: .win)
            return
        }

        if playerHand.total > dealerHand.total {
            settleRound(with: .win)
        } else if playerHand.total < dealerHand.total {
            settleRound(with: .lose)
        } else {
            settleRound(with: .push)
        }
    }

    private func settleRound(with result: RoundResult) {
        roundResult = result
        applyBankrollChange(for: result)
        updateStats(for: result)
        phase = .roundOver
    }

    private func applyBankrollChange(for result: RoundResult) {
        // Bets are not removed from the bankroll up front. Instead we adjust the bankroll
        // here once the result is known, mirroring the net change a casino payout would create.
        switch result {
        case .win:
            bankroll += bet
        case .lose:
            bankroll = max(0, bankroll - bet)
        case .push:
            break
        case .blackjack:
            bankroll += Int(Double(bet) * 1.5)
        }
    }

    private func updateStats(for result: RoundResult) {
        totalHands += 1
        switch result {
        case .win:
            wins += 1
        case .lose:
            losses += 1
        case .push:
            pushes += 1
        case .blackjack:
            blackjacks += 1
            wins += 1
        }
    }

    // MARK: - Persistence

    private func persistIfNeeded() {
        guard !isRestoringState else { return }
        // Keep bankroll and stats in sync with UserDefaults so progress survives relaunches.
        let payload = PersistedState(
            bankroll: bankroll,
            totalHands: totalHands,
            wins: wins,
            losses: losses,
            pushes: pushes,
            blackjacks: blackjacks
        )
        save(state: payload)
    }

    private func save(state: PersistedState) {
        userDefaults.set(state.bankroll, forKey: UserDefaultKeys.bankroll)
        userDefaults.set(state.totalHands, forKey: UserDefaultKeys.totalHands)
        userDefaults.set(state.wins, forKey: UserDefaultKeys.wins)
        userDefaults.set(state.losses, forKey: UserDefaultKeys.losses)
        userDefaults.set(state.pushes, forKey: UserDefaultKeys.pushes)
        userDefaults.set(state.blackjacks, forKey: UserDefaultKeys.blackjacks)
    }

    private static func loadPersistedState(from defaults: UserDefaults, defaultBankroll: Int) -> PersistedState {
        var isRestoring = PersistedState(
            bankroll: defaultBankroll,
            totalHands: 0,
            wins: 0,
            losses: 0,
            pushes: 0,
            blackjacks: 0
        )

        if defaults.object(forKey: UserDefaultKeys.bankroll) != nil {
            isRestoring.bankroll = defaults.integer(forKey: UserDefaultKeys.bankroll)
        }
        if defaults.object(forKey: UserDefaultKeys.totalHands) != nil {
            isRestoring.totalHands = defaults.integer(forKey: UserDefaultKeys.totalHands)
        }
        if defaults.object(forKey: UserDefaultKeys.wins) != nil {
            isRestoring.wins = defaults.integer(forKey: UserDefaultKeys.wins)
        }
        if defaults.object(forKey: UserDefaultKeys.losses) != nil {
            isRestoring.losses = defaults.integer(forKey: UserDefaultKeys.losses)
        }
        if defaults.object(forKey: UserDefaultKeys.pushes) != nil {
            isRestoring.pushes = defaults.integer(forKey: UserDefaultKeys.pushes)
        }
        if defaults.object(forKey: UserDefaultKeys.blackjacks) != nil {
            isRestoring.blackjacks = defaults.integer(forKey: UserDefaultKeys.blackjacks)
        }

        return isRestoring
    }

    private struct PersistedState {
        var bankroll: Int
        var totalHands: Int
        var wins: Int
        var losses: Int
        var pushes: Int
        var blackjacks: Int
    }

    private enum UserDefaultKeys {
        static let bankroll = "Blackjack.bankroll"
        static let totalHands = "Blackjack.totalHands"
        static let wins = "Blackjack.wins"
        static let losses = "Blackjack.losses"
        static let pushes = "Blackjack.pushes"
        static let blackjacks = "Blackjack.blackjacks"
    }
}
