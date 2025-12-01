//
//  Gamestate.swift
//  BlackJack
//
//  Created by Curtis Bollinger on 11/30/25.
//

import Foundation

enum GamePhase {
    case betting
    case playerTurn
    case dealerTurn
    case roundOver
}

enum RoundResult {
    case win
    case lose
    case push
    case blackjack
    case surrender
}
