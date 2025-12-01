//
//  BlackjackGameViewModel.swift
//  BlackJack
//
//  Created by Curtis Bollinger on 11/30/25.
//

import Foundation

@MainActor
final class BlackjackGameViewModel: ObservableObject {
    // MARK: - Nested types

    struct ShoeConfig {
        var numberOfDecks: Int
        var penetration: Double
    }

    enum BlackjackRulePreset {
        case vegasStrip
        case european
        case atlanticCity
    }

    // MARK: - Published game state

    @Published private(set) var playerHands: [Hand] = []
    @Published private(set) var activeHandIndex: Int = 0
    @Published private(set) var dealerHand: Hand = Hand()
    @Published var bet: Int = 10
    @Published var bankroll: Int {
        didSet { persistIfNeeded() }
    }
    @Published private(set) var bets: [Int] = []
    @Published private(set) var phase: GamePhase = .betting
    @Published private(set) var roundResult: RoundResult?

    // Insurance
    @Published private(set) var insuranceBet: Int = 0
    @Published private(set) var isInsuranceOffered: Bool = false
    @Published private(set) var hasResolvedInsurance: Bool = false

    // Shoe configuration
    @Published var shoeConfig = ShoeConfig(numberOfDecks: 6, penetration: 0.75) {
        didSet {
            // Rebuild the shoe if configuration changes between rounds.
            if phase == .betting {
                deck = Deck(numberOfDecks: shoeConfig.numberOfDecks)
            }
        }
    }

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

    // MARK: - Rule toggles

    var allowSurrender: Bool = true
    var surrenderIsLate: Bool = true
    var allowResplitAces: Bool = false
    var allowMultipleSplits: Bool = true
    var pairMatchingByValueNotRank: Bool = false
    var maxHands: Int = 4

    // MARK: - Private properties

    private let defaultBankroll = 1000
    private let defaultBet = 10
    private var deck: Deck
    private let userDefaults: UserDefaults
    private var isRestoringState = false
    private var handHasActed: [Bool] = []
    private var handIsFinished: [Bool] = []

    // MARK: - Lifecycle

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.deck = Deck(numberOfDecks: shoeConfig.numberOfDecks)
        isRestoringState = true
        let saved = Self.loadPersistedState(from: userDefaults, defaultBankroll: defaultBankroll)
        bankroll = saved.bankroll
        totalHands = saved.totalHands
        wins = saved.wins
        losses = saved.losses
        pushes = saved.pushes
        blackjacks = saved.blackjacks
        bet = max(defaultBet, min(bankroll, bet))
        applyPreset(.vegasStrip)
        isRestoringState = false
    }

    // MARK: - Computed properties

    var dealerTotalDescription: String {
        "Total: \(dealerHand.total)"
    }

    var playerTotalDescription: String {
        "Total: \(currentHand.total)"
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
        case .surrender:
            return "Surrendered"
        }
    }

    var canDeal: Bool {
        phase == .betting && bet > 0 && bet <= bankroll
    }

    var canDoubleDown: Bool {
        guard phase == .playerTurn, currentHand.cards.count == 2 else { return false }
        guard bets.indices.contains(activeHandIndex) else { return false }
        return bets[activeHandIndex] <= bankroll
    }

    var playerHand: Hand { playerHands.first ?? Hand() }
    var currentHand: Hand {
        guard playerHands.indices.contains(activeHandIndex) else { return Hand() }
        return playerHands[activeHandIndex]
    }

    // MARK: - Betting controls

    func adjustBet(by amount: Int) {
        guard phase == .betting else { return }
        bet = max(0, min(bankroll, bet + amount))
    }

    func placeBet(_ amount: Int) {
        adjustBet(by: amount)
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
        insuranceBet = 0
        isInsuranceOffered = false
        hasResolvedInsurance = false

        prepareShoeIfNeeded()

        playerHands = [Hand()]
        bets = [bet]
        activeHandIndex = 0
        handHasActed = [false]
        handIsFinished = [false]
        dealerHand = Hand()
        phase = .playerTurn

        // Remove the primary stake up front. Future payouts return the stake as needed.
        bankroll -= bet

        dealInitialCards()
        offerInsuranceIfNeeded()
        evaluateForBlackjackIfNeeded()
    }

    func hit() {
        guard phase == .playerTurn, playerHands.indices.contains(activeHandIndex) else { return }
        handHasActed[activeHandIndex] = true
        if let card = drawCardFromShoe() {
            playerHands[activeHandIndex].addCard(card)
        }

        if playerHands[activeHandIndex].isBust || playerHands[activeHandIndex].total == 21 {
            handIsFinished[activeHandIndex] = true
            advanceActiveHandIfNeeded()
        }
    }

    func stand() {
        guard phase == .playerTurn, playerHands.indices.contains(activeHandIndex) else { return }
        handHasActed[activeHandIndex] = true
        handIsFinished[activeHandIndex] = true
        advanceActiveHandIfNeeded()
    }

    func doubleDown() {
        guard canDoubleDown else { return }
        handHasActed[activeHandIndex] = true
        bankroll -= bets[activeHandIndex]
        bets[activeHandIndex] *= 2
        if let card = drawCardFromShoe() {
            playerHands[activeHandIndex].addCard(card)
        }
        handIsFinished[activeHandIndex] = true
        advanceActiveHandIfNeeded()
    }

    func split() {
        guard canSplitCurrentHand else { return }
        let splitBet = bets[activeHandIndex]
        bankroll -= splitBet
        let hand = playerHands[activeHandIndex]
        guard hand.cards.count == 2 else { return }

        var firstHand = Hand(cards: [hand.cards[0]])
        var secondHand = Hand(cards: [hand.cards[1]])

        // Each new hand gets one additional card from the shoe.
        if let firstCard = drawCardFromShoe() { firstHand.addCard(firstCard) }
        if let secondCard = drawCardFromShoe() { secondHand.addCard(secondCard) }

        playerHands[activeHandIndex] = firstHand
        playerHands.insert(secondHand, at: activeHandIndex + 1)
        bets.insert(splitBet, at: activeHandIndex + 1)
        handHasActed[activeHandIndex] = false
        handHasActed.insert(false, at: activeHandIndex + 1)
        handIsFinished[activeHandIndex] = firstHand.isBlackjack || firstHand.total == 21
        handIsFinished.insert(secondHand.isBlackjack || secondHand.total == 21, at: activeHandIndex + 1)
        advanceActiveHandIfNeeded()
    }

    func surrender() {
        guard allowSurrender, phase == .playerTurn else { return }
        if surrenderIsLate && !hasResolvedInsurance {
            return
        }

        // Apply surrender to all active hands to keep accounting simple.
        var results: [RoundResult] = []
        for (index, betAmount) in bets.enumerated() {
            // Stake was already removed; return half to represent a 50% loss.
            bankroll += betAmount / 2
            handIsFinished[index] = true
            results.append(.surrender)
        }
        isInsuranceOffered = false
        hasResolvedInsurance = true
        roundResult = .surrender
        updateStats(for: results)
        phase = .roundOver
    }

    func placeInsurance(amount: Int) {
        guard isInsuranceOffered, !hasResolvedInsurance else { return }
        guard amount > 0, amount <= bet / 2, amount <= bankroll else { return }
        insuranceBet = amount
        bankroll -= amount
    }

    func nextHand() {
        roundResult = nil
        playerHands = []
        bets = []
        handHasActed = []
        handIsFinished = []
        dealerHand = Hand()
        activeHandIndex = 0
        phase = .betting
        bet = min(max(defaultBet, bet), bankroll)
        insuranceBet = 0
        isInsuranceOffered = false
        hasResolvedInsurance = false
    }

    func nextRound() {
        nextHand()
    }

    func resetBankrollAndStats() {
        bankroll = defaultBankroll
        totalHands = 0
        wins = 0
        losses = 0
        pushes = 0
        blackjacks = 0
        bet = min(defaultBet, bankroll)
        nextHand()
    }

    // MARK: - Rules

    var canSplitCurrentHand: Bool {
        guard phase == .playerTurn, playerHands.indices.contains(activeHandIndex) else { return false }
        guard playerHands.count < maxHands else { return false }
        let hand = playerHands[activeHandIndex]
        guard hand.cards.count == 2 else { return false }
        guard bets.indices.contains(activeHandIndex), bets[activeHandIndex] <= bankroll else { return false }
        if !allowMultipleSplits && playerHands.count > 1 { return false }
        if !allowResplitAces, hand.cards.first?.rank == .ace, hand.cards.last?.rank == .ace, playerHands.count > 1 {
            return false
        }
        if handHasActed.indices.contains(activeHandIndex) && handHasActed[activeHandIndex] { return false }

        if pairMatchingByValueNotRank {
            return hand.cards[0].rank.value == hand.cards[1].rank.value
        } else {
            return hand.cards[0].rank == hand.cards[1].rank
        }
    }

    func applyPreset(_ preset: BlackjackRulePreset) {
        switch preset {
        case .vegasStrip:
            // Typical Vegas Strip: 4 decks, late surrender allowed, dealer stands on soft 17 (implicit), resplit up to 4 hands.
            shoeConfig = ShoeConfig(numberOfDecks: 4, penetration: 0.75)
            allowSurrender = true
            surrenderIsLate = true
            allowResplitAces = false
            allowMultipleSplits = true
            pairMatchingByValueNotRank = false
            maxHands = 4
        case .european:
            // European: 2 decks, often no surrender, dealer takes no hole card (not modeled here).
            shoeConfig = ShoeConfig(numberOfDecks: 2, penetration: 0.7)
            allowSurrender = false
            surrenderIsLate = true
            allowResplitAces = false
            allowMultipleSplits = false
            pairMatchingByValueNotRank = false
            maxHands = 3
        case .atlanticCity:
            // Atlantic City: 8 decks, late surrender allowed, dealer stands on soft 17.
            shoeConfig = ShoeConfig(numberOfDecks: 8, penetration: 0.75)
            allowSurrender = true
            surrenderIsLate = true
            allowResplitAces = false
            allowMultipleSplits = true
            pairMatchingByValueNotRank = false
            maxHands = 4
        }
    }

    // MARK: - Private helpers

    private func prepareShoeIfNeeded() {
        // Reshuffle whenever penetration threshold is met or configuration changed.
        if deck.numberOfDecks != shoeConfig.numberOfDecks || shouldReshuffleShoe {
            deck = Deck(numberOfDecks: shoeConfig.numberOfDecks)
        }
    }

    private var shouldReshuffleShoe: Bool {
        // When remaining cards drop below the (1 - penetration) slice, rebuild the shoe.
        let threshold = Int(Double(deck.totalCards) * (1.0 - shoeConfig.penetration))
        return deck.remainingCards <= max(0, threshold)
    }

    private func drawCardFromShoe() -> Card? {
        if deck.remainingCards == 0 || shouldReshuffleShoe {
            deck = Deck(numberOfDecks: shoeConfig.numberOfDecks)
        }
        var card = deck.drawCard()
        if card == nil {
            deck.reshuffle()
            card = deck.drawCard()
        }
        return card
    }

    private func dealInitialCards() {
        if let card1 = drawCardFromShoe() { playerHands[0].addCard(card1) }
        if let card2 = drawCardFromShoe() { dealerHand.addCard(card2) }
        if let card3 = drawCardFromShoe() { playerHands[0].addCard(card3) }
        if let card4 = drawCardFromShoe() { dealerHand.addCard(card4) }

        handIsFinished[0] = playerHands[0].isBlackjack
    }

    private func offerInsuranceIfNeeded() {
        // Insurance is offered when the dealer's upcard is an ace.
        if let upcard = dealerHand.cards.first, upcard.rank == .ace {
            isInsuranceOffered = true
            hasResolvedInsurance = false
        } else {
            isInsuranceOffered = false
            hasResolvedInsurance = true
        }
    }

    private func resolveInsuranceIfNeeded(dealerHasBlackjack: Bool) {
        guard isInsuranceOffered else { return }
        defer {
            isInsuranceOffered = false
            hasResolvedInsurance = true
            insuranceBet = 0
        }
        if dealerHasBlackjack {
            // Insurance pays 2:1; since the stake was already removed, return it alongside the winnings.
            bankroll += insuranceBet * 3
        }
    }

    private func evaluateForBlackjackIfNeeded() {
        let playerBJ = playerHands.first?.isBlackjack ?? false
        let dealerBJ = dealerHand.isBlackjack

        if dealerBJ {
            resolveInsuranceIfNeeded(dealerHasBlackjack: true)
            let result: RoundResult = playerBJ ? .push : .lose
            settleRound(with: [result])
        } else if playerBJ {
            resolveInsuranceIfNeeded(dealerHasBlackjack: false)
            settleRound(with: [.blackjack])
        } else {
            resolveInsuranceIfNeeded(dealerHasBlackjack: false)
        }
    }

    private func advanceActiveHandIfNeeded() {
        while activeHandIndex < playerHands.count,
              handIsFinished.indices.contains(activeHandIndex),
              handIsFinished[activeHandIndex] {
            activeHandIndex += 1
        }
        if activeHandIndex >= playerHands.count {
            phase = .dealerTurn
            playDealerHand()
        }
    }

    private func playDealerHand() {
        // Dealer stands on all 17+ hands; support for soft 17 rules could be added here.
        while dealerHand.total < 17 {
            if let card = drawCardFromShoe() {
                dealerHand.addCard(card)
            } else {
                break
            }
        }
        concludeRound()
    }

    private func concludeRound() {
        let dealerBust = dealerHand.isBust
        let dealerBJ = dealerHand.isBlackjack

        var results: [RoundResult] = []
        for (index, hand) in playerHands.enumerated() {
            if hand.isBust {
                results.append(.lose)
                continue
            }

            if dealerBust {
                results.append(.win)
                continue
            }

            if hand.isBlackjack && hand.cards.count == 2 {
                results.append(dealerBJ ? .push : .blackjack)
                continue
            }

            if dealerBJ {
                results.append(.lose)
                continue
            }

            if hand.total > dealerHand.total {
                results.append(.win)
            } else if hand.total < dealerHand.total {
                results.append(.lose)
            } else {
                results.append(.push)
            }
        }

        settleRound(with: results)
    }

    private func settleRound(with results: [RoundResult]) {
        for (index, result) in results.enumerated() {
            let betAmount = bets[safe: index] ?? bet
            applyBankrollChange(for: result, bet: betAmount)
        }
        updateStats(for: results)
        roundResult = summarize(results: results)
        phase = .roundOver
    }

    private func applyBankrollChange(for result: RoundResult, bet: Int) {
        // Stakes are removed when the bet is placed. Here we pay back the appropriate amount.
        switch result {
        case .win:
            bankroll += bet * 2
        case .lose:
            break
        case .push:
            bankroll += bet
        case .blackjack:
            bankroll += Int(Double(bet) * 2.5)
        case .surrender:
            bankroll += bet / 2
        }
    }

    private func summarize(results: [RoundResult]) -> RoundResult? {
        guard let first = results.first else { return nil }
        if results.allSatisfy({ $0 == first }) {
            return first
        }
        if results.contains(.blackjack) {
            return .blackjack
        }
        if results.contains(.win) && !results.contains(.lose) {
            return .win
        }
        if results.contains(.lose) && !results.contains(.win) {
            return .lose
        }
        if results.contains(.surrender) {
            return .surrender
        }
        return .push
    }

    private func updateStats(for results: [RoundResult]) {
        totalHands += results.count
        for result in results {
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
            case .surrender:
                losses += 1
            }
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

private extension Array {
    subscript(safe index: Index) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
