//
//  TestDataGenerator.swift
//  PlainTextMoney
//
//  Created by Stephen Dawes on 29/07/2025.
//

#if DEBUG
import SwiftData
import Foundation

class TestDataGenerator {
    
    static func generateTestData(modelContext: ModelContext) {
        print("🚀 Starting test data generation...")
        
        // Clear existing data first
        clearAllData(modelContext: modelContext)
        
        let accounts = createTestAccounts(modelContext: modelContext)
        print("✅ Created \(accounts.count) test accounts")
        
        generateHistoricalUpdates(for: accounts, modelContext: modelContext)
        print("✅ Generated historical updates for all accounts")
        
        // Ensure complete snapshot coverage for all accounts
        print("🔄 Ensuring complete snapshot coverage...")
        for account in accounts {
            SnapshotService.ensureCompleteSnapshotCoverage(for: account, modelContext: modelContext)
        }
        print("✅ Complete snapshot coverage ensured")
        
        // Ensure complete portfolio snapshot coverage
        print("🔄 Ensuring complete portfolio snapshot coverage...")
        SnapshotService.ensurePortfolioSnapshotCoverage(modelContext: modelContext)
        print("✅ Complete portfolio snapshot coverage ensured")
        
        // Save context
        try? modelContext.save()
        print("✅ Saved to database")
        
        // Comprehensive verification
        print("\n🔍 Verifying snapshot coverage...")
        let isComplete = SnapshotService.verifyAllAccountSnapshots(accounts: accounts)
        
        if isComplete {
            print("🎉 Test data generation complete - Perfect snapshot coverage!\n")
        } else {
            print("⚠️ Test data generation complete - Some snapshots may be missing\n")
        }
    }
    
    static func clearAllData(modelContext: ModelContext) {
        // Fetch and delete all accounts (updates and snapshots will cascade delete)
        let accountDescriptor = FetchDescriptor<Account>()
        if let accounts = try? modelContext.fetch(accountDescriptor) {
            for account in accounts {
                modelContext.delete(account)
            }
        }
        
        // Also clear any orphaned snapshots
        let snapshotDescriptor = FetchDescriptor<AccountSnapshot>()
        if let snapshots = try? modelContext.fetch(snapshotDescriptor) {
            for snapshot in snapshots {
                modelContext.delete(snapshot)
            }
        }
        
        // Clear all portfolio snapshots
        let portfolioDescriptor = FetchDescriptor<PortfolioSnapshot>()
        if let portfolioSnapshots = try? modelContext.fetch(portfolioDescriptor) {
            for snapshot in portfolioSnapshots {
                modelContext.delete(snapshot)
            }
        }
        
        try? modelContext.save()
    }
    
    private static func createTestAccounts(modelContext: ModelContext) -> [Account] {
        let accountData: [(String, Decimal, Int)] = [
            ("ISA Savings", 5000, -24),           // 2 years ago
            ("Pension Fund", 45000, -24),         // 2 years ago  
            ("Emergency Fund", 3000, -24),        // 2 years ago
            ("Investment Account", 8000, -24),    // 2 years ago
            ("House Deposit", 15000, -24),        // 2 years ago
            ("Crypto Portfolio", 2000, -24),      // 2 years ago
            ("Simple Growth", 1000, -6),          // 6 months ago, predictable pattern
            ("Minimal Updates", 800, -2)          // 2 months ago, only 2 updates
        ]
        
        var accounts: [Account] = []
        
        for (name, initialValue, monthsAgo) in accountData {
            let account = Account(name: name)
            
            // Set creation date
            let calendar = Calendar.current
            account.createdAt = calendar.date(byAdding: .month, value: monthsAgo, to: Date()) ?? Date()
            
            modelContext.insert(account)
            accounts.append(account)
            
            // Create initial update
            let initialUpdate = AccountUpdate(value: initialValue, account: account)
            initialUpdate.date = account.createdAt
            modelContext.insert(initialUpdate)
            
            // Create initial snapshot
            SnapshotService.updateAccountSnapshot(for: account, value: initialValue, date: account.createdAt, modelContext: modelContext)
        }
        
        return accounts
    }
    
    private static func generateHistoricalUpdates(for accounts: [Account], modelContext: ModelContext) {
        for (index, account) in accounts.enumerated() {
            if account.name == "Simple Growth" {
                generateSimpleGrowthPattern(for: account, modelContext: modelContext)
            } else if account.name == "Minimal Updates" {
                generateMinimalUpdates(for: account, modelContext: modelContext)
            } else {
                generateRegularUpdates(for: account, accountIndex: index, modelContext: modelContext)
            }
        }
    }
    
    private static func generateRegularUpdates(for account: Account, accountIndex: Int, modelContext: ModelContext) {
        let calendar = Calendar.current
        let startDate = account.createdAt
        let endDate = Date()
        
        // Generate updates every 2 weeks for regular accounts
        var currentDate = calendar.date(byAdding: .day, value: 14, to: startDate) ?? startDate
        
        while currentDate < endDate {
            // Skip some updates randomly to make it more realistic
            if Bool.random() && Double.random(in: 0...1) > 0.8 {
                currentDate = calendar.date(byAdding: .day, value: Int.random(in: 12...16), to: currentDate) ?? currentDate
                continue
            }
            
            let newValue = calculateNextValue(for: account, at: currentDate, accountIndex: accountIndex)
            
            let update = AccountUpdate(value: newValue, account: account)
            update.date = currentDate.addingTimeInterval(Double.random(in: 0...86400)) // Random time during the day
            modelContext.insert(update)
            
            // Create snapshot for this update
            SnapshotService.updateAccountSnapshot(for: account, value: newValue, date: update.date, modelContext: modelContext)
            
            // Move to next update period (roughly 2 weeks)
            currentDate = calendar.date(byAdding: .day, value: Int.random(in: 12...16), to: currentDate) ?? currentDate
        }
    }
    
    private static func generateSimpleGrowthPattern(for account: Account, modelContext: ModelContext) {
        let calendar = Calendar.current
        let startDate = account.createdAt
        let endDate = Date()
        
        print("📋 Generating simple growth pattern for \(account.name)")
        
        var currentValue: Decimal = 1000 // Starting value
        var updateCount = 0
        
        // Start from the month after account creation
        var currentMonth = calendar.date(byAdding: .month, value: 0, to: startDate) ?? startDate
        
        while currentMonth < endDate {
            // First update on the 1st of the month
            if let firstOfMonth = calendar.date(bySetting: .day, value: 1, of: currentMonth) {
                if firstOfMonth >= startDate && firstOfMonth <= endDate {
                    currentValue += 100 // Increase by £100
                    
                    let update = AccountUpdate(value: currentValue, account: account)
                    update.date = firstOfMonth.addingTimeInterval(10 * 3600) // 10 AM
                    modelContext.insert(update)
                    
                    SnapshotService.updateAccountSnapshot(for: account, value: currentValue, date: update.date, modelContext: modelContext)
                    updateCount += 1
                }
            }
            
            // Second update on the 15th of the month
            if let fifteenthOfMonth = calendar.date(bySetting: .day, value: 15, of: currentMonth) {
                if fifteenthOfMonth >= startDate && fifteenthOfMonth <= endDate {
                    currentValue += 50 // Increase by £50
                    
                    let update = AccountUpdate(value: currentValue, account: account)
                    update.date = fifteenthOfMonth.addingTimeInterval(14 * 3600) // 2 PM
                    modelContext.insert(update)
                    
                    SnapshotService.updateAccountSnapshot(for: account, value: currentValue, date: update.date, modelContext: modelContext)
                    updateCount += 1
                }
            }
            
            // Move to next month
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
        
        print("   Generated \(updateCount) predictable updates for Simple Growth")
    }
    
    private static func generateMinimalUpdates(for account: Account, modelContext: ModelContext) {
        let calendar = Calendar.current
        let startDate = account.createdAt
        
        print("📋 Generating minimal updates for \(account.name)")
        
        // Only add 2 updates over 2 months
        // First update after 3 weeks
        if let firstUpdate = calendar.date(byAdding: .day, value: 21, to: startDate) {
            let update1 = AccountUpdate(value: 1200, account: account) // +400
            update1.date = firstUpdate.addingTimeInterval(11 * 3600) // 11 AM
            modelContext.insert(update1)
            
            SnapshotService.updateAccountSnapshot(for: account, value: 1200, date: update1.date, modelContext: modelContext)
            print("   Update 1: \(firstUpdate.formatted(date: .abbreviated, time: .omitted)) - £1200")
        }
        
        // Second update after 6 weeks
        if let secondUpdate = calendar.date(byAdding: .day, value: 42, to: startDate) {
            let update2 = AccountUpdate(value: 1500, account: account) // +300
            update2.date = secondUpdate.addingTimeInterval(15 * 3600) // 3 PM
            modelContext.insert(update2)
            
            SnapshotService.updateAccountSnapshot(for: account, value: 1500, date: update2.date, modelContext: modelContext)
            print("   Update 2: \(secondUpdate.formatted(date: .abbreviated, time: .omitted)) - £1500")
        }
        
        print("   Generated 2 minimal updates")
    }
    
    private static func calculateNextValue(for account: Account, at date: Date, accountIndex: Int) -> Decimal {
        // Get current value (last update)
        let currentValue = account.updates.last?.value ?? 0
        
        // Different growth patterns for different accounts
        let growthPattern = getGrowthPattern(accountIndex: accountIndex, date: date)
        let changeAmount = currentValue * Decimal(growthPattern / 100.0)
        
        let newValue = max(0, currentValue + changeAmount)
        
        // Round to nearest pound
        return Decimal(Int(NSDecimalNumber(decimal: newValue).doubleValue))
    }
    
    private static func getGrowthPattern(accountIndex: Int, date: Date) -> Double {
        switch accountIndex {
        case 0: // ISA Savings - Steady growth with regular deposits
            return Double.random(in: 0.5...3.0)
            
        case 1: // Pension Fund - Slow but steady with market fluctuations
            let marketVolatility = Double.random(in: -2.0...3.0)
            return 0.3 + marketVolatility
            
        case 2: // Emergency Fund - Occasional deposits, mostly stable
            return Bool.random() ? Double.random(in: 0.0...5.0) : 0.0
            
        case 3: // Investment Account - More volatile, can go up or down
            return Double.random(in: -3.0...5.0)
            
        case 4: // House Deposit - Regular monthly additions
            return Double.random(in: 1.0...4.0)
            
        case 5: // Crypto Portfolio - Highly volatile
            return Double.random(in: -15.0...20.0)
            
        default:
            return Double.random(in: -1.0...2.0)
        }
    }
    
}
#endif