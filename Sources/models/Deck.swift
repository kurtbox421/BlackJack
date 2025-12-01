//
//  Deck.swift
//  BlackJack
//
//  Created by Curtis Bollinger on 11/30/25.
//

import Foundation

struct Deck {
    private(set) var cards: [Card]
    private(set) var numberOfDecks: Int

    var totalCards: Int { numberOfDecks * 52 }
    var remainingCards: Int { cards.count }

    init(numberOfDecks: Int = 1, shuffled: Bool = true) {
        self.numberOfDecks = max(1, numberOfDecks)
        self.cards = Deck.fullDeck(numberOfDecks: self.numberOfDecks)
        if shuffled {
            cards.shuffle()
        }
    }

    mutating func drawCard() -> Card? {
        // Do not auto-reshuffle here; the view model manages shoe penetration.
        return cards.popLast()
    }

    mutating func reshuffle(shuffled: Bool = true) {
        cards = Deck.fullDeck(numberOfDecks: numberOfDecks)
        if shuffled {
            cards.shuffle()
        }
    }

    private static func fullDeck(numberOfDecks: Int) -> [Card] {
        var newDeck: [Card] = []
        for _ in 0..<max(1, numberOfDecks) {
            for suit in Suit.allCases {
                for rank in Rank.allCases {
                    newDeck.append(Card(suit: suit, rank: rank))
                }
            }
        }
        return newDeck
    }
}
