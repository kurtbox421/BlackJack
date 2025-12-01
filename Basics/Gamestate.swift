//
//  Gamestate.swift
//  BlackJack
//
//  Created by Curtis Bollinger on 11/30/25.
//
// GameState.swift
import Foundation

enum GamePhase {
    case betting
    case playerTurn
    case dealerTurn
    case roundOver
}

enum RoundResult {
    case win, lose, push, blackjack
}
