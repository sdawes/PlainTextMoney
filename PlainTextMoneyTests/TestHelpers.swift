//
//  TestHelpers.swift
//  PlainTextMoneyTests
//
//  Created by Claude on 10/08/2025.
//

import XCTest
import SwiftData
import Foundation
@testable import PlainTextMoney

/// Helper utilities for testing SwiftData models and services
@MainActor
class TestHelpers {
    
    // MARK: - In-Memory Container Setup
    
    /// Creates an in-memory SwiftData container for testing
    /// Each test gets a clean, isolated database
    static func createTestContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Account.self, AccountUpdate.self,
            configurations: config
        )
    }
    
    /// Creates a ModelContext from a test container
    static func createTestContext() throws -> ModelContext {
        let container = try createTestContainer()
        return ModelContext(container)
    }
    
    // MARK: - Test Data Factory
    
    /// Creates a test account with predictable data
    static func createTestAccount(
        name: String = "Test Account",
        createdAt: Date = Date(),
        isActive: Bool = true,
        in context: ModelContext
    ) -> Account {
        let account = Account(name: name)
        account.createdAt = createdAt
        account.isActive = isActive
        
        context.insert(account)
        return account
    }
    
    /// Creates a test account update
    static func createTestUpdate(
        value: Decimal,
        date: Date = Date(),
        account: Account,
        in context: ModelContext
    ) -> AccountUpdate {
        let update = AccountUpdate(value: value, account: account)
        update.date = date
        
        context.insert(update)
        return update
    }
    
    /// Creates a simple test portfolio with known values for testing
    /// Returns (accounts: [Account], expectedTotal: Decimal)
    static func createTestPortfolio(in context: ModelContext) -> (accounts: [Account], expectedTotal: Decimal) {
        let calendar = Calendar.current
        let baseDate = Date()
        
        // Account 1: £1000 -> £1200 (£200 gain)
        let account1 = createTestAccount(name: "Account 1", in: context)
        let _ = createTestUpdate(
            value: 1000,
            date: calendar.date(byAdding: .day, value: -2, to: baseDate)!,
            account: account1,
            in: context
        )
        let _ = createTestUpdate(
            value: 1200,
            date: calendar.date(byAdding: .day, value: -1, to: baseDate)!,
            account: account1,
            in: context
        )
        
        // Account 2: £500 -> £450 (£50 loss)
        let account2 = createTestAccount(name: "Account 2", in: context)
        let _ = createTestUpdate(
            value: 500,
            date: calendar.date(byAdding: .day, value: -2, to: baseDate)!,
            account: account2,
            in: context
        )
        let _ = createTestUpdate(
            value: 450,
            date: calendar.date(byAdding: .day, value: -1, to: baseDate)!,
            account: account2,
            in: context
        )
        
        let accounts = [account1, account2]
        let expectedTotal: Decimal = 1200 + 450 // Current values
        
        return (accounts: accounts, expectedTotal: expectedTotal)
    }
    
    /// Creates a complex test portfolio for advanced scenarios
    static func createComplexTestPortfolio(in context: ModelContext) -> [Account] {
        let calendar = Calendar.current
        let baseDate = Date()
        
        var accounts: [Account] = []
        
        // Account with multiple updates over time
        let account1 = createTestAccount(name: "Growth Account", in: context)
        for i in 0..<5 {
            let value = Decimal(1000 + (i * 100)) // 1000, 1100, 1200, 1300, 1400
            let date = calendar.date(byAdding: .day, value: -i, to: baseDate)!
            let _ = createTestUpdate(value: value, date: date, account: account1, in: context)
        }
        accounts.append(account1)
        
        // Account with declining value
        let account2 = createTestAccount(name: "Decline Account", in: context)
        for i in 0..<3 {
            let value = Decimal(2000 - (i * 200)) // 2000, 1800, 1600
            let date = calendar.date(byAdding: .day, value: -i, to: baseDate)!
            let _ = createTestUpdate(value: value, date: date, account: account2, in: context)
        }
        accounts.append(account2)
        
        // Account with single update (edge case)
        let account3 = createTestAccount(name: "Single Update", in: context)
        let _ = createTestUpdate(
            value: 500,
            date: calendar.date(byAdding: .day, value: -1, to: baseDate)!,
            account: account3,
            in: context
        )
        accounts.append(account3)
        
        return accounts
    }
    
    // MARK: - Assertion Helpers
    
    /// Asserts that two Decimal values are approximately equal (for financial calculations)
    static func assertDecimalEqual(
        _ actual: Decimal,
        _ expected: Decimal,
        accuracy: Decimal = 0.01,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let difference = abs(actual - expected)
        XCTAssertLessThanOrEqual(
            difference,
            accuracy,
            "Expected \\(expected), but got \\(actual). Difference: \\(difference)",
            file: file,
            line: line
        )
    }
    
    /// Asserts that a percentage is approximately correct
    static func assertPercentageEqual(
        _ actual: Double,
        _ expected: Double,
        accuracy: Double = 0.1,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            actual,
            expected,
            accuracy: accuracy,
            "Expected \\(expected)%, but got \\(actual)%",
            file: file,
            line: line
        )
    }
    
    // MARK: - Date Helpers
    
    /// Creates a date with specific components for testing
    static func createDate(year: Int, month: Int, day: Int, hour: Int = 12) -> Date {
        let calendar = Calendar.current
        let components = DateComponents(year: year, month: month, day: day, hour: hour)
        return calendar.date(from: components) ?? Date()
    }
    
    /// Creates dates for time period testing
    static func createTestDates() -> (oneMonthAgo: Date, oneYearAgo: Date, twoYearsAgo: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        return (
            oneMonthAgo: calendar.date(byAdding: .month, value: -1, to: now) ?? now,
            oneYearAgo: calendar.date(byAdding: .year, value: -1, to: now) ?? now,
            twoYearsAgo: calendar.date(byAdding: .year, value: -2, to: now) ?? now
        )
    }
}

// MARK: - Test Extensions

extension XCTestCase {
    /// Convenience method to create a test context
    @MainActor
    func createTestContext() throws -> ModelContext {
        try TestHelpers.createTestContext()
    }
    
    /// Convenience method to save and catch errors
    @MainActor
    func saveContext(_ context: ModelContext, file: StaticString = #file, line: UInt = #line) {
        do {
            try context.save()
        } catch {
            XCTFail("Failed to save context: \\(error)", file: file, line: line)
        }
    }
}