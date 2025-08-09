//
//  Account.swift
//  PlainTextMoney
//
//  Created by Stephen Dawes on 29/07/2025.
//

import SwiftData
import Foundation

@Model
class Account {
    // PERFORMANCE: SwiftData indexes for fast account queries
    // These indexes dramatically speed up account filtering and lookup operations
    #Index<Account>([\.isActive], [\.name])
    
    var name: String
    var createdAt: Date
    var isActive: Bool
    var closedAt: Date?
    
    @Relationship(deleteRule: .cascade) 
    var updates: [AccountUpdate] = []
    
    init(name: String) {
        self.name = name
        self.createdAt = Date()
        self.isActive = true
        self.closedAt = nil
    }
}