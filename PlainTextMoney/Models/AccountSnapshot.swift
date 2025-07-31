//
//  AccountSnapshot.swift
//  PlainTextMoney
//
//  Created by Stephen Dawes on 30/07/2025.
//

import SwiftData
import Foundation

@Model
class AccountSnapshot {
    var date: Date
    var value: Decimal
    var account: Account?
    
    init(date: Date, value: Decimal, account: Account) {
        self.date = Calendar.current.startOfDay(for: date)
        self.value = value
        self.account = account
    }
}