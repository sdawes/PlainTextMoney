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
        print("✅ Generated historical updates")
        
        // Ensure complete snapshot coverage for all accounts
        print("🔄 Ensuring complete snapshot coverage...")
        for account in accounts {
            SnapshotService.ensureCompleteSnapshotCoverage(for: account, modelContext: modelContext)
        }
        print("✅ Complete snapshot coverage ensured")
        
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
        
        try? modelContext.save()
    }
    
    private static func createTestAccounts(modelContext: ModelContext) -> [Account] {
        let accountData: [(String, Decimal)] = [
            ("ISA Savings", 5000),
            ("Pension Fund", 45000),
            ("Emergency Fund", 3000),
            ("Investment Account", 8000),
            ("House Deposit", 15000),
            ("Crypto Portfolio", 2000)
        ]
        
        var accounts: [Account] = []
        
        for (name, initialValue) in accountData {
            let account = Account(name: name)
            
            // Set creation date to 2 years ago
            let calendar = Calendar.current
            account.createdAt = calendar.date(byAdding: .year, value: -2, to: Date()) ?? Date()
            
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
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        let endDate = Date()
        
        // Generate updates every 2 weeks for each account
        var currentDate = startDate
        
        while currentDate < endDate {
            for (index, account) in accounts.enumerated() {
                // Skip some updates randomly to make it more realistic
                if Bool.random() && Double.random(in: 0...1) > 0.8 {
                    continue
                }
                
                let newValue = calculateNextValue(for: account, at: currentDate, accountIndex: index)
                
                let update = AccountUpdate(value: newValue, account: account)
                update.date = currentDate.addingTimeInterval(Double.random(in: 0...86400)) // Random time during the day
                modelContext.insert(update)
                
                // Create snapshot for this update
                SnapshotService.updateAccountSnapshot(for: account, value: newValue, date: update.date, modelContext: modelContext)
            }
            
            // Move to next update period (roughly 2 weeks)
            currentDate = calendar.date(byAdding: .day, value: Int.random(in: 12...16), to: currentDate) ?? currentDate
        }
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