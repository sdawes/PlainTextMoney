//
//  PortfolioHistory.swift
//  PlainTextMoney
//
//  Created by Stephen Dawes on 09/08/2025.
//

import SwiftData
import Foundation

@Model
class PortfolioHistory {
    // PERFORMANCE: SwiftData indexes for fast history queries
    #Index<PortfolioHistory>([\.date], [\.isValid])
    
    var date: Date
    var totalValue: Decimal
    var accountValues: [String: Decimal]
    var isValid: Bool
    var createdAt: Date
    
    init(date: Date, totalValue: Decimal, accountValues: [String: Decimal]) {
        self.date = date
        self.totalValue = totalValue
        self.accountValues = accountValues
        self.isValid = true
        self.createdAt = Date()
    }
    
    func invalidate() {
        self.isValid = false
    }
    
    func toChartDataPoint() -> ChartDataPoint {
        return ChartDataPoint(date: date, value: totalValue)
    }
}

extension PortfolioHistory {
    static func getLastValidHistory(in context: ModelContext) -> PortfolioHistory? {
        let descriptor = FetchDescriptor<PortfolioHistory>(
            predicate: #Predicate { $0.isValid == true },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let histories = try context.fetch(descriptor)
            return histories.first
        } catch {
            print("Error fetching last valid history: \(error)")
            return nil
        }
    }
    
    static func getHistoryAfter(_ date: Date, in context: ModelContext) -> [PortfolioHistory] {
        let descriptor = FetchDescriptor<PortfolioHistory>(
            predicate: #Predicate { history in
                history.date > date && history.isValid == true
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Error fetching history after date: \(error)")
            return []
        }
    }
    
    static func invalidateHistoryAfter(_ date: Date, in context: ModelContext) {
        let descriptor = FetchDescriptor<PortfolioHistory>(
            predicate: #Predicate { history in
                history.date >= date && history.isValid == true
            }
        )
        
        do {
            let historiesToInvalidate = try context.fetch(descriptor)
            for history in historiesToInvalidate {
                history.invalidate()
            }
            try context.save()
        } catch {
            print("Error invalidating history: \(error)")
        }
    }
}