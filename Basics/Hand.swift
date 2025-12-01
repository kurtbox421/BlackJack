//
//  Hand.swift
//  BlackJack
//
//  Created by Curtis Bollinger on 11/30/25.
//
// Hand.swift
import Foundation

struct Hand {
    var cards: [Card] = []
    
    var values: (total: Int, isSoft: Bool) {
        var total = 0
        var aces = 0
        
        for card in cards {
            if card.rank == .ace {
                aces += 1
            }
            total += card.rank.value
        }
        
        // Downgrade aces from 11 to 1 as needed
        while total > 21 && aces > 0 {
            total -= 10
            aces -= 1
        }
        
        return (total, aces > 0)
    }
    
    var total: Int { values.total }
    var isBust: Bool { total > 21 }
    var isBlackjack: Bool { cards.count == 2 && total == 21 }
}
