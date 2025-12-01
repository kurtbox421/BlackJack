//
//  Deck.swift
//  BlackJack
//
//  Created by Curtis Bollinger on 11/30/25.
//

import Foundation

struct Deck {
    private(set) var cards: [Card] = Deck.fullDeck()

    init(shuffled: Bool = true) {
        if shuffled {
            cards.shuffle()
        }
    }

    mutating func drawCard() -> Card? {
        if cards.isEmpty {
            // Rebuild and reshuffle a fresh deck when we run out of cards.
            cards = Deck.fullDeck()
            cards.shuffle()
        }
        return cards.popLast()
    }

    private static func fullDeck() -> [Card] {
        var newDeck: [Card] = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                newDeck.append(Card(suit: suit, rank: rank))
            }
        }
        return newDeck
    }
}
