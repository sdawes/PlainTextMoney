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
    var name: String
    var createdAt: Date
    var isActive: Bool
    var closedAt: Date?
    
    @Relationship(deleteRule: .cascade) 
    var updates: [AccountUpdate] = []
    
    @Relationship(deleteRule: .cascade)
    var snapshots: [AccountSnapshot] = []
    
    init(name: String) {
        self.name = name
        self.createdAt = Date()
        self.isActive = true
        self.closedAt = nil
    }
}