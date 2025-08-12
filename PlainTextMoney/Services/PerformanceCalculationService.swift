//
//  PerformanceCalculationService.swift
//  PlainTextMoney
//
//  Created by Claude on 07/08/2025.
//

import Foundation
import SwiftData

struct PerformanceCalculationService {
    
    // MARK: - Performance Caching Layer
    
    private struct PortfolioPerformanceCache {
        private static var cache: [String: (Double, Decimal, Bool, Bool, String)] = [:]
        private static var lastAccountHash: Int = 0
        
        static func getOrCalculate(
            accounts: [Account],
            period: TimePeriod,
            calculator: () -> (Double, Decimal, Bool, Bool, String)
        ) -> (Double, Decimal, Bool, Bool, String) {
            // Create hash of account data to detect changes
            let currentHash = accounts.map { account in
                account.updates.map { "\($0.date.timeIntervalSince1970)-\($0.value)" }.joined()
            }.joined().hashValue
            
            let cacheKey = "\(period.rawValue)-\(currentHash)"
            
            // Invalidate cache if accounts changed
            if currentHash != lastAccountHash {
                cache.removeAll()
                lastAccountHash = currentHash
                #if DEBUG
                print("🧹 Portfolio cache invalidated - data changed")
                #endif
            }
            
            // Return cached result if available
            if let cached = cache[cacheKey] {
                #if DEBUG
                print("⚡ Portfolio \(period.displayName) - cached result")
                #endif
                return cached
            }
            
            // Calculate fresh result and cache it
            #if DEBUG
            let startTime = CFAbsoluteTimeGetCurrent()
            #endif
            
            let result = calculator()
            cache[cacheKey] = result
            
            #if DEBUG
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            print("🔄 Portfolio \(period.displayName) - calculated in \(elapsed * 1000)ms")
            #endif
            
            return result
        }
    }
    
    enum TimePeriod: String, CaseIterable, Identifiable {
        case lastUpdate = "lastUpdate"
        case oneMonth = "oneMonth"
        case threeMonths = "threeMonths"
        case oneYear = "oneYear"
        case allTime = "allTime"
        
        var id: Self { self }
        
        var displayName: String {
            switch self {
            case .lastUpdate: return "Latest"
            case .oneMonth: return "1M"
            case .threeMonths: return "3M"
            case .oneYear: return "1Y"
            case .allTime: return "Max"
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
            // Handle edge case where previous value was 0 - can't calculate meaningful percentage
            return (0.0, 0, true, false)
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
    /// Calculate account performance over the last 3 months (~90 days)
    static func calculateAccountChangeThreeMonths(account: Account) -> (percentage: Double, absolute: Decimal, isPositive: Bool, hasData: Bool) {
        let sortedUpdates = account.updates.sorted { $0.date < $1.date }
        
        guard let currentUpdate = sortedUpdates.last else {
            return (0.0, 0, true, false) // No updates at all
        }
        
        let calendar = Calendar.current
        let threeMonthsAgo = calendar.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        
        // Find the most recent update that is >= 90 days old (baseline)
        let eligibleUpdates = sortedUpdates.filter { $0.date <= threeMonthsAgo }
        
        let baselineUpdate: AccountUpdate
        if let latestEligibleUpdate = eligibleUpdates.last {
            // Found an update from 90+ days ago
            baselineUpdate = latestEligibleUpdate
        } else {
            // No updates older than 90 days - use the first update (account is newer than 3 months)
            guard let firstUpdate = sortedUpdates.first else {
                return (0.0, 0, true, false)
            }
            baselineUpdate = firstUpdate
        }
        
        // Calculate the change
        let baselineValue = baselineUpdate.value
        let currentValue = currentUpdate.value
        let absoluteChange = currentValue - baselineValue
        
        // Handle zero baseline (avoid division by zero)
        guard baselineValue != 0 else {
            return (0.0, absoluteChange, absoluteChange >= 0, false) // hasData = false for zero baseline
        }
        
        // Calculate percentage change
        let percentageChange = Double(truncating: NSDecimalNumber(decimal: (absoluteChange / baselineValue) * 100))
        
        return (percentageChange, absoluteChange, absoluteChange >= 0, true)
    }
    
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
    
    // MARK: - Portfolio Performance Calculations
    
    /// Calculate portfolio performance since the last update across all accounts
    static func calculatePortfolioChangeFromLastUpdate(accounts: [Account]) -> (percentage: Double, absolute: Decimal, isPositive: Bool, hasData: Bool, actualPeriodLabel: String) {
        return PortfolioPerformanceCache.getOrCalculate(accounts: accounts, period: .lastUpdate) {
            let activeAccounts = accounts.filter { $0.isActive }
            guard !activeAccounts.isEmpty else { return (0.0, 0, true, false, "") }
            
            // Get all updates across all accounts, sorted chronologically
            let allUpdates = activeAccounts.flatMap { $0.updates }
                .sorted { $0.date < $1.date }
            
            guard allUpdates.count >= 2 else { return (0.0, 0, true, false, "Need more updates") }
            
            // Find the most recent update
            let latestUpdate = allUpdates.last!
            
            // Calculate portfolio value at that point and at the previous significant point
            var accountValues: [String: Decimal] = [:]
            var previousPortfolioValue: Decimal = 0
            var currentPortfolioValue: Decimal = 0
            
            // Replay updates to find portfolio values
            for update in allUpdates {
                accountValues[update.account?.name ?? ""] = update.value
                let portfolioTotal = accountValues.values.reduce(0, +)
                
                if update == latestUpdate {
                    currentPortfolioValue = portfolioTotal
                } else if update == allUpdates[allUpdates.count - 2] {
                    previousPortfolioValue = portfolioTotal
                }
            }
            
            let absoluteChange = currentPortfolioValue - previousPortfolioValue
            let isPositive = absoluteChange >= 0
            
            let percentage: Double
            if previousPortfolioValue > 0 {
                let change = (absoluteChange / previousPortfolioValue) * 100
                percentage = Double(truncating: change as NSNumber)
            } else {
                percentage = 0.0
            }
            
            return (percentage, absoluteChange, isPositive, true, "Since last update")
        }
    }
    
    /// Calculate portfolio performance over the last month
    static func calculatePortfolioChangeOneMonth(accounts: [Account]) -> (percentage: Double, absolute: Decimal, isPositive: Bool, hasData: Bool, actualPeriodLabel: String) {
        return PortfolioPerformanceCache.getOrCalculate(accounts: accounts, period: .oneMonth) {
            return calculatePortfolioChangeForTimeframe(accounts: accounts, daysBack: 30)
        }
    }
    
    /// Calculate portfolio performance over the last year
    static func calculatePortfolioChangeOneYear(accounts: [Account]) -> (percentage: Double, absolute: Decimal, isPositive: Bool, hasData: Bool, actualPeriodLabel: String) {
        return PortfolioPerformanceCache.getOrCalculate(accounts: accounts, period: .oneYear) {
            return calculatePortfolioChangeForTimeframe(accounts: accounts, daysBack: 365)
        }
    }
    
    /// Calculate portfolio performance since the very beginning
    static func calculatePortfolioChangeAllTime(accounts: [Account]) -> (percentage: Double, absolute: Decimal, isPositive: Bool, hasData: Bool, actualPeriodLabel: String) {
        return PortfolioPerformanceCache.getOrCalculate(accounts: accounts, period: .allTime) {
            let activeAccounts = accounts.filter { $0.isActive }
            guard !activeAccounts.isEmpty else { return (0.0, 0, true, false, "") }
            
            // Calculate current portfolio total
            let currentTotal = activeAccounts.reduce(Decimal(0)) { total, account in
                let latestUpdate = account.updates.sorted { $0.date < $1.date }.last
                return total + (latestUpdate?.value ?? 0)
            }
            
            // Calculate baseline total (sum of all first update values)
            let baselineTotal = activeAccounts.reduce(Decimal(0)) { total, account in
                let firstUpdate = account.updates.sorted { $0.date < $1.date }.first
                return total + (firstUpdate?.value ?? 0)
            }
            
            guard baselineTotal > 0 else { return (0.0, 0, true, false, "") }
            
            let absoluteChange = currentTotal - baselineTotal
            let isPositive = absoluteChange >= 0
            
            let change = (absoluteChange / baselineTotal) * 100
            let percentage = Double(truncating: change as NSNumber)
            
            // Generate label with actual start date
            let oldestDate = activeAccounts.compactMap { account in
                account.updates.sorted { $0.date < $1.date }.first?.date
            }.min()
            
            let actualPeriodLabel: String
            if let oldestDate = oldestDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                actualPeriodLabel = "Since start (\(formatter.string(from: oldestDate)))"
            } else {
                actualPeriodLabel = "Since start"
            }
            
            return (percentage, absoluteChange, isPositive, true, actualPeriodLabel)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Helper method for time-based portfolio calculations
    private static func calculatePortfolioChangeForTimeframe(accounts: [Account], daysBack: Int) -> (percentage: Double, absolute: Decimal, isPositive: Bool, hasData: Bool, actualPeriodLabel: String) {
        let activeAccounts = accounts.filter { $0.isActive }
        guard !activeAccounts.isEmpty else { return (0.0, 0, true, false, "") }
        
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        
        // Calculate current portfolio total
        let currentTotal = activeAccounts.reduce(Decimal(0)) { total, account in
            let latestUpdate = account.updates.sorted { $0.date < $1.date }.last
            return total + (latestUpdate?.value ?? 0)
        }
        
        // Calculate baseline portfolio total (at target date)
        var baselineTotal = activeAccounts.reduce(Decimal(0)) { total, account in
            let eligibleUpdates = account.updates
                .filter { $0.date <= targetDate }
                .sorted { $0.date < $1.date }
            
            if let baselineUpdate = eligibleUpdates.last {
                return total + baselineUpdate.value
            } else {
                // Account created after target date - exclude from baseline
                return total
            }
        }
        
        // Track whether we're using target date or fallback data
        var usedFallback = false
        var oldestDate: Date? = nil
        
        // If no data from target date, fall back to oldest available data
        if baselineTotal <= 0 {
            usedFallback = true
            baselineTotal = activeAccounts.reduce(Decimal(0)) { total, account in
                let sortedUpdates = account.updates.sorted { $0.date < $1.date }
                if let firstUpdate = sortedUpdates.first {
                    if oldestDate == nil || firstUpdate.date < oldestDate! {
                        oldestDate = firstUpdate.date
                    }
                    return total + firstUpdate.value
                } else {
                    return total
                }
            }
        }
        
        // If still no data, return no change
        guard baselineTotal > 0 else { return (0.0, 0, true, false, "") }
        
        let absoluteChange = currentTotal - baselineTotal
        let isPositive = absoluteChange >= 0
        
        let change = (absoluteChange / baselineTotal) * 100
        let percentage = Double(truncating: change as NSNumber)
        
        // Generate contextual label
        let actualPeriodLabel: String
        if usedFallback, let oldestDate = oldestDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            actualPeriodLabel = "Since start (\(formatter.string(from: oldestDate)))"
        } else if daysBack >= 365 {
            actualPeriodLabel = "Past year"
        } else if daysBack >= 30 {
            actualPeriodLabel = "Past month"
        } else {
            actualPeriodLabel = "Recent period"
        }
        
        return (percentage, absoluteChange, isPositive, true, actualPeriodLabel)
    }
}