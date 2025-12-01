//
//  Card.swift
//  BlackJack
//
//  Created by Curtis Bollinger on 11/30/25.
//

import Foundation

enum Suit: String, CaseIterable {
    case hearts = "♥︎"
    case diamonds = "♦︎"
    case clubs = "♣︎"
    case spades = "♠︎"

    var color: String {
        switch self {
        case .hearts, .diamonds:
            return "red"
        default:
            return "black"
        }
    }
}

enum Rank: Int, CaseIterable, Comparable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack = 11, queen, king, ace

    var label: String {
        switch self {
        case .jack:
            return "J"
        case .queen:
            return "Q"
        case .king:
            return "K"
        case .ace:
            return "A"
        default:
            return String(rawValue)
        }
    }

    var value: Int {
        switch self {
        case .ace:
            return 11
        case .king, .queen, .jack:
            return 10
        default:
            return rawValue
        }
    }

    static func < (lhs: Rank, rhs: Rank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct Card: Identifiable {
    let id = UUID()
    let suit: Suit
    let rank: Rank

    var displayName: String {
        "\(rank.label)\(suit.rawValue)"
    }
}
