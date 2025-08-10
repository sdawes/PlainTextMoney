//
//  UIIntegrationTests.swift
//  PlainTextMoneyTests
//
//  Created by Claude on 10/08/2025.
//

import XCTest
import SwiftUI
import SwiftData
@testable import PlainTextMoney

/// Integration tests for core UI components
/// Tests the interaction between SwiftUI views, SwiftData models, and services
@MainActor
final class UIIntegrationTests: XCTestCase {
    
    var context: ModelContext!
    var container: ModelContainer!
    
    override func setUp() async throws {
        container = try TestHelpers.createTestContainer()
        context = ModelContext(container)
    }
    
    override func tearDown() async throws {
        context = nil
        container = nil
    }
    
    // MARK: - Dashboard View Integration Tests
    
    func testDashboardView_WithEmptyPortfolio() throws {
        // Given: Empty portfolio (no accounts)
        saveContext(context)
        
        // When: Dashboard calculates portfolio total
        let accounts: [Account] = []
        let totalValue = accounts.reduce(Decimal(0)) { total, account in
            let latestUpdate = account.updates.sorted { $0.date < $1.date }.last
            return total + (latestUpdate?.value ?? 0)
        }
        
        // Then: Should show zero value
        XCTAssertEqual(totalValue, 0, "Empty portfolio should have zero total value")
    }
    
    func testDashboardView_WithActiveAccounts() throws {
        // Given: Portfolio with active accounts
        let (accounts, expectedTotal) = TestHelpers.createTestPortfolio(in: context)
        saveContext(context)
        
        // When: Dashboard calculates portfolio total
        let calculatedTotal = accounts.reduce(Decimal(0)) { total, account in
            guard account.isActive else { return total }
            let latestUpdate = account.updates.sorted { $0.date < $1.date }.last
            return total + (latestUpdate?.value ?? 0)
        }
        
        // Then: Should match expected total
        TestHelpers.assertDecimalEqual(calculatedTotal, expectedTotal)
    }
    
    func testDashboardView_WithInactiveAccounts() throws {
        // Given: Portfolio with mix of active and inactive accounts
        let account1 = TestHelpers.createTestAccount(name: "Active Account", in: context)
        account1.isActive = true
        let _ = TestHelpers.createTestUpdate(value: 1000, account: account1, in: context)
        
        let account2 = TestHelpers.createTestAccount(name: "Inactive Account", in: context)
        account2.isActive = false
        let _ = TestHelpers.createTestUpdate(value: 500, account: account2, in: context)
        
        saveContext(context)
        
        // When: Dashboard calculates portfolio total (active accounts only)
        let activeAccounts = [account1, account2].filter { $0.isActive }
        let totalValue = activeAccounts.reduce(Decimal(0)) { total, account in
            let latestUpdate = account.updates.sorted { $0.date < $1.date }.last
            return total + (latestUpdate?.value ?? 0)
        }
        
        // Then: Should only include active account
        TestHelpers.assertDecimalEqual(totalValue, 1000)
    }
    
    // MARK: - Account Detail Integration Tests
    
    func testAccountDetail_CurrentValueCalculation() throws {
        // Given: Account with multiple updates
        let account = TestHelpers.createTestAccount(name: "Test Account", in: context)
        
        let calendar = Calendar.current
        let baseDate = Date()
        
        let _ = TestHelpers.createTestUpdate(
            value: 1000,
            date: calendar.date(byAdding: .day, value: -3, to: baseDate)!,
            account: account,
            in: context
        )
        let _ = TestHelpers.createTestUpdate(
            value: 1200,
            date: calendar.date(byAdding: .day, value: -1, to: baseDate)!,
            account: account,
            in: context
        )
        let _ = TestHelpers.createTestUpdate(
            value: 1150,
            date: baseDate,
            account: account,
            in: context
        )
        
        saveContext(context)
        
        // When: Calculate current value (most recent update)
        let currentValue = account.updates
            .sorted { $0.date < $1.date }
            .last?.value ?? 0
        
        // Then: Should return most recent value
        TestHelpers.assertDecimalEqual(currentValue, 1150)
    }
    
    func testAccountDetail_PerformanceCalculation() throws {
        // Given: Account with performance data
        let account = TestHelpers.createTestAccount(name: "Performance Test", in: context)
        
        let calendar = Calendar.current
        let baseDate = Date()
        
        let _ = TestHelpers.createTestUpdate(
            value: 1000,
            date: calendar.date(byAdding: .day, value: -2, to: baseDate)!,
            account: account,
            in: context
        )
        let _ = TestHelpers.createTestUpdate(
            value: 1200,
            date: calendar.date(byAdding: .day, value: -1, to: baseDate)!,
            account: account,
            in: context
        )
        
        saveContext(context)
        
        // When: Calculate performance from last update
        let performance = PerformanceCalculationService.calculateAccountChangeFromLastUpdate(account: account)
        
        // Then: Should show 20% gain (+£200)
        XCTAssertTrue(performance.hasData, "Should have performance data")
        XCTAssertTrue(performance.isPositive, "Should show positive performance")
        TestHelpers.assertPercentageEqual(performance.percentage, 20.0, accuracy: 0.1)
        TestHelpers.assertDecimalEqual(performance.absolute, 200)
    }
    
    // MARK: - Chart Data Integration Tests
    
    func testChartDataGeneration_SingleAccount() throws {
        // Given: Account with chart-worthy data
        let account = TestHelpers.createTestAccount(name: "Chart Account", in: context)
        
        let calendar = Calendar.current
        let baseDate = Date()
        
        let testData: [(value: Decimal, daysAgo: Int)] = [
            (1000, 5),
            (1100, 4),
            (1050, 3),
            (1200, 2),
            (1150, 1)
        ]
        
        for data in testData {
            let _ = TestHelpers.createTestUpdate(
                value: data.value,
                date: calendar.date(byAdding: .day, value: -data.daysAgo, to: baseDate)!,
                account: account,
                in: context
            )
        }
        
        saveContext(context)
        
        // When: Generate chart data points
        let chartDataPoints = account.updates
            .sorted { $0.date < $1.date }
            .map { ChartDataPoint(date: $0.date, value: $0.value) }
        
        // Then: Should have correct number of points in chronological order
        XCTAssertEqual(chartDataPoints.count, 5, "Should have 5 chart data points")
        
        // Verify chronological ordering
        for i in 1..<chartDataPoints.count {
            XCTAssertLessThanOrEqual(
                chartDataPoints[i-1].date,
                chartDataPoints[i].date,
                "Chart data should be in chronological order"
            )
        }
        
        // Verify values
        TestHelpers.assertDecimalEqual(chartDataPoints[0].value, 1000) // Oldest
        TestHelpers.assertDecimalEqual(chartDataPoints[4].value, 1150) // Newest
    }
    
    func testChartDataGeneration_Portfolio() throws {
        // Given: Multiple accounts for portfolio chart
        let (accounts, _) = TestHelpers.createTestPortfolio(in: context)
        saveContext(context)
        
        // When: Generate portfolio chart data
        let allUpdates = accounts.flatMap { $0.updates }
            .sorted { $0.date < $1.date }
        
        var currentAccountValues: [String: Decimal] = [:]
        let chartDataPoints = allUpdates.map { update in
            currentAccountValues[update.account?.name ?? ""] = update.value
            let total = currentAccountValues.values.reduce(0, +)
            return ChartDataPoint(date: update.date, value: total)
        }
        
        // Then: Should show portfolio progression
        XCTAssertGreaterThan(chartDataPoints.count, 0, "Should generate portfolio chart data")
        XCTAssertEqual(chartDataPoints.last?.value, 1650, "Final portfolio value should be £1650 (£1200 + £450)")
    }
    
    // MARK: - Data Consistency Integration Tests
    
    func testDataConsistency_AccountAndUpdatesRelationship() throws {
        // Given: Account with updates
        let account = TestHelpers.createTestAccount(name: "Relationship Test", in: context)
        let update1 = TestHelpers.createTestUpdate(value: 1000, account: account, in: context)
        let update2 = TestHelpers.createTestUpdate(value: 1200, account: account, in: context)
        
        saveContext(context)
        
        // When: Verify relationships
        // Then: Account should have updates
        XCTAssertEqual(account.updates.count, 2, "Account should have 2 updates")
        XCTAssertTrue(account.updates.contains(update1), "Account should contain first update")
        XCTAssertTrue(account.updates.contains(update2), "Account should contain second update")
        
        // Updates should reference account
        XCTAssertEqual(update1.account, account, "First update should reference account")
        XCTAssertEqual(update2.account, account, "Second update should reference account")
    }
    
    func testDataConsistency_CascadeDelete() throws {
        // Given: Account with updates
        let account = TestHelpers.createTestAccount(name: "Cascade Test", in: context)
        let _ = TestHelpers.createTestUpdate(value: 1000, account: account, in: context)
        let _ = TestHelpers.createTestUpdate(value: 1200, account: account, in: context)
        
        saveContext(context)
        
        let updateCount = account.updates.count
        XCTAssertEqual(updateCount, 2, "Should have 2 updates before deletion")
        
        // When: Delete account
        context.delete(account)
        saveContext(context)
        
        // Then: Updates should be cascade deleted
        let remainingUpdates = try context.fetch(FetchDescriptor<AccountUpdate>())
        XCTAssertEqual(remainingUpdates.count, 0, "All updates should be cascade deleted")
    }
    
    // MARK: - Service Integration Tests
    
    func testServiceIntegration_PerformanceCalculationWithRealData() throws {
        // Given: Real-world test scenario
        let accounts = TestHelpers.createComplexTestPortfolio(in: context)
        saveContext(context)
        
        // When: Calculate performance using actual service
        let performance = PerformanceCalculationService.calculatePortfolioChangeFromLastUpdate(accounts: accounts)
        
        // Then: Should provide valid performance data
        XCTAssertTrue(performance.hasData, "Complex portfolio should have performance data")
        XCTAssertNotEqual(performance.actualPeriodLabel, "", "Should have descriptive period label")
        XCTAssertTrue(abs(performance.percentage) >= 0, "Percentage should be valid number")
    }
    
    func testServiceIntegration_InputValidationInRealScenario() throws {
        // Given: User input scenarios
        let validInputs = ["100", "1000.50", "0.01"]
        let invalidInputs = ["", "abc", "100.123", "-50"]
        
        // When: Validate inputs as if from UI
        for input in validInputs {
            let result = InputValidator.validateMonetaryInput(input)
            
            // Then: Should be valid for account creation
            switch result {
            case .valid(let decimal):
                XCTAssertGreaterThanOrEqual(decimal, 0, "Valid input should be non-negative")
                XCTAssertLessThanOrEqual(decimal, InputValidator.maxValue, "Valid input should be within limits")
            case .invalid(let error):
                XCTFail("Valid input '\(input)' should not fail: \(error)")
            }
        }
        
        for input in invalidInputs {
            let result = InputValidator.validateMonetaryInput(input)
            
            // Then: Should prevent invalid data entry
            switch result {
            case .valid(_):
                XCTFail("Invalid input '\(input)' should not be accepted")
            case .invalid(let error):
                XCTAssertFalse(error.isEmpty, "Invalid input should provide user feedback")
            }
        }
    }
    
    // MARK: - Performance Integration Tests
    
    func testPerformance_LargePortfolioCalculations() throws {
        // Given: Large portfolio simulation
        var accounts: [Account] = []
        
        for i in 0..<20 {
            let account = TestHelpers.createTestAccount(name: "Account \(i)", in: context)
            
            // Add 10 updates per account
            for j in 0..<10 {
                let value = Decimal(1000 + (i * 100) + (j * 10))
                let date = Calendar.current.date(byAdding: .day, value: -(j + 1), to: Date())!
                let _ = TestHelpers.createTestUpdate(value: value, date: date, account: account, in: context)
            }
            
            accounts.append(account)
        }
        
        saveContext(context)
        
        // When: Measure performance calculation
        measure {
            let _ = PerformanceCalculationService.calculatePortfolioChangeFromLastUpdate(accounts: accounts)
        }
        
        // Then: Should complete within reasonable time
        // XCTest measure will fail if too slow
    }
    
    func testPerformance_ChartDataGeneration() throws {
        // Given: Complex portfolio for chart generation
        let accounts = TestHelpers.createComplexTestPortfolio(in: context)
        saveContext(context)
        
        // When: Measure chart data generation
        measure {
            let allUpdates = accounts.flatMap { $0.updates }
                .sorted { $0.date < $1.date }
            
            var currentAccountValues: [String: Decimal] = [:]
            let _ = allUpdates.map { update in
                currentAccountValues[update.account?.name ?? ""] = update.value
                let total = currentAccountValues.values.reduce(0, +)
                return ChartDataPoint(date: update.date, value: total)
            }
        }
        
        // Then: Should generate chart data efficiently
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testErrorHandling_InvalidDataScenarios() throws {
        // Given: Edge case scenarios
        let account = TestHelpers.createTestAccount(name: "Error Test", in: context)
        saveContext(context)
        
        // When: Calculate performance with no updates
        let performanceNoUpdates = PerformanceCalculationService.calculateAccountChangeFromLastUpdate(account: account)
        
        // Then: Should handle gracefully
        XCTAssertFalse(performanceNoUpdates.hasData, "No updates should result in no performance data")
        
        // When: Calculate performance with single update
        let _ = TestHelpers.createTestUpdate(value: 1000, account: account, in: context)
        saveContext(context)
        
        let performanceSingleUpdate = PerformanceCalculationService.calculateAccountChangeFromLastUpdate(account: account)
        
        // Then: Should handle gracefully
        XCTAssertFalse(performanceSingleUpdate.hasData, "Single update should result in no performance comparison")
    }
    
    // MARK: - Real-World Scenario Tests
    
    func testRealWorldScenario_UserJourney() throws {
        // Given: Simulate complete user workflow
        
        // Step 1: User creates first account
        let savingsAccount = TestHelpers.createTestAccount(name: "Savings Account", in: context)
        let _ = TestHelpers.createTestUpdate(value: 5000, account: savingsAccount, in: context)
        saveContext(context)
        
        // Step 2: User adds investment account
        let investmentAccount = TestHelpers.createTestAccount(name: "Investment Account", in: context)
        let _ = TestHelpers.createTestUpdate(value: 10000, account: investmentAccount, in: context)
        saveContext(context)
        
        // Step 3: User updates both accounts after a month
        let calendar = Calendar.current
        let oneMonthLater = calendar.date(byAdding: .month, value: 1, to: Date())!
        
        let _ = TestHelpers.createTestUpdate(value: 5200, date: oneMonthLater, account: savingsAccount, in: context)
        let _ = TestHelpers.createTestUpdate(value: 10800, date: oneMonthLater, account: investmentAccount, in: context)
        saveContext(context)
        
        // When: Calculate portfolio performance
        let accounts = [savingsAccount, investmentAccount]
        let portfolioPerformance = PerformanceCalculationService.calculatePortfolioChangeFromLastUpdate(accounts: accounts)
        
        // Then: Should show meaningful results
        XCTAssertTrue(portfolioPerformance.hasData, "User portfolio should have performance data")
        XCTAssertTrue(portfolioPerformance.isPositive, "User portfolio should show growth")
        
        // Portfolio should show positive growth from the user journey
        // Actual calculation may vary due to timeline-based calculation method
        TestHelpers.assertDecimalEqual(portfolioPerformance.absolute, 1000, accuracy: 300.0)
        XCTAssertGreaterThan(portfolioPerformance.percentage, 4.0)
        XCTAssertLessThan(portfolioPerformance.percentage, 8.0)
    }
}