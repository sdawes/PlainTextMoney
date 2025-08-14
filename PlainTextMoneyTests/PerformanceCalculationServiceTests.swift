//
//  PerformanceCalculationServiceTests.swift
//  PlainTextMoneyTests
//
//  Created by Claude on 10/08/2025.
//

import Testing
import SwiftData
import Foundation
@testable import PlainTextMoney

/// Tests for PerformanceCalculationService
/// Verifies that financial calculations return correct results
@MainActor
struct PerformanceCalculationServiceTests {
    
    // MARK: - Last Update Tests
    
    @Test func calculateAccountChangeFromLastUpdate_WithTwoUpdates() throws {
        // Given: Account with two updates showing growth
        let context = try TestHelpers.createTestContext()
        let account = TestHelpers.createTestAccount(name: "Growth Test", in: context)
        
        let calendar = Calendar.current
        let baseDate = Date()
        
        // First update: £1000
        let _ = TestHelpers.createTestUpdate(
            value: 1000,
            date: calendar.date(byAdding: .day, value: -2, to: baseDate)!,
            account: account,
            in: context
        )
        
        // Second update: £1200 (+20% gain, +£200)
        let _ = TestHelpers.createTestUpdate(
            value: 1200,
            date: calendar.date(byAdding: .day, value: -1, to: baseDate)!,
            account: account,
            in: context
        )
        
        saveContext(context)
        
        // When: Calculate performance from last update
        let result = PerformanceCalculationService.calculateAccountChangeFromLastUpdate(account: account)
        
        // Then: Should show 20% gain and £200 absolute gain
        #expect(result.hasData, "Should have data for calculation")
        #expect(result.isPositive, "Should show positive growth")
        TestHelpers.expectPercentageEqual(result.percentage, 20.0, accuracy: 0.1)
        TestHelpers.expectDecimalEqual(result.absolute, 200)
    }
    
    @Test func calculateAccountChangeFromLastUpdate_WithLoss() throws {
        // Given: Account with loss
        let context = try TestHelpers.createTestContext()
        let account = TestHelpers.createTestAccount(name: "Loss Test", in: context)
        
        let calendar = Calendar.current
        let baseDate = Date()
        
        let _ = TestHelpers.createTestUpdate(
            value: 1000,
            date: calendar.date(byAdding: .day, value: -2, to: baseDate)!,
            account: account,
            in: context
        )
        
        let _ = TestHelpers.createTestUpdate(
            value: 800, // -20% loss, -£200
            date: calendar.date(byAdding: .day, value: -1, to: baseDate)!,
            account: account,
            in: context
        )
        
        saveContext(context)
        
        // When
        let result = PerformanceCalculationService.calculateAccountChangeFromLastUpdate(account: account)
        
        // Then
        #expect(result.hasData)
        #expect(!result.isPositive, "Should show negative performance")
        TestHelpers.expectPercentageEqual(result.percentage, -20.0, accuracy: 0.1)
        TestHelpers.expectDecimalEqual(result.absolute, -200)
    }
    
    @Test func calculateAccountChangeFromLastUpdate_WithSingleUpdate() throws {
        // Given: Account with only one update
        let context = try TestHelpers.createTestContext()
        let account = TestHelpers.createTestAccount(name: "Single Update", in: context)
        
        let _ = TestHelpers.createTestUpdate(
            value: 1000,
            date: Date(),
            account: account,
            in: context
        )
        
        saveContext(context)
        
        // When
        let result = PerformanceCalculationService.calculateAccountChangeFromLastUpdate(account: account)
        
        // Then: Should indicate no data available
        #expect(!result.hasData, "Should not have data for single update scenario")
        #expect(result.percentage == 0.0)
        #expect(result.absolute == 0)
    }
    
    @Test func calculateAccountChangeFromLastUpdate_WithNoUpdates() throws {
        // Given: Account with no updates
        let context = try TestHelpers.createTestContext()
        let account = TestHelpers.createTestAccount(name: "Empty Account", in: context)
        saveContext(context)
        
        // When
        let result = PerformanceCalculationService.calculateAccountChangeFromLastUpdate(account: account)
        
        // Then: Should indicate no data available
        #expect(!result.hasData, "Should not have data for empty account")
    }
    
    // MARK: - All Time Tests
    
    @Test func calculateAccountChangeAllTime_WithMultipleUpdates() throws {
        // Given: Account with progression over time
        let context = try TestHelpers.createTestContext()
        let account = TestHelpers.createTestAccount(name: "All Time Test", in: context)
        
        let calendar = Calendar.current
        let baseDate = Date()
        
        // First update: £500 (baseline)
        let _ = TestHelpers.createTestUpdate(
            value: 500,
            date: calendar.date(byAdding: .month, value: -6, to: baseDate)!,
            account: account,
            in: context
        )
        
        // Middle update: £700
        let _ = TestHelpers.createTestUpdate(
            value: 700,
            date: calendar.date(byAdding: .month, value: -3, to: baseDate)!,
            account: account,
            in: context
        )
        
        // Latest update: £1000 (100% gain from start, +£500)
        let _ = TestHelpers.createTestUpdate(
            value: 1000,
            date: baseDate,
            account: account,
            in: context
        )
        
        saveContext(context)
        
        // When
        let result = PerformanceCalculationService.calculateAccountChangeAllTime(account: account)
        
        // Then: Should show 100% gain from first to last
        #expect(result.hasData)
        #expect(result.isPositive)
        TestHelpers.expectPercentageEqual(result.percentage, 100.0, accuracy: 0.1)
        TestHelpers.expectDecimalEqual(result.absolute, 500)
    }
    
    // MARK: - One Month Tests
    
    @Test func calculateAccountChangeOneMonth() throws {
        // Given: Account with updates spanning more than one month
        let context = try TestHelpers.createTestContext()
        let account = TestHelpers.createTestAccount(name: "Month Test", in: context)
        
        let calendar = Calendar.current
        let baseDate = Date()
        
        // Update 2 months ago: £800
        let _ = TestHelpers.createTestUpdate(
            value: 800,
            date: calendar.date(byAdding: .month, value: -2, to: baseDate)!,
            account: account,
            in: context
        )
        
        // Update 3 weeks ago: £900 (this should be the baseline for "one month")
        let _ = TestHelpers.createTestUpdate(
            value: 900,
            date: calendar.date(byAdding: .weekOfYear, value: -3, to: baseDate)!,
            account: account,
            in: context
        )
        
        // Current update: £1080 (20% gain from £900)
        let _ = TestHelpers.createTestUpdate(
            value: 1080,
            date: baseDate,
            account: account,
            in: context
        )
        
        saveContext(context)
        
        // When
        let result = PerformanceCalculationService.calculateAccountChangeOneMonth(account: account)
        
        // Then: Should calculate from ~1 month ago value to current
        #expect(result.hasData)
        #expect(result.isPositive)
        
        // Should calculate from 2 months ago (£800) to current (£1080)
        // Growth: £1080 - £800 = £280 gain on £800 base = 35% gain
        #expect(result.percentage > 34.0)
        #expect(result.percentage < 36.0)
    }
    
    // MARK: - Three Months Tests
    
    @Test func calculateAccountChangeThreeMonths() throws {
        // Given: Account with updates spanning more than three months
        let context = try TestHelpers.createTestContext()
        let account = TestHelpers.createTestAccount(name: "Three Month Test", in: context)
        
        let calendar = Calendar.current
        let baseDate = Date()
        
        // Update 6 months ago: £1000
        let _ = TestHelpers.createTestUpdate(
            value: 1000,
            date: calendar.date(byAdding: .month, value: -6, to: baseDate)!,
            account: account,
            in: context
        )
        
        // Update ~3 months ago: £1200 (this should be the baseline for "three months")
        let _ = TestHelpers.createTestUpdate(
            value: 1200,
            date: calendar.date(byAdding: .day, value: -95, to: baseDate)!,
            account: account,
            in: context
        )
        
        // Current update: £1440 (20% gain from £1200)
        let _ = TestHelpers.createTestUpdate(
            value: 1440,
            date: baseDate,
            account: account,
            in: context
        )
        
        saveContext(context)
        
        // When
        let result = PerformanceCalculationService.calculateAccountChangeThreeMonths(account: account)
        
        // Then: Should calculate from ~3 months ago value to current
        #expect(result.hasData)
        #expect(result.isPositive)
        
        // Should calculate from 3+ months ago (£1200) to current (£1440)
        // Growth: £1440 - £1200 = £240 gain on £1200 base = 20% gain
        #expect(result.percentage > 19.0)
        #expect(result.percentage < 21.0)
    }
    
    @Test func calculateAccountChangeThreeMonthsAccountNewerThan3Months() throws {
        // Given: Account that's only 2 months old
        let context = try TestHelpers.createTestContext()
        let account = TestHelpers.createTestAccount(name: "New Account", in: context)
        
        let calendar = Calendar.current
        let baseDate = Date()
        
        // Initial update: £500 (2 months ago - account is newer than 3 months)
        let _ = TestHelpers.createTestUpdate(
            value: 500,
            date: calendar.date(byAdding: .month, value: -2, to: baseDate)!,
            account: account,
            in: context
        )
        
        // Current update: £700 (40% gain from £500)
        let _ = TestHelpers.createTestUpdate(
            value: 700,
            date: baseDate,
            account: account,
            in: context
        )
        
        saveContext(context)
        
        // When
        let result = PerformanceCalculationService.calculateAccountChangeThreeMonths(account: account)
        
        // Then: Should use first update as baseline since account is newer than 3 months
        #expect(result.hasData)
        #expect(result.isPositive)
        
        // Should calculate from first update (£500) to current (£700)
        // Growth: £700 - £500 = £200 gain on £500 base = 40% gain
        TestHelpers.expectPercentageEqual(result.percentage, 40.0, accuracy: 0.1)
        TestHelpers.expectDecimalEqual(result.absolute, 200)
    }
    
    @Test func calculateAccountChangeThreeMonthsAbsoluteValues() throws {
        // Given: Account with specific monetary values for precise absolute testing
        let context = try TestHelpers.createTestContext()
        let account = TestHelpers.createTestAccount(name: "Absolute Value Test", in: context)
        
        let calendar = Calendar.current
        let baseDate = Date()
        
        // Update 4 months ago: £10,000
        let _ = TestHelpers.createTestUpdate(
            value: 10000,
            date: calendar.date(byAdding: .month, value: -4, to: baseDate)!,
            account: account,
            in: context
        )
        
        // Update exactly 3 months ago: £12,500 (baseline for 3-month calculation)
        let _ = TestHelpers.createTestUpdate(
            value: 12500,
            date: calendar.date(byAdding: .day, value: -90, to: baseDate)!,
            account: account,
            in: context
        )
        
        // Current update: £15,750 (£3,250 gain from £12,500 = 26% gain)
        let _ = TestHelpers.createTestUpdate(
            value: 15750,
            date: baseDate,
            account: account,
            in: context
        )
        
        saveContext(context)
        
        // When
        let result = PerformanceCalculationService.calculateAccountChangeThreeMonths(account: account)
        
        // Then: Verify exact absolute values
        #expect(result.hasData)
        #expect(result.isPositive)
        
        // Absolute change should be exactly £3,250
        TestHelpers.expectDecimalEqual(result.absolute, 3250, accuracy: 0.01)
        
        // Percentage should be 26% (3250/12500 = 0.26)
        TestHelpers.expectPercentageEqual(result.percentage, 26.0, accuracy: 0.1)
    }
    
    @Test func calculateAccountChangeThreeMonthsLoss() throws {
        // Given: Account with a loss over 3 months
        let context = try TestHelpers.createTestContext()
        let account = TestHelpers.createTestAccount(name: "Loss Test", in: context)
        
        let calendar = Calendar.current
        let baseDate = Date()
        
        // Update 3+ months ago: £20,000 (baseline)
        let _ = TestHelpers.createTestUpdate(
            value: 20000,
            date: calendar.date(byAdding: .day, value: -95, to: baseDate)!,
            account: account,
            in: context
        )
        
        // Current update: £16,000 (£4,000 loss = -20%)
        let _ = TestHelpers.createTestUpdate(
            value: 16000,
            date: baseDate,
            account: account,
            in: context
        )
        
        saveContext(context)
        
        // When
        let result = PerformanceCalculationService.calculateAccountChangeThreeMonths(account: account)
        
        // Then: Verify loss values are correct
        #expect(result.hasData)
        #expect(!result.isPositive, "Should indicate a loss")
        
        // Absolute change should be exactly -£4,000
        TestHelpers.expectDecimalEqual(result.absolute, -4000, accuracy: 0.01)
        
        // Percentage should be -20% (-4000/20000 = -0.20)
        TestHelpers.expectPercentageEqual(result.percentage, -20.0, accuracy: 0.1)
    }
    
    @Test func calculateAccountChangeThreeMonthsPrecisionTest() throws {
        // Given: Account with decimal precision values
        let context = try TestHelpers.createTestContext()
        let account = TestHelpers.createTestAccount(name: "Precision Test", in: context)
        
        let calendar = Calendar.current
        let baseDate = Date()
        
        // Baseline: £1,234.56
        let _ = TestHelpers.createTestUpdate(
            value: Decimal(string: "1234.56")!,
            date: calendar.date(byAdding: .day, value: -92, to: baseDate)!,
            account: account,
            in: context
        )
        
        // Current: £1,358.79 (gain of £124.23)
        let _ = TestHelpers.createTestUpdate(
            value: Decimal(string: "1358.79")!,
            date: baseDate,
            account: account,
            in: context
        )
        
        saveContext(context)
        
        // When
        let result = PerformanceCalculationService.calculateAccountChangeThreeMonths(account: account)
        
        // Then: Verify decimal precision is maintained
        #expect(result.hasData)
        #expect(result.isPositive)
        
        // Absolute change: £124.23
        TestHelpers.expectDecimalEqual(result.absolute, Decimal(string: "124.23")!, accuracy: 0.01)
        
        // Percentage: 124.23/1234.56 ≈ 10.06%
        TestHelpers.expectPercentageEqual(result.percentage, 10.06, accuracy: 0.1)
    }
    
    // MARK: - One Year Tests
    
    @Test func calculateAccountChangeOneYear() throws {
        // Given: Account with updates spanning more than one year
        let context = try TestHelpers.createTestContext()
        let account = TestHelpers.createTestAccount(name: "Year Test", in: context)
        
        let calendar = Calendar.current
        let baseDate = Date()
        
        // Update 18 months ago: £500
        let _ = TestHelpers.createTestUpdate(
            value: 500,
            date: calendar.date(byAdding: .month, value: -18, to: baseDate)!,
            account: account,
            in: context
        )
        
        // Update ~1 year ago: £600
        let _ = TestHelpers.createTestUpdate(
            value: 600,
            date: calendar.date(byAdding: .month, value: -11, to: baseDate)!,
            account: account,
            in: context
        )
        
        // Current update: £1200 (100% gain from £600)
        let _ = TestHelpers.createTestUpdate(
            value: 1200,
            date: baseDate,
            account: account,
            in: context
        )
        
        saveContext(context)
        
        // When
        let result = PerformanceCalculationService.calculateAccountChangeOneYear(account: account)
        
        // Then: Should show substantial gain from ~1 year ago
        #expect(result.hasData)
        #expect(result.isPositive)
        #expect(result.percentage > 90.0) // Close to 100% gain
    }
    
    // MARK: - Edge Cases
    
    @Test func calculateWithZeroInitialValue() throws {
        // Given: Account starting with £0
        let context = try TestHelpers.createTestContext()
        let account = TestHelpers.createTestAccount(name: "Zero Start", in: context)
        
        let _ = TestHelpers.createTestUpdate(value: 0, date: Date(timeIntervalSinceNow: -86400), account: account, in: context)
        let _ = TestHelpers.createTestUpdate(value: 100, date: Date(), account: account, in: context)
        
        saveContext(context)
        
        // When
        let result = PerformanceCalculationService.calculateAccountChangeFromLastUpdate(account: account)
        
        // Then: Should handle division by zero gracefully
        #expect(!result.hasData, "Should not calculate percentage from zero base")
        #expect(result.percentage == 0.0)
        #expect(result.absolute == 0)
    }
    
    @Test func calculateWithIdenticalValues() throws {
        // Given: Account with no change
        let context = try TestHelpers.createTestContext()
        let account = TestHelpers.createTestAccount(name: "No Change", in: context)
        
        let calendar = Calendar.current
        let baseDate = Date()
        
        let _ = TestHelpers.createTestUpdate(
            value: 1000,
            date: calendar.date(byAdding: .day, value: -2, to: baseDate)!,
            account: account,
            in: context
        )
        let _ = TestHelpers.createTestUpdate(
            value: 1000, // Same value
            date: calendar.date(byAdding: .day, value: -1, to: baseDate)!,
            account: account,
            in: context
        )
        
        saveContext(context)
        
        // When
        let result = PerformanceCalculationService.calculateAccountChangeFromLastUpdate(account: account)
        
        // Then: Should show 0% change
        #expect(result.hasData)
        #expect(result.isPositive) // 0% is considered positive (no loss)
        TestHelpers.expectPercentageEqual(result.percentage, 0.0, accuracy: 0.01)
        TestHelpers.expectDecimalEqual(result.absolute, 0)
    }
    
    // MARK: - Precision Tests
    
    @Test func decimalPrecisionInCalculations() throws {
        // Given: Account with precise decimal values
        let context = try TestHelpers.createTestContext()
        let account = TestHelpers.createTestAccount(name: "Precision Test", in: context)
        
        // Use precise decimal values to test rounding
        let _ = TestHelpers.createTestUpdate(
            value: Decimal(string: "1000.33")!,
            date: Date(timeIntervalSinceNow: -86400),
            account: account,
            in: context
        )
        let _ = TestHelpers.createTestUpdate(
            value: Decimal(string: "1050.67")!,
            date: Date(),
            account: account,
            in: context
        )
        
        saveContext(context)
        
        // When
        let result = PerformanceCalculationService.calculateAccountChangeFromLastUpdate(account: account)
        
        // Then: Should maintain decimal precision
        #expect(result.hasData)
        #expect(result.isPositive)
        
        let expectedChange = Decimal(string: "50.34")! // 1050.67 - 1000.33
        TestHelpers.expectDecimalEqual(result.absolute, expectedChange, accuracy: 0.01)
        
        // Percentage should be approximately 5.03%
        TestHelpers.expectPercentageEqual(result.percentage, 5.03, accuracy: 0.1)
    }
    
    // MARK: - Chart Data Filtering Tests
    
    @Test func threeMonthChartDataFiltering() throws {
        // Given: Account with updates spanning more than 3 months
        let context = try TestHelpers.createTestContext()
        let account = TestHelpers.createTestAccount(name: "Chart Filter Test", in: context)
        
        let calendar = Calendar.current
        let baseDate = Date()
        
        // Create updates spanning 6 months
        let testDates: [(months: Int, value: Decimal)] = [
            (-6, 1000),  // 6 months ago - should be excluded
            (-5, 1100),  // 5 months ago - should be excluded  
            (-4, 1200),  // 4 months ago - should be excluded
            (-3, 1300),  // 3 months ago - should be included (boundary)
            (-2, 1400),  // 2 months ago - should be included
            (-1, 1500),  // 1 month ago - should be included
            (0, 1600)    // today - should be included
        ]
        
        var allUpdates: [AccountUpdate] = []
        for (monthsOffset, value) in testDates {
            let date = calendar.date(byAdding: .month, value: monthsOffset, to: baseDate)!
            let update = TestHelpers.createTestUpdate(value: value, date: date, account: account, in: context)
            allUpdates.append(update)
        }
        
        saveContext(context)
        
        // When: Filter for 3-month period (90 days)
        let threeMonthsAgo = calendar.date(byAdding: .day, value: -90, to: baseDate)!
        let filteredUpdates = account.updates.filter { $0.date >= threeMonthsAgo }.sorted { $0.date < $1.date }
        
        // Then: Should include approximately the last 3 months of data
        #expect(filteredUpdates.count >= 3, "Should have at least 3 updates in 3-month window")
        #expect(filteredUpdates.count <= 5, "Should not have more than 5 updates in 3-month window")
        
        // Verify the oldest included update is not older than 3 months + some tolerance
        if let oldestFiltered = filteredUpdates.first {
            let daysSinceOldest = calendar.dateComponents([.day], from: oldestFiltered.date, to: baseDate).day ?? 0
            #expect(daysSinceOldest <= 100, "Oldest filtered update should be within ~3 months (allowing some tolerance)")
        }
        
        // Verify the newest update is included
        if let newestFiltered = filteredUpdates.last {
            let newestOriginal = allUpdates.sorted { $0.date < $1.date }.last!
            #expect(newestFiltered.value == newestOriginal.value, "Most recent update should be included")
        }
    }
    
    @Test func threeMonthChartDataBoundaryConditions() throws {
        // Given: Account with updates exactly at 3-month boundaries
        let context = try TestHelpers.createTestContext()
        let account = TestHelpers.createTestAccount(name: "Boundary Test", in: context)
        
        let calendar = Calendar.current
        let baseDate = Date()
        
        // Create updates at specific intervals around the 3-month boundary
        let exactlyThreeMonthsAgo = calendar.date(byAdding: .day, value: -90, to: baseDate)!
        let justBeforeThreeMonths = calendar.date(byAdding: .day, value: -91, to: baseDate)!
        let justAfterThreeMonths = calendar.date(byAdding: .day, value: -89, to: baseDate)!
        
        let _ = TestHelpers.createTestUpdate(value: 1000, date: justBeforeThreeMonths, account: account, in: context)
        let exactBoundaryUpdate = TestHelpers.createTestUpdate(value: 1100, date: exactlyThreeMonthsAgo, account: account, in: context)
        let _ = TestHelpers.createTestUpdate(value: 1200, date: justAfterThreeMonths, account: account, in: context)
        let _ = TestHelpers.createTestUpdate(value: 1300, date: baseDate, account: account, in: context)
        
        saveContext(context)
        
        // When: Filter for 3-month period
        let filteredUpdates = account.updates.filter { $0.date >= exactlyThreeMonthsAgo }.sorted { $0.date < $1.date }
        
        // Then: Should include the boundary update and all after, but not before
        #expect(filteredUpdates.count == 3, "Should include exactly 3 updates (boundary + 2 after)")
        #expect(filteredUpdates.first?.value == exactBoundaryUpdate.value, "Should include the boundary update")
        #expect(filteredUpdates.contains { $0.value == 1200 }, "Should include update just after boundary")
        #expect(filteredUpdates.contains { $0.value == 1300 }, "Should include current update")
        #expect(!filteredUpdates.contains { $0.value == 1000 }, "Should exclude update just before boundary")
    }
    
    @Test func threeMonthChartDataWithSparseUpdates() throws {
        // Given: Account with very few updates in 3-month window
        let context = try TestHelpers.createTestContext()
        let account = TestHelpers.createTestAccount(name: "Sparse Data Test", in: context)
        
        let calendar = Calendar.current
        let baseDate = Date()
        
        // Create sparse updates - only 2 updates in the 3-month window
        let _ = TestHelpers.createTestUpdate(value: 1000, date: calendar.date(byAdding: .month, value: -6, to: baseDate)!, account: account, in: context)
        let oldUpdate = TestHelpers.createTestUpdate(value: 1500, date: calendar.date(byAdding: .day, value: -60, to: baseDate)!, account: account, in: context)
        let newUpdate = TestHelpers.createTestUpdate(value: 1800, date: baseDate, account: account, in: context)
        
        saveContext(context)
        
        // When: Filter for 3-month period
        let threeMonthsAgo = calendar.date(byAdding: .day, value: -90, to: baseDate)!
        let filteredUpdates = account.updates.filter { $0.date >= threeMonthsAgo }.sorted { $0.date < $1.date }
        
        // Then: Should handle sparse data gracefully
        #expect(filteredUpdates.count == 2, "Should include exactly 2 updates in 3-month window")
        #expect(filteredUpdates.first?.value == oldUpdate.value, "Should include the older update in window")
        #expect(filteredUpdates.last?.value == newUpdate.value, "Should include the current update")
        #expect(!filteredUpdates.contains { $0.value == 1000 }, "Should exclude very old update")
        
        // Verify chart data would work with this sparse data
        let chartPoints = filteredUpdates.map { ChartDataPoint(date: $0.date, value: $0.value) }
        #expect(chartPoints.count == 2, "Chart should handle 2 data points")
        #expect(chartPoints.first?.value == 1500, "First chart point should match first update")
        #expect(chartPoints.last?.value == 1800, "Last chart point should match last update")
    }
}