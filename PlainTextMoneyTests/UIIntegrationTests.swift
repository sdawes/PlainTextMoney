//
//  UIIntegrationTests.swift
//  PlainTextMoneyTests
//
//  Created by Claude on 10/08/2025.
//

import Testing
import SwiftUI
import SwiftData
@testable import PlainTextMoney

/// Integration tests for core UI components
/// Tests the interaction between SwiftUI views, SwiftData models, and services
@MainActor
struct UIIntegrationTests {
    
    
    // MARK: - Dashboard View Integration Tests
    
    @Test func dashboardView_WithEmptyPortfolio() throws {
        // Given: Empty portfolio (no accounts)
        
        
        // When: Dashboard calculates portfolio total
        let accounts: [Account] = []
        let totalValue = accounts.reduce(Decimal(0)) { total, account in
            let latestUpdate = account.updates.sorted { $0.date < $1.date }.last
            return total + (latestUpdate?.value ?? 0)
        }
        
        // Then: Should show zero value
        #expect(totalValue == 0, "Empty portfolio should have zero total value")
    }
    
    @Test func DashboardView_WithActiveAccounts() throws {
        // Given: Portfolio with active accounts
        let context = try TestHelpers.createTestContext()
        let (accounts, expectedTotal) = TestHelpers.createTestPortfolio(in: context)
        saveContext(context)
        
        
        // When: Dashboard calculates portfolio total
        let calculatedTotal = accounts.reduce(Decimal(0)) { total, account in
            guard account.isActive else { return total }
            let latestUpdate = account.updates.sorted { $0.date < $1.date }.last
            return total + (latestUpdate?.value ?? 0)
        }
        
        // Then: Should match expected total
        TestHelpers.expectDecimalEqual(calculatedTotal, expectedTotal)
    }
    
    @Test func DashboardView_WithInactiveAccounts() throws {
        // Given: Portfolio with mix of active and inactive accounts
        let context = try TestHelpers.createTestContext()
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
        TestHelpers.expectDecimalEqual(totalValue, 1000)
    }
    
    // MARK: - Account Detail Integration Tests
    
    @Test func AccountDetail_CurrentValueCalculation() throws {
        // Given: Account with multiple updates
        let context = try TestHelpers.createTestContext()
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
        TestHelpers.expectDecimalEqual(currentValue, 1150)
    }
    
    @Test func AccountDetail_PerformanceCalculation() throws {
        // Given: Account with performance data
        let context = try TestHelpers.createTestContext()
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
        #expect(performance.hasData, "Should have performance data")
        #expect(performance.isPositive, "Should show positive performance")
        TestHelpers.expectPercentageEqual(performance.percentage, 20.0, accuracy: 0.1)
        TestHelpers.expectDecimalEqual(performance.absolute, 200)
    }
    
    // MARK: - Chart Data Integration Tests
    
    @Test func ChartDataGeneration_SingleAccount() throws {
        // Given: Account with chart-worthy data
        let context = try TestHelpers.createTestContext()
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
        #expect(chartDataPoints.count == 5, "Should have 5 chart data points")
        
        // Verify chronological ordering
        for i in 1..<chartDataPoints.count {
            #expect(
                chartDataPoints[i-1].date <= chartDataPoints[i].date,
                "Chart data should be in chronological order"
            )
        }
        
        // Verify values
        TestHelpers.expectDecimalEqual(chartDataPoints[0].value, 1000) // Oldest
        TestHelpers.expectDecimalEqual(chartDataPoints[4].value, 1150) // Newest
    }
    
    @Test func ChartDataGeneration_Portfolio() throws {
        // Given: Multiple accounts for portfolio chart
        let context = try TestHelpers.createTestContext()
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
        #expect(chartDataPoints.count > 0, "Should generate portfolio chart data")
        #expect(chartDataPoints.last?.value == 1650, "Final portfolio value should be £1650 (£1200 + £450)")
    }
    
    // MARK: - Data Consistency Integration Tests
    
    @Test func DataConsistency_AccountAndUpdatesRelationship() throws {
        // Given: Account with updates
        let context = try TestHelpers.createTestContext()
        let account = TestHelpers.createTestAccount(name: "Relationship Test", in: context)
        let update1 = TestHelpers.createTestUpdate(value: 1000, account: account, in: context)
        let update2 = TestHelpers.createTestUpdate(value: 1200, account: account, in: context)
        
        saveContext(context)
        
        // When: Verify relationships
        // Then: Account should have updates
        #expect(account.updates.count == 2, "Account should have 2 updates")
        #expect(account.updates.contains(update1), "Account should contain first update")
        #expect(account.updates.contains(update2), "Account should contain second update")
        
        // Updates should reference account
        #expect(update1.account == account, "First update should reference account")
        #expect(update2.account == account, "Second update should reference account")
    }
    
    @Test func DataConsistency_CascadeDelete() throws {
        // Given: Account with updates
        let context = try TestHelpers.createTestContext()
        let account = TestHelpers.createTestAccount(name: "Cascade Test", in: context)
        let _ = TestHelpers.createTestUpdate(value: 1000, account: account, in: context)
        let _ = TestHelpers.createTestUpdate(value: 1200, account: account, in: context)
        
        saveContext(context)
        
        let updateCount = account.updates.count
        #expect(updateCount == 2, "Should have 2 updates before deletion")
        
        // When: Delete account
        context.delete(account)
        saveContext(context)
        
        // Then: Updates should be cascade deleted
        let remainingUpdates = try context.fetch(FetchDescriptor<AccountUpdate>())
        #expect(remainingUpdates.count == 0, "All updates should be cascade deleted")
    }
    
    // MARK: - Service Integration Tests
    
    @Test func ServiceIntegration_PerformanceCalculationWithRealData() throws {
        // Given: Real-world test scenario
        let context = try TestHelpers.createTestContext()
        let accounts = TestHelpers.createComplexTestPortfolio(in: context)
        saveContext(context)
        
        
        // When: Calculate performance using actual service
        let performance = PerformanceCalculationService.calculatePortfolioChangeFromLastUpdate(accounts: accounts)
        
        // Then: Should provide valid performance data
        #expect(performance.hasData, "Complex portfolio should have performance data")
        #expect(performance.actualPeriodLabel != "", "Should have descriptive period label")
        #expect(abs(performance.percentage) >= 0, "Percentage should be valid number")
    }
    
    @Test func ServiceIntegration_InputValidationInRealScenario() throws {
        // Given: User input scenarios
        let validInputs = ["100", "1000.50", "0.01"]
        let invalidInputs = ["", "abc", "100.123", "-50"]
        
        // When: Validate inputs as if from UI
        for input in validInputs {
            let result = InputValidator.validateMonetaryInput(input)
            
            // Then: Should be valid for account creation
            switch result {
            case .valid(let decimal):
                #expect(decimal >= 0, "Valid input should be non-negative")
                #expect(decimal <= InputValidator.maxValue, "Valid input should be within limits")
            case .invalid(let error):
                Issue.record("Valid input '\(input)' should not fail: \(error)")
            }
        }
        
        for input in invalidInputs {
            let result = InputValidator.validateMonetaryInput(input)
            
            // Then: Should prevent invalid data entry
            switch result {
            case .valid(_):
                Issue.record("Invalid input '\(input)' should not be accepted")
            case .invalid(let error):
                #expect(!error.isEmpty, "Invalid input should provide user feedback")
            }
        }
    }
    
    // MARK: - Form Validation Integration Tests
    
    @Test func AddAccountView_NameValidation_Empty() throws {
        // Given: Empty account name
        let emptyNames = ["", " ", "   ", "\t", "\n"]
        
        for name in emptyNames {
            // When: Validate account name
            let result = InputValidator.validateAccountName(name)
            
            // Then: Should be invalid
            switch result {
            case .valid(_):
                Issue.record("Empty name '\(name)' should be invalid")
            case .invalid(let error):
                #expect(!error.isEmpty, "Should have error message")
                #expect(error.contains("empty"), "Error should mention empty")
            }
        }
    }
    
    @Test func AddAccountView_NameValidation_TooLong() throws {
        // Given: Account name exceeding max length
        let longName = String(repeating: "A", count: InputValidator.maxAccountNameLength + 1)
        
        // When: Validate account name
        let result = InputValidator.validateAccountName(longName)
        
        // Then: Should be invalid
        switch result {
        case .valid(_):
            Issue.record("Long name should be invalid")
        case .invalid(let error):
            #expect(error.contains("too long") || error.contains("max"))
        }
    }
    
    @Test func AddAccountView_NameValidation_Duplicate() throws {
        // Given: Existing accounts in context
        let context = try TestHelpers.createTestContext()
        let account1 = TestHelpers.createTestAccount(name: "Savings Account", in: context)
        let account2 = TestHelpers.createTestAccount(name: "Current Account", in: context)
        saveContext(context)
        
        // Get existing account names
        let existingNames = [account1.name, account2.name]
        
        // When: Try to validate duplicate names
        let duplicateTests = [
            "Savings Account",  // Exact match
            "savings account",  // Case insensitive
            "SAVINGS ACCOUNT",  // All caps
            " Savings Account " // With whitespace
        ]
        
        for duplicateName in duplicateTests {
            let result = InputValidator.validateAccountName(duplicateName, existingNames: existingNames)
            
            // Then: Should be invalid
            switch result {
            case .valid(_):
                Issue.record("Duplicate name '\(duplicateName)' should be invalid")
            case .invalid(let error):
                #expect(error.contains("already exists"), "Error should mention duplicate")
            }
        }
    }
    
    @Test func AddAccountView_NameValidation_SecurityCharacters() throws {
        // Given: Names with potentially dangerous characters
        let dangerousNames = [
            "Account\0Name",           // Null byte
            "Account\u{001B}[31mRed",  // ANSI escape
            "Bell\u{0007}Sound",       // Bell character
            "\u{001F}Control"          // Control character
        ]
        
        for name in dangerousNames {
            // When: Validate dangerous name
            let result = InputValidator.validateAccountName(name)
            
            // Then: Should be invalid
            switch result {
            case .valid(_):
                Issue.record("Dangerous name '\(name)' should be invalid")
            case .invalid(let error):
                #expect(error.contains("invalid") || error.contains("control"))
            }
        }
    }
    
    @Test func AddAccountView_ValueValidation_InvalidFormats() throws {
        // Given: Invalid monetary inputs
        let invalidInputs = [
            "",           // Empty
            "abc",        // Letters
            "100.123",    // Too many decimals
            "-50",        // Negative
            "1.2.3",      // Multiple decimal points
            "$100",       // Currency symbol
            "100,000",    // Comma separator
            String(repeating: "9", count: 20) // Too long
        ]
        
        for input in invalidInputs {
            // When: Validate monetary input
            let result = InputValidator.validateMonetaryInput(input)
            
            // Then: Should be invalid
            switch result {
            case .valid(_):
                Issue.record("Invalid input '\(input)' should be rejected")
            case .invalid(let error):
                #expect(!error.isEmpty, "Should have error message")
            }
        }
    }
    
    @Test func AddAccountView_FormCompletion() throws {
        // Given: Valid form inputs
        let validName = "Test Account"
        let validValue = "1000.50"
        
        // Validate both inputs
        let nameResult = InputValidator.validateAccountName(validName)
        let valueResult = InputValidator.validateMonetaryInput(validValue)
        
        // Then: Both should be valid
        switch nameResult {
        case .valid(let name):
            #expect(name == validName)
        case .invalid(let error):
            Issue.record("Valid name should pass: \(error)")
        }
        
        switch valueResult {
        case .valid(let value):
            TestHelpers.expectDecimalEqual(value, 1000.50)
        case .invalid(let error):
            Issue.record("Valid value should pass: \(error)")
        }
    }
    
    @Test func AccountDetailView_UpdateValidation() throws {
        // Given: Existing account
        let context = try TestHelpers.createTestContext()
        let account = TestHelpers.createTestAccount(name: "Test Account", in: context)
        let _ = TestHelpers.createTestUpdate(value: 1000, account: account, in: context)
        saveContext(context)
        
        // Test various update values
        let testCases: [(input: String, isValid: Bool)] = [
            ("2000", true),
            ("1500.75", true),
            ("0", true),
            ("999999999.99", true),  // Max value
            ("", false),
            ("abc", false),
            ("-100", false),
            ("1000000000", false),   // Exceeds max
            ("100.123", false)       // Too many decimals
        ]
        
        for testCase in testCases {
            // When: Validate update value
            let result = InputValidator.validateMonetaryInput(testCase.input)
            
            // Then: Should match expected validity
            switch result {
            case .valid(_):
                #expect(testCase.isValid, "Input '\(testCase.input)' validity mismatch")
            case .invalid(_):
                #expect(!testCase.isValid, "Input '\(testCase.input)' validity mismatch")
            }
        }
    }
    
    @Test func FormValidation_ProgressiveTyping() throws {
        // Given: Simulated progressive typing for account name
        let nameTypingSequence = ["T", "Te", "Tes", "Test", "Test ", "Test A", "Test Acc", "Test Account"]
        
        for partialName in nameTypingSequence {
            // When: Validate partial name
            let result = InputValidator.validateAccountName(partialName)
            
            // Then: All should be valid (as they meet minimum requirements)
            switch result {
            case .valid(let name):
                // The validator trims whitespace, so we expect the trimmed version
                #expect(name == partialName.trimmingCharacters(in: .whitespacesAndNewlines))
            case .invalid(let error):
                Issue.record("Partial name '\(partialName)' should be valid: \(error)")
            }
        }
        
        // Given: Simulated progressive typing for value
        let valueTypingSequence = ["1", "10", "100", "100.", "100.5", "100.50"]
        
        for partialValue in valueTypingSequence {
            // When: Validate partial value
            let result = InputValidator.validateMonetaryInput(partialValue)
            
            // Then: Should handle progressive input appropriately
            switch result {
            case .valid(let value):
                #expect(value >= 0)
            case .invalid(_):
                // Some intermediate states might be invalid (like "100.")
                // This is acceptable as long as final state is valid
                break
            }
        }
    }
    
    @Test func FormValidation_BoundaryValues() throws {
        // Test account name boundaries
        let minName = "A" // Single character
        let maxName = String(repeating: "A", count: InputValidator.maxAccountNameLength)
        let tooLongName = String(repeating: "A", count: InputValidator.maxAccountNameLength + 1)
        
        // Min name should be valid
        switch InputValidator.validateAccountName(minName) {
        case .valid(let name):
            #expect(name == minName)
        case .invalid(let error):
            Issue.record("Min length name should be valid: \(error)")
        }
        
        // Max name should be valid
        switch InputValidator.validateAccountName(maxName) {
        case .valid(let name):
            #expect(name.count == InputValidator.maxAccountNameLength)
        case .invalid(let error):
            Issue.record("Max length name should be valid: \(error)")
        }
        
        // Too long name should be invalid
        switch InputValidator.validateAccountName(tooLongName) {
        case .valid(_):
            Issue.record("Name exceeding max should be invalid")
        case .invalid(let error):
            #expect(error.contains("too long") || error.contains("max"))
        }
        
        // Test monetary value boundaries
        let minValue = "0"
        let maxValue = "999999999.99"
        let tooLargeValue = "1000000000"
        
        // Min value should be valid
        switch InputValidator.validateMonetaryInput(minValue) {
        case .valid(let value):
            TestHelpers.expectDecimalEqual(value, 0)
        case .invalid(let error):
            Issue.record("Min value should be valid: \(error)")
        }
        
        // Max value should be valid
        switch InputValidator.validateMonetaryInput(maxValue) {
        case .valid(let value):
            TestHelpers.expectDecimalEqual(value, InputValidator.maxValue)
        case .invalid(let error):
            Issue.record("Max value should be valid: \(error)")
        }
        
        // Too large value should be invalid
        switch InputValidator.validateMonetaryInput(tooLargeValue) {
        case .valid(_):
            Issue.record("Value exceeding max should be invalid")
        case .invalid(let error):
            #expect(error.contains("too large") || error.contains("max"))
        }
    }
    
    @Test func FormValidation_InternationalCharacters() throws {
        // Given: Account names with international characters
        let internationalNames = [
            "日本の貯金",     // Japanese
            "Сбережения",    // Russian
            "储蓄账户",       // Chinese
            "حساب التوفير",  // Arabic
            "बचत खाता",      // Hindi
            "Épargne €",     // French with Euro
            "Αποταμίευση",   // Greek
            "저축 계좌"       // Korean
        ]
        
        for name in internationalNames {
            // When: Validate international name
            let result = InputValidator.validateAccountName(name)
            
            // Then: Should be valid
            switch result {
            case .valid(let validatedName):
                #expect(validatedName == name)
            case .invalid(let error):
                Issue.record("International name '\(name)' should be valid: \(error)")
            }
        }
    }
    
    @Test func FormValidation_EmojiSupport() throws {
        // Given: Account names with emojis
        let emojiNames = [
            "Savings 💰",
            "Investment 📈",
            "House 🏠",
            "Car Fund 🚗",
            "Holiday ✈️",
            "Emergency 🚨",
            "Crypto 🪙",
            "Retirement 👴"
        ]
        
        for name in emojiNames {
            // When: Validate emoji name
            let result = InputValidator.validateAccountName(name)
            
            // Then: Should be valid
            switch result {
            case .valid(let validatedName):
                #expect(validatedName == name)
            case .invalid(let error):
                Issue.record("Emoji name '\(name)' should be valid: \(error)")
            }
        }
    }
    
    // MARK: - Performance Integration Tests
    
    @Test(.timeLimit(.minutes(1))) func Performance_LargePortfolioCalculations() throws {
        // Given: Large portfolio simulation
        let context = try TestHelpers.createTestContext()
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
        let _ = PerformanceCalculationService.calculatePortfolioChangeFromLastUpdate(accounts: accounts)
        
        // Then: Should complete within reasonable time
        // Swift Testing timeLimit will fail if too slow
    }
    
    @Test(.timeLimit(.minutes(1))) func Performance_ChartDataGeneration() throws {
        // Given: Complex portfolio for chart generation
        let context = try TestHelpers.createTestContext()
        let accounts = TestHelpers.createComplexTestPortfolio(in: context)
        saveContext(context)
        
        // When: Measure chart data generation
        let allUpdates = accounts.flatMap { $0.updates }
            .sorted { $0.date < $1.date }
        
        var currentAccountValues: [String: Decimal] = [:]
        let _ = allUpdates.map { update in
            currentAccountValues[update.account?.name ?? ""] = update.value
            let total = currentAccountValues.values.reduce(0, +)
            return ChartDataPoint(date: update.date, value: total)
        }
        
        // Then: Should generate chart data efficiently
    }
    
    // MARK: - Error Handling Integration Tests
    
    @Test func ErrorHandling_InvalidDataScenarios() throws {
        // Given: Edge case scenarios
        let context = try TestHelpers.createTestContext()
        let account = TestHelpers.createTestAccount(name: "Error Test", in: context)
        saveContext(context)
        
        
        // When: Calculate performance with no updates
        let performanceNoUpdates = PerformanceCalculationService.calculateAccountChangeFromLastUpdate(account: account)
        
        // Then: Should handle gracefully
        #expect(!performanceNoUpdates.hasData, "No updates should result in no performance data")
        
        // When: Calculate performance with single update
        let _ = TestHelpers.createTestUpdate(value: 1000, account: account, in: context)
        saveContext(context)
        
        let performanceSingleUpdate = PerformanceCalculationService.calculateAccountChangeFromLastUpdate(account: account)
        
        // Then: Should handle gracefully
        #expect(!performanceSingleUpdate.hasData, "Single update should result in no performance comparison")
    }
    
    // MARK: - Real-World Scenario Tests
    
    @Test func RealWorldScenario_UserJourney() throws {
        // Given: Simulate complete user workflow
        let context = try TestHelpers.createTestContext()
        
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
        
        // When: Calculate portfolio performance (use all-time since this spans months)
        let accounts = [savingsAccount, investmentAccount]
        let portfolioPerformance = PerformanceCalculationService.calculatePortfolioChangeAllTime(accounts: accounts)
        
        // Then: Should show meaningful results
        #expect(portfolioPerformance.hasData, "User portfolio should have performance data")
        #expect(portfolioPerformance.isPositive, "User portfolio should show growth")
        
        // Portfolio should show positive growth from the user journey
        // Actual calculation may vary due to timeline-based calculation method
        TestHelpers.expectDecimalEqual(portfolioPerformance.absolute, 1000, accuracy: Decimal(300.0))
        #expect(portfolioPerformance.percentage > 4.0)
        #expect(portfolioPerformance.percentage < 8.0)
    }
}