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
    var value: Decimal
    var date: Date
    var account: Account?
    
    init(value: Decimal, account: Account) {
        self.value = value
        self.date = Date()
        self.account = account
    }
}