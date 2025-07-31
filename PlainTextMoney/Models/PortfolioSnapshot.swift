//
//  PortfolioSnapshot.swift
//  PlainTextMoney
//
//  Created by Stephen Dawes on 31/07/2025.
//

import SwiftData
import Foundation

@Model
class PortfolioSnapshot {
    var date: Date
    var totalValue: Decimal
    
    init(date: Date, totalValue: Decimal) {
        self.date = Calendar.current.startOfDay(for: date)
        self.totalValue = totalValue
    }
}