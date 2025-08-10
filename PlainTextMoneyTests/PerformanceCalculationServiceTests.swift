//
//  PerformanceCalculationServiceTests.swift
//  PlainTextMoneyTests
//
//  Created by Claude on 10/08/2025.
//

import XCTest
import SwiftData
import Foundation
@testable import PlainTextMoney

/// Tests for PerformanceCalculationService
/// Verifies that financial calculations return correct results
@MainActor
final class PerformanceCalculationServiceTests: XCTestCase {
    
    var context: ModelContext!
    
    override func setUp() async throws {
        context = try createTestContext()
    }
    
    override func tearDown() async throws {
        context = nil
    }
    
    // MARK: - Last Update Tests
    
    func testCalculateAccountChangeFromLastUpdate_WithTwoUpdates() throws {
        // Given: Account with two updates showing growth
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
        XCTAssertTrue(result.hasData, "Should have data for calculation")
        XCTAssertTrue(result.isPositive, "Should show positive growth")
        TestHelpers.assertPercentageEqual(result.percentage, 20.0, accuracy: 0.1)
        TestHelpers.assertDecimalEqual(result.absolute, 200)
    }
    
    func testCalculateAccountChangeFromLastUpdate_WithLoss() throws {
        // Given: Account with loss
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
        XCTAssertTrue(result.hasData)
        XCTAssertFalse(result.isPositive, "Should show negative performance")
        TestHelpers.assertPercentageEqual(result.percentage, -20.0, accuracy: 0.1)
        TestHelpers.assertDecimalEqual(result.absolute, -200)
    }
    
    func testCalculateAccountChangeFromLastUpdate_WithSingleUpdate() throws {
        // Given: Account with only one update
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
        XCTAssertFalse(result.hasData, "Should not have data for single update scenario")
        XCTAssertEqual(result.percentage, 0.0)
        XCTAssertEqual(result.absolute, 0)
    }
    
    func testCalculateAccountChangeFromLastUpdate_WithNoUpdates() throws {
        // Given: Account with no updates
        let account = TestHelpers.createTestAccount(name: "Empty Account", in: context)
        saveContext(context)
        
        // When
        let result = PerformanceCalculationService.calculateAccountChangeFromLastUpdate(account: account)
        
        // Then: Should indicate no data available
        XCTAssertFalse(result.hasData, "Should not have data for empty account")
    }
    
    // MARK: - All Time Tests
    
    func testCalculateAccountChangeAllTime_WithMultipleUpdates() throws {
        // Given: Account with progression over time
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
        XCTAssertTrue(result.hasData)
        XCTAssertTrue(result.isPositive)
        TestHelpers.assertPercentageEqual(result.percentage, 100.0, accuracy: 0.1)
        TestHelpers.assertDecimalEqual(result.absolute, 500)
    }
    
    // MARK: - One Month Tests
    
    func testCalculateAccountChangeOneMonth() throws {
        // Given: Account with updates spanning more than one month
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
        XCTAssertTrue(result.hasData)
        XCTAssertTrue(result.isPositive)
        
        // Should calculate from 2 months ago (£800) to current (£1080)
        // Growth: £1080 - £800 = £280 gain on £800 base = 35% gain
        XCTAssertGreaterThan(result.percentage, 34.0)
        XCTAssertLessThan(result.percentage, 36.0)
    }
    
    // MARK: - One Year Tests
    
    func testCalculateAccountChangeOneYear() throws {
        // Given: Account with updates spanning more than one year
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
        XCTAssertTrue(result.hasData)
        XCTAssertTrue(result.isPositive)
        XCTAssertGreaterThan(result.percentage, 90.0) // Close to 100% gain
    }
    
    // MARK: - Edge Cases
    
    func testCalculateWithZeroInitialValue() throws {
        // Given: Account starting with £0
        let account = TestHelpers.createTestAccount(name: "Zero Start", in: context)
        
        let _ = TestHelpers.createTestUpdate(value: 0, date: Date(timeIntervalSinceNow: -86400), account: account, in: context)
        let _ = TestHelpers.createTestUpdate(value: 100, date: Date(), account: account, in: context)
        
        saveContext(context)
        
        // When
        let result = PerformanceCalculationService.calculateAccountChangeFromLastUpdate(account: account)
        
        // Then: Should handle division by zero gracefully
        XCTAssertFalse(result.hasData, "Should not calculate percentage from zero base")
        XCTAssertEqual(result.percentage, 0.0)
        XCTAssertEqual(result.absolute, 0)
    }
    
    func testCalculateWithIdenticalValues() throws {
        // Given: Account with no change
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
        XCTAssertTrue(result.hasData)
        XCTAssertTrue(result.isPositive) // 0% is considered positive (no loss)
        TestHelpers.assertPercentageEqual(result.percentage, 0.0, accuracy: 0.01)
        TestHelpers.assertDecimalEqual(result.absolute, 0)
    }
    
    // MARK: - Precision Tests
    
    func testDecimalPrecisionInCalculations() throws {
        // Given: Account with precise decimal values
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
        XCTAssertTrue(result.hasData)
        XCTAssertTrue(result.isPositive)
        
        let expectedChange = Decimal(string: "50.34")! // 1050.67 - 1000.33
        TestHelpers.assertDecimalEqual(result.absolute, expectedChange, accuracy: 0.01)
        
        // Percentage should be approximately 5.03%
        TestHelpers.assertPercentageEqual(result.percentage, 5.03, accuracy: 0.1)
    }
}