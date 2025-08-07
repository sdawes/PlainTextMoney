//
//  PerformanceCalculationService.swift
//  PlainTextMoney
//
//  Created by Claude on 07/08/2025.
//

import Foundation

struct PerformanceCalculationService {
    
    enum TimePeriod: CaseIterable, Identifiable {
        case lastUpdate
        case oneMonth
        case oneYear
        case allTime
        
        var id: Self { self }
        
        var displayName: String {
            switch self {
            case .lastUpdate: return "Last Update"
            case .oneMonth: return "1 Month"
            case .oneYear: return "1 Year"
            case .allTime: return "All Time"
            }
        }
    }
    
    // MARK: - Account Performance Calculations
    
    /// Calculate account performance since the last update (previous update vs current value)
    static func calculateAccountChangeFromLastUpdate(account: Account) -> (percentage: Double, absolute: Decimal, isPositive: Bool, hasData: Bool) {
        let sortedUpdates = account.updates.sorted { $0.date < $1.date }
        
        // Need at least 2 updates to show change from last update
        guard sortedUpdates.count >= 2 else {
            return (0.0, 0, true, false)
        }
        
        let currentUpdate = sortedUpdates.last!  // Most recent
        let previousUpdate = sortedUpdates[sortedUpdates.count - 2]  // Second to last
        
        let absoluteChange = currentUpdate.value - previousUpdate.value
        let isPositive = absoluteChange >= 0
        
        // Calculate percentage change
        let percentage: Double
        if previousUpdate.value > 0 {
            let change = (absoluteChange / previousUpdate.value) * 100
            percentage = Double(truncating: change as NSNumber)
        } else {
            // Handle edge case where previous value was 0
            percentage = 0.0
        }
        
        return (percentage, absoluteChange, isPositive, true)
    }
    
    /// Calculate account performance since the very first update (all-time change)
    static func calculateAccountChangeAllTime(account: Account) -> (percentage: Double, absolute: Decimal, isPositive: Bool, hasData: Bool) {
        let sortedUpdates = account.updates.sorted { $0.date < $1.date }
        
        guard let firstUpdate = sortedUpdates.first,
              let lastUpdate = sortedUpdates.last,
              firstUpdate != lastUpdate,
              firstUpdate.value > 0 else {
            return (0.0, 0, true, false)
        }
        
        let absoluteChange = lastUpdate.value - firstUpdate.value
        let isPositive = absoluteChange >= 0
        
        // Calculate percentage change
        let change = (absoluteChange / firstUpdate.value) * 100
        let percentage = Double(truncating: change as NSNumber)
        
        return (percentage, absoluteChange, isPositive, true)
    }
    
    /// Calculate account performance over the last month (~30 days)
    static func calculateAccountChangeOneMonth(account: Account) -> (percentage: Double, absolute: Decimal, isPositive: Bool, hasData: Bool) {
        let sortedUpdates = account.updates.sorted { $0.date < $1.date }
        
        guard let currentUpdate = sortedUpdates.last else {
            return (0.0, 0, true, false) // No updates at all
        }
        
        let calendar = Calendar.current
        let oneMonthAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        // Find the most recent update that is >= 30 days old (baseline)
        let eligibleUpdates = sortedUpdates.filter { $0.date <= oneMonthAgo }
        
        let baselineUpdate: AccountUpdate
        if let latestEligibleUpdate = eligibleUpdates.last {
            // Found an update from 30+ days ago
            baselineUpdate = latestEligibleUpdate
        } else {
            // No updates older than 30 days - use the first update (account is newer than 30 days)
            guard let firstUpdate = sortedUpdates.first else {
                return (0.0, 0, true, false)
            }
            baselineUpdate = firstUpdate
        }
        
        // Calculate change
        let absoluteChange = currentUpdate.value - baselineUpdate.value
        let isPositive = absoluteChange >= 0
        
        // Calculate percentage change
        let percentage: Double
        if baselineUpdate.value > 0 {
            let change = (absoluteChange / baselineUpdate.value) * 100
            percentage = Double(truncating: change as NSNumber)
        } else {
            // Handle edge case where baseline value was 0
            percentage = 0.0
        }
        
        return (percentage, absoluteChange, isPositive, true)
    }
    
    /// Calculate account performance over the last year (~365 days)
    static func calculateAccountChangeOneYear(account: Account) -> (percentage: Double, absolute: Decimal, isPositive: Bool, hasData: Bool) {
        let sortedUpdates = account.updates.sorted { $0.date < $1.date }
        
        guard let currentUpdate = sortedUpdates.last else {
            return (0.0, 0, true, false) // No updates at all
        }
        
        let calendar = Calendar.current
        let oneYearAgo = calendar.date(byAdding: .day, value: -365, to: Date()) ?? Date()
        
        // Find the most recent update that is >= 365 days old (baseline)
        let eligibleUpdates = sortedUpdates.filter { $0.date <= oneYearAgo }
        
        let baselineUpdate: AccountUpdate
        if let latestEligibleUpdate = eligibleUpdates.last {
            // Found an update from 365+ days ago
            baselineUpdate = latestEligibleUpdate
        } else {
            // No updates older than 365 days - use the first update (account is newer than 1 year)
            guard let firstUpdate = sortedUpdates.first else {
                return (0.0, 0, true, false)
            }
            baselineUpdate = firstUpdate
        }
        
        // Calculate change
        let absoluteChange = currentUpdate.value - baselineUpdate.value
        let isPositive = absoluteChange >= 0
        
        // Calculate percentage change
        let percentage: Double
        if baselineUpdate.value > 0 {
            let change = (absoluteChange / baselineUpdate.value) * 100
            percentage = Double(truncating: change as NSNumber)
        } else {
            // Handle edge case where baseline value was 0
            percentage = 0.0
        }
        
        return (percentage, absoluteChange, isPositive, true)
    }
}