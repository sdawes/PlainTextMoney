//
//  AccountUpdate.swift
//  PlainTextMoney
//
//  Created by Stephen Dawes on 29/07/2025.
//

import SwiftData
import Foundation

@Model
class AccountUpdate {
    // PERFORMANCE: SwiftData indexes for fast date-based queries
    // These indexes dramatically speed up time-period filtering operations (10-100x faster)
    #Index<AccountUpdate>([\.date], [\.account, \.date])
    
    var value: Decimal
    var date: Date
    var account: Account?
    
    init(value: Decimal, account: Account) {
        self.value = value
        self.date = Date()
        self.account = account
    }
}