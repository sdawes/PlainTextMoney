//
//  PortfolioEngine.swift
//  PlainTextMoney
//
//  Created by Stephen Dawes on 09/08/2025.
//

import Foundation
import SwiftData

/// High-performance portfolio calculation engine that runs on a background actor
/// Offloads heavy calculations from the main thread for smooth UI performance
@ModelActor
actor PortfolioEngine {
    // MARK: - Incremental History Management (Disabled for now)
    
    // NOTE: Incremental history system disabled due to linker issues with PortfolioHistory model
    // Using legacy timeline generation for all operations
    
    // MARK: - Portfolio Timeline Generation
    
    /// Generate portfolio timeline points using legacy method (disabled incremental for now)
    /// - Parameter accounts: Active accounts to include in timeline
    /// - Returns: Array of chart data points representing portfolio value over time
    func generatePortfolioTimeline(accounts: [Account]) async -> [ChartDataPoint] {
        // TEMPORARILY: Use only legacy timeline generation to debug chart issue
        print("📊 Using legacy timeline generation")
        return await generatePortfolioTimelineLegacy(accounts: accounts)
    }
    
    /// Legacy method: Generate timeline by processing all updates (fallback for edge cases)
    /// - Parameter accounts: Active accounts to include in timeline
    /// - Returns: Array of chart data points representing portfolio value over time
    func generatePortfolioTimelineLegacy(accounts: [Account]) async -> [ChartDataPoint] {
        // Get all updates from all active accounts, sorted chronologically
        let allUpdates = accounts
            .filter { $0.isActive }
            .flatMap { $0.updates }
            .sorted { $0.date < $1.date }
        
        guard !allUpdates.isEmpty else { 
            return [] 
        }
        
        var portfolioPoints: [ChartDataPoint] = []
        var currentAccountValues: [String: Decimal] = [:] // Track running account values
        
        // For each update, recalculate portfolio total incrementally
        for update in allUpdates {
            // Update this account's current value
            currentAccountValues[update.account?.name ?? ""] = update.value
            
            // Calculate portfolio total from current values
            let portfolioTotal = currentAccountValues.values.reduce(0, +)
            portfolioPoints.append(ChartDataPoint(date: update.date, value: portfolioTotal))
        }
        
        return portfolioPoints
    }
    
    /// Generate filtered portfolio timeline for a specific period
    /// - Parameters:
    ///   - accounts: Active accounts to include
    ///   - startDate: Optional start date for filtering (nil means handle intelligently based on period)
    ///   - period: The selected time period for intelligent filtering
    /// - Returns: Filtered array of chart data points
    func generateFilteredPortfolioTimeline(
        accounts: [Account],
        startDate: Date?,
        period: PerformanceCalculationService.TimePeriod
    ) async -> [ChartDataPoint] {
        let fullTimeline = await generatePortfolioTimeline(accounts: accounts)
        
        // Handle special case for lastUpdate
        if period == .lastUpdate && startDate == nil {
            // For "Since Last Update", we need exactly the last 2 points
            if fullTimeline.count >= 2 {
                let lastTwoPoints = Array(fullTimeline.suffix(2))
                
                // DEBUG: Log the actual data points for debugging
                print("🔍 DEBUG: Since Last Update - Full timeline has \(fullTimeline.count) points")
                print("🔍 DEBUG: Last 2 points:")
                for (index, point) in lastTwoPoints.enumerated() {
                    print("   Point \(index + 1): Date=\(point.date), Value=£\(point.value)")
                }
                print("🔍 DEBUG: Values identical? \(lastTwoPoints[0].value == lastTwoPoints[1].value)")
                print("🔍 DEBUG: Dates identical? \(lastTwoPoints[0].date == lastTwoPoints[1].date)")
                
                return lastTwoPoints
            }
            return fullTimeline
        }
        
        guard let startDate = startDate else {
            return fullTimeline
        }
        
        return filterPortfolioTimeline(fullTimeline, from: startDate)
    }
    
    // MARK: - Performance Calculations
    
    /// Calculate portfolio performance for a specific time period
    /// - Parameters:
    ///   - accounts: Active accounts to calculate
    ///   - period: Time period to calculate for
    /// - Returns: Performance data including percentage and absolute changes
    func calculatePortfolioPerformance(
        accounts: [Account],
        period: PerformanceCalculationService.TimePeriod
    ) async -> (percentage: Double, absolute: Decimal, isPositive: Bool, hasData: Bool, actualPeriodLabel: String) {
        let activeAccounts = accounts.filter { $0.isActive }
        
        switch period {
        case .lastUpdate:
            return await calculatePortfolioChangeFromLastUpdate(accounts: activeAccounts)
        case .oneMonth:
            return await calculatePortfolioChangeOneMonth(accounts: activeAccounts)
        case .oneYear:
            return await calculatePortfolioChangeOneYear(accounts: activeAccounts)
        case .allTime:
            return await calculatePortfolioChangeAllTime(accounts: activeAccounts)
        }
    }
    
    /// Calculate account performance for a specific time period
    /// - Parameters:
    ///   - account: Account to calculate
    ///   - period: Time period to calculate for
    /// - Returns: Performance data including percentage and absolute changes
    func calculateAccountPerformance(
        account: Account,
        period: PerformanceCalculationService.TimePeriod
    ) async -> (percentage: Double, absolute: Decimal, isPositive: Bool, hasData: Bool) {
        switch period {
        case .lastUpdate:
            return PerformanceCalculationService.calculateAccountChangeFromLastUpdate(account: account)
        case .oneMonth:
            return PerformanceCalculationService.calculateAccountChangeOneMonth(account: account)
        case .oneYear:
            return PerformanceCalculationService.calculateAccountChangeOneYear(account: account)
        case .allTime:
            return PerformanceCalculationService.calculateAccountChangeAllTime(account: account)
        }
    }
    
    // MARK: - Private Calculation Methods
    
    private func calculatePortfolioChangeFromLastUpdate(
        accounts: [Account]
    ) async -> (percentage: Double, absolute: Decimal, isPositive: Bool, hasData: Bool, actualPeriodLabel: String) {
        let timeline = await generatePortfolioTimeline(accounts: accounts)
        
        guard timeline.count >= 2 else {
            return (0, 0, true, false, "No previous update")
        }
        
        let previousValue = timeline[timeline.count - 2].value
        let currentValue = timeline.last?.value ?? 0
        
        guard previousValue > 0 else {
            return (0, 0, true, false, "No previous value")
        }
        
        let absoluteChange = currentValue - previousValue
        let percentageChange = ((currentValue - previousValue) / previousValue) * 100
        
        return (
            Double(truncating: percentageChange as NSNumber),
            absoluteChange,
            absoluteChange >= 0,
            true,
            "Since last update"
        )
    }
    
    private func calculatePortfolioChangeOneMonth(
        accounts: [Account]
    ) async -> (percentage: Double, absolute: Decimal, isPositive: Bool, hasData: Bool, actualPeriodLabel: String) {
        let calendar = Calendar.current
        let oneMonthAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        return await calculatePortfolioChangeForPeriod(
            accounts: accounts,
            startDate: oneMonthAgo,
            periodLabel: "Past month"
        )
    }
    
    private func calculatePortfolioChangeOneYear(
        accounts: [Account]
    ) async -> (percentage: Double, absolute: Decimal, isPositive: Bool, hasData: Bool, actualPeriodLabel: String) {
        let calendar = Calendar.current
        let oneYearAgo = calendar.date(byAdding: .day, value: -365, to: Date()) ?? Date()
        
        return await calculatePortfolioChangeForPeriod(
            accounts: accounts,
            startDate: oneYearAgo,
            periodLabel: "Past year"
        )
    }
    
    private func calculatePortfolioChangeAllTime(
        accounts: [Account]
    ) async -> (percentage: Double, absolute: Decimal, isPositive: Bool, hasData: Bool, actualPeriodLabel: String) {
        let timeline = await generatePortfolioTimeline(accounts: accounts)
        
        guard let firstValue = timeline.first?.value,
              let lastValue = timeline.last?.value,
              firstValue > 0 else {
            return (0, 0, true, false, "All time")
        }
        
        let absoluteChange = lastValue - firstValue
        let percentageChange = ((lastValue - firstValue) / firstValue) * 100
        
        let firstDate = timeline.first?.date ?? Date()
        let periodLabel = "Since \(firstDate.formatted(date: .abbreviated, time: .omitted))"
        
        return (
            Double(truncating: percentageChange as NSNumber),
            absoluteChange,
            absoluteChange >= 0,
            true,
            periodLabel
        )
    }
    
    private func calculatePortfolioChangeForPeriod(
        accounts: [Account],
        startDate: Date,
        periodLabel: String
    ) async -> (percentage: Double, absolute: Decimal, isPositive: Bool, hasData: Bool, actualPeriodLabel: String) {
        let timeline = await generatePortfolioTimeline(accounts: accounts)
        
        // Find the value at or just before the start date
        var startValue: Decimal?
        var actualStartDate: Date?
        
        for point in timeline.reversed() {
            if point.date <= startDate {
                startValue = point.value
                actualStartDate = point.date
                break
            }
        }
        
        // If no data before start date, use the first available
        if startValue == nil && !timeline.isEmpty {
            startValue = timeline.first?.value
            actualStartDate = timeline.first?.date
        }
        
        guard let start = startValue,
              let lastValue = timeline.last?.value,
              start > 0 else {
            // No data for this period, fall back to all-time
            if let firstPoint = timeline.first,
               let lastPoint = timeline.last {
                let absoluteChange = lastPoint.value - firstPoint.value
                let percentageChange = firstPoint.value > 0 ? 
                    ((lastPoint.value - firstPoint.value) / firstPoint.value) * 100 : 0
                
                return (
                    Double(truncating: percentageChange as NSNumber),
                    absoluteChange,
                    absoluteChange >= 0,
                    true,
                    "Since \(firstPoint.date.formatted(date: .abbreviated, time: .omitted))"
                )
            }
            return (0, 0, true, false, periodLabel)
        }
        
        let absoluteChange = lastValue - start
        let percentageChange = ((lastValue - start) / start) * 100
        
        // Determine actual period label
        let actualLabel: String
        if let actualStart = actualStartDate, actualStart > startDate {
            actualLabel = "Since \(actualStart.formatted(date: .abbreviated, time: .omitted))"
        } else {
            actualLabel = periodLabel
        }
        
        return (
            Double(truncating: percentageChange as NSNumber),
            absoluteChange,
            absoluteChange >= 0,
            true,
            actualLabel
        )
    }
    
    // MARK: - Timeline Filtering
    
    private func filterPortfolioTimeline(_ portfolioPoints: [ChartDataPoint], from startDate: Date) -> [ChartDataPoint] {
        var filteredPoints: [ChartDataPoint] = []
        
        // Check if startDate exactly matches a portfolio point (no boundary needed)
        let hasExactMatch = portfolioPoints.contains { $0.date == startDate }
        
        if !hasExactMatch {
            // Find the last point before the startDate to maintain chart continuity
            var boundaryPoint: ChartDataPoint? = nil
            for point in portfolioPoints {
                if point.date < startDate {
                    boundaryPoint = point
                } else {
                    break
                }
            }
            
            // Add the boundary point if it exists (for chart continuity)
            if let boundaryPoint = boundaryPoint {
                filteredPoints.append(boundaryPoint)
            }
        }
        
        // Add all points from startDate onwards
        filteredPoints.append(contentsOf: portfolioPoints.filter { $0.date >= startDate })
        
        return filteredPoints
    }
    
    // MARK: - Private Helper Methods
    
    private func getAllUpdatesAfter(_ date: Date, from accounts: [Account]) -> [AccountUpdate] {
        return accounts
            .flatMap { $0.updates }
            .filter { $0.date > date }
            .sorted { $0.date < $1.date }
    }
    
    // getAllValidHistory() method removed - was part of disabled incremental history system
}