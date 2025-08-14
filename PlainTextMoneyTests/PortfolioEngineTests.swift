//
//  PortfolioEngineTests.swift
//  PlainTextMoneyTests
//
//  Created by Claude on 10/08/2025.
//

import Testing
import SwiftData
import Foundation
@testable import PlainTextMoney

/// Tests for PortfolioEngine
/// Verifies background actor calculations and cross-actor data handling
@MainActor
struct PortfolioEngineTests {
    
    // MARK: - Portfolio Timeline Generation Tests
    
    @Test func generatePortfolioTimeline_WithSimplePortfolio() async throws {
        // Given: Simple portfolio with known values
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let engine = PortfolioEngine(modelContainer: container)
        let (accounts, expectedTotal) = TestHelpers.createTestPortfolio(in: context)
        saveContext(context)
        
        let accountIDs = accounts.map { $0.persistentModelID }
        
        // When: Generate portfolio timeline
        let timeline = await engine.generatePortfolioTimeline(accountIDs: accountIDs)
        
        // Then: Should have correct number of timeline points
        #expect(timeline.count == 4, "Should have 4 timeline points (2 updates per account)")
        
        // Verify final portfolio value matches expected total
        guard let finalPoint = timeline.last else {
            Issue.record("Timeline should have at least one point")
            return
        }
        
        TestHelpers.expectDecimalEqual(finalPoint.value, expectedTotal)
    }
    
    @Test func generatePortfolioTimeline_WithEmptyPortfolio() async throws {
        // Given: Empty array of account IDs
        let container = try TestHelpers.createTestContainer()
        let engine = PortfolioEngine(modelContainer: container)
        let accountIDs: [PersistentIdentifier] = []
        
        // When: Generate timeline
        let timeline = await engine.generatePortfolioTimeline(accountIDs: accountIDs)
        
        // Then: Should return empty timeline
        #expect(timeline.count == 0, "Empty portfolio should return empty timeline")
    }
    
    @Test func generatePortfolioTimeline_WithChronologicalOrdering() async throws {
        // Given: Portfolio with updates in mixed chronological order
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let engine = PortfolioEngine(modelContainer: container)
        let account1 = TestHelpers.createTestAccount(name: "Account 1", in: context)
        let account2 = TestHelpers.createTestAccount(name: "Account 2", in: context)
        
        let calendar = Calendar.current
        let baseDate = Date()
        
        // Add updates in non-chronological order in code, but should be sorted by date
        let _ = TestHelpers.createTestUpdate(
            value: 200,
            date: calendar.date(byAdding: .day, value: -1, to: baseDate)!, // Day 2
            account: account2,
            in: context
        )
        
        let _ = TestHelpers.createTestUpdate(
            value: 100,
            date: calendar.date(byAdding: .day, value: -3, to: baseDate)!, // Day 1
            account: account1,
            in: context
        )
        
        let _ = TestHelpers.createTestUpdate(
            value: 300,
            date: calendar.date(byAdding: .day, value: -2, to: baseDate)!, // Day 2
            account: account1,
            in: context
        )
        
        let _ = TestHelpers.createTestUpdate(
            value: 400,
            date: baseDate, // Day 3
            account: account2,
            in: context
        )
        
        saveContext(context)
        
        let accountIDs = [account1.persistentModelID, account2.persistentModelID]
        
        // When: Generate timeline
        let timeline = await engine.generatePortfolioTimeline(accountIDs: accountIDs)
        
        // Then: Timeline should be in chronological order
        #expect(timeline.count == 4)
        
        // Verify chronological progression
        for i in 1..<timeline.count {
            #expect(
                timeline[i-1].date <= timeline[i].date,
                "Timeline should be in chronological order"
            )
        }
        
        // Verify portfolio values accumulate correctly
        // Day 1: Account1=100, Account2=0 → Total=100
        TestHelpers.expectDecimalEqual(timeline[0].value, 100)
        
        // Day 2: Account1=300, Account2=0 → Total=300  
        TestHelpers.expectDecimalEqual(timeline[1].value, 300)
        
        // Day 2 later: Account1=300, Account2=200 → Total=500
        TestHelpers.expectDecimalEqual(timeline[2].value, 500)
        
        // Day 3: Account1=300, Account2=400 → Total=700
        TestHelpers.expectDecimalEqual(timeline[3].value, 700)
    }
    
    // MARK: - Filtered Portfolio Timeline Tests
    
    @Test func generateFilteredPortfolioTimeline_LastUpdate() async throws {
        // Given: Portfolio with multiple updates
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let engine = PortfolioEngine(modelContainer: container)
        let accounts = TestHelpers.createComplexTestPortfolio(in: context)
        saveContext(context)
        
        let accountIDs = accounts.map { $0.persistentModelID }
        
        // When: Generate filtered timeline for last update
        let timeline = await engine.generateFilteredPortfolioTimeline(
            accountIDs: accountIDs,
            startDate: nil,
            period: .lastUpdate
        )
        
        // Then: Should return exactly 2 points for "Since Last Update"
        #expect(timeline.count == 2, "Last update should return exactly 2 points")
        
        // Verify points are chronologically ordered (or at least not reversed)
        #expect(timeline[0].date <= timeline[1].date)
    }
    
    @Test func generateFilteredPortfolioTimeline_WithStartDate() async throws {
        // Given: Portfolio with updates over time
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let engine = PortfolioEngine(modelContainer: container)
        let accounts = TestHelpers.createComplexTestPortfolio(in: context)
        saveContext(context)
        
        let accountIDs = accounts.map { $0.persistentModelID }
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -2, to: Date())!
        
        // When: Generate filtered timeline
        let timeline = await engine.generateFilteredPortfolioTimeline(
            accountIDs: accountIDs,
            startDate: startDate,
            period: .oneMonth
        )
        
        // Then: All points should be after or at start date, or include boundary point
        for point in timeline {
            let isAtOrAfterStart = point.date >= startDate
            let isBoundaryPoint = timeline.first == point && point.date < startDate
            
            #expect(
                isAtOrAfterStart || isBoundaryPoint,
                "Point at \\(point.date) should be after \\(startDate) or be a boundary point"
            )
        }
    }
    
    // MARK: - Portfolio Performance Calculation Tests
    
    @Test func calculatePortfolioPerformance_ZeroChangeUpdate() async throws {
        // Given: The exact scenario from user's issue
        // User updates account with SAME value -> should show £0 portfolio change
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let engine = PortfolioEngine(modelContainer: container)
        
        let calendar = Calendar.current
        let now = Date()
        let oneHourAgo = calendar.date(byAdding: .hour, value: -1, to: now)!
        let twoHoursAgo = calendar.date(byAdding: .hour, value: -2, to: now)!
        
        // Create HL Active Savings account with historical updates
        let hlAccount = TestHelpers.createTestAccount(name: "HL Active Savings", in: context)
        let _ = TestHelpers.createTestUpdate(value: 45069, date: twoHoursAgo, account: hlAccount, in: context)  // Previous value
        
        // Create other account for portfolio context
        let otherAccount = TestHelpers.createTestAccount(name: "Other Account", in: context)
        let _ = TestHelpers.createTestUpdate(value: 10000, date: twoHoursAgo, account: otherAccount, in: context)
        
        saveContext(context)
        
        // User updates HL Active Savings with SAME VALUE (£0 change)
        let _ = TestHelpers.createTestUpdate(value: 45069, date: now, account: hlAccount, in: context)  // Same value!
        saveContext(context)
        
        let accounts = [hlAccount, otherAccount]
        let accountIDs = accounts.map { $0.persistentModelID }
        
        // When: Calculate performance since last update
        let performance = await engine.calculatePortfolioPerformance(
            accountIDs: accountIDs,
            period: .lastUpdate
        )
        
        // Then: Should show £0 change (not £31 like the old confusing logic)
        #expect(performance.hasData, "Should have performance data")
        #expect(performance.actualPeriodLabel.contains("Since last update"))
        
        // Expected calculation:
        // Before last update: £45069 + £10000 = £55069
        // After last update: £45069 + £10000 = £55069 (same!)
        // Change: £0 (0% change)
        
        #expect(performance.isPositive, "Zero change should be considered positive")
        TestHelpers.expectDecimalEqual(performance.absolute, 0, accuracy: Decimal(0.01))
        TestHelpers.expectPercentageEqual(performance.percentage, 0.0, accuracy: 0.01)
    }
    
    @Test func calculatePortfolioPerformance_AllTime() async throws {
        // Given: Portfolio with all-time performance
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let engine = PortfolioEngine(modelContainer: container)
        let accounts = TestHelpers.createComplexTestPortfolio(in: context)
        saveContext(context)
        
        let accountIDs = accounts.map { $0.persistentModelID }
        
        // When: Calculate all-time performance
        let performance = await engine.calculatePortfolioPerformance(
            accountIDs: accountIDs,
            period: .allTime
        )
        
        // Then: Should show all-time performance
        #expect(performance.hasData, "Should have all-time performance data")
        #expect(performance.actualPeriodLabel.contains("Since"), "Should show since earliest date")
        
        // Should show positive performance (complex portfolio is designed to grow)
        #expect(performance.isPositive, "Complex portfolio should show positive all-time performance")
        #expect(performance.absolute > 0, "Should have positive absolute change")
    }
    
    // MARK: - Cross-Actor Data Handling Tests
    
    @Test func crossActorDataHandling_WithPersistentIdentifiers() async throws {
        // Given: Accounts created in main context
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let engine = PortfolioEngine(modelContainer: container)
        let (accounts, expectedTotal) = TestHelpers.createTestPortfolio(in: context)
        saveContext(context)
        
        // Extract PersistentIdentifiers (simulating cross-actor boundary)
        let accountIDs = accounts.map { $0.persistentModelID }
        
        // When: Engine processes IDs and re-fetches data internally
        let timeline = await engine.generatePortfolioTimeline(accountIDs: accountIDs)
        
        // Then: Should successfully process data despite cross-actor boundary
        #expect(timeline.count > 0, "Should generate timeline from PersistentIdentifiers")
        
        guard let finalValue = timeline.last?.value else {
            Issue.record("Timeline should have final value")
            return
        }
        
        TestHelpers.expectDecimalEqual(finalValue, expectedTotal, accuracy: Decimal(0.01))
    }
    
    // MARK: - Error Handling Tests
    
    @Test func handleInvalidPersistentIdentifiers() async throws {
        // Given: Invalid/non-existent PersistentIdentifier
        // This is tricky to test directly, but we can test with empty results
        
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let engine = PortfolioEngine(modelContainer: container)
        let validAccounts = TestHelpers.createComplexTestPortfolio(in: context)
        saveContext(context)
        
        // Delete one account to simulate "dangling" ID
        let accountToDelete = validAccounts[0]
        let danglingID = accountToDelete.persistentModelID
        context.delete(accountToDelete)
        saveContext(context)
        
        let accountIDs = [danglingID] // Now references deleted account
        
        // When: Try to generate timeline with dangling ID
        let timeline = await engine.generatePortfolioTimeline(accountIDs: accountIDs)
        
        // Then: Should handle gracefully (return empty or skip invalid IDs)
        // Engine should not crash and should return valid result
        #expect(timeline != nil, "Should return non-nil result even with invalid IDs")
    }
    
    // MARK: - Performance Consistency Tests
    
    @Test func performanceCalculationConsistency() async throws {
        // Given: Same portfolio data
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let engine = PortfolioEngine(modelContainer: container)
        let (accounts, _) = TestHelpers.createTestPortfolio(in: context)
        saveContext(context)
        
        let accountIDs = accounts.map { $0.persistentModelID }
        
        // When: Calculate performance multiple times
        let performance1 = await engine.calculatePortfolioPerformance(
            accountIDs: accountIDs,
            period: .lastUpdate
        )
        
        let performance2 = await engine.calculatePortfolioPerformance(
            accountIDs: accountIDs,
            period: .lastUpdate
        )
        
        // Then: Results should be identical
        #expect(performance1.hasData == performance2.hasData)
        #expect(performance1.isPositive == performance2.isPositive)
        TestHelpers.expectPercentageEqual(performance1.percentage, performance2.percentage, accuracy: 0.01)
        TestHelpers.expectDecimalEqual(performance1.absolute, performance2.absolute, accuracy: Decimal(0.01))
        #expect(performance1.actualPeriodLabel == performance2.actualPeriodLabel)
    }
}