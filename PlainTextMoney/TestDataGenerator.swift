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
    
    // MARK: - Public Interface
    
    static func generateTestDataSet1(modelContext: ModelContext) {
        print("🚀 Generating Test Data Set 1 (Personal Finance Data)...")
        print("📊 PERFORMANCE TEST: Using update-only chart architecture")
        generateTestDataSet(.set1, modelContext: modelContext)
    }
    
    static func generateTestDataSet2(modelContext: ModelContext) {
        print("🚀 Generating Test Data Set 2 (Large Historic Data)...")
        generateTestDataSet(.set2, modelContext: modelContext)
    }
    
    static func generateTestDataSet3(modelContext: ModelContext) {
        print("🚀 Generating Test Data Set 3 (Simple Pattern Data)...")
        generateTestDataSet(.set3, modelContext: modelContext)
    }
    
    // Legacy method for backwards compatibility
    static func generateTestData(modelContext: ModelContext) {
        generateTestDataSet2(modelContext: modelContext)
    }
    
    static func clearAllData(modelContext: ModelContext) {
        // Fetch and delete all accounts (updates will cascade delete)
        let accountDescriptor = FetchDescriptor<Account>()
        if let accounts = try? modelContext.fetch(accountDescriptor) {
            for account in accounts {
                modelContext.delete(account)
            }
        }
        
        try? modelContext.save()
    }
    
    // MARK: - Test Data Sets
    
    enum TestDataSet {
        case set1  // Personal finance data (7 accounts, 5 dates)
        case set2  // Large historic data (6 accounts, 2 years)
        case set3  // Simple monthly pattern (2 accounts, £100/month for 6 months)
    }
    
    private static func generateTestDataSet(_ dataSet: TestDataSet, modelContext: ModelContext) {
        clearAllData(modelContext: modelContext)
        
        let accounts: [Account]
        switch dataSet {
        case .set1:
            accounts = createSet1Accounts(modelContext: modelContext)
            print("✅ Created \(accounts.count) Set 1 accounts (personal finance data)")
            generateSet1Updates(for: accounts, modelContext: modelContext)
            print("✅ Generated Set 1 updates")
        case .set2:
            accounts = createSet2Accounts(modelContext: modelContext)
            print("✅ Created \(accounts.count) Set 2 accounts (large historic data)")
            generateSet2Updates(for: accounts, modelContext: modelContext)
            print("✅ Generated Set 2 historical updates")
        case .set3:
            accounts = createSet3Accounts(modelContext: modelContext)
            print("✅ Created \(accounts.count) Set 3 accounts (simple patterns)")
            generateSet3Updates(for: accounts, modelContext: modelContext)
            print("✅ Generated Set 3 pattern updates")
        }
        
        // UPDATE-ONLY ARCHITECTURE: No snapshot generation needed!
        print("✅ Using update-only charts - no snapshot generation required")
        
        // Save context
        try? modelContext.save()
        print("✅ Saved to database")
        
        // Show final summary
        print("\n📊 Test Data Summary:")
        for account in accounts {
            print("   \(account.name): \(account.updates.count) updates")
        }
        let totalUpdates = accounts.reduce(0) { $0 + $1.updates.count }
        print("   Total updates: \(totalUpdates)")
        print("🎉 Test data generation complete - Update-only architecture!\n")
    }
    
    // MARK: - Test Data Set 1 (Personal Finance Data)
    
    private static func createSet1Accounts(modelContext: ModelContext) -> [Account] {
        let calendar = Calendar.current
        var accounts: [Account] = []
        
        // Create accounts with specific creation dates
        let accountData: [(String, Date)] = [
            ("Monzo Cash ISA", calendar.date(from: DateComponents(year: 2025, month: 5, day: 1)) ?? Date()),
            ("Monzo Savings", calendar.date(from: DateComponents(year: 2025, month: 5, day: 1)) ?? Date()),
            ("T212 Cash ISA", calendar.date(from: DateComponents(year: 2025, month: 5, day: 1)) ?? Date()),
            ("T212 Stocks ISA", calendar.date(from: DateComponents(year: 2025, month: 5, day: 1)) ?? Date()),
            ("HL Active Savings", calendar.date(from: DateComponents(year: 2025, month: 5, day: 1)) ?? Date()),
            ("HL S&S ISA", calendar.date(from: DateComponents(year: 2025, month: 5, day: 1)) ?? Date()),
            ("HL GSIPP", calendar.date(from: DateComponents(year: 2025, month: 5, day: 1)) ?? Date())
        ]
        
        for (name, createdAt) in accountData {
            let account = Account(name: name)
            account.createdAt = createdAt
            modelContext.insert(account)
            accounts.append(account)
        }
        
        return accounts
    }
    
    private static func generateSet1Updates(for accounts: [Account], modelContext: ModelContext) {
        let calendar = Calendar.current
        
        // Data structure: [Date: [Account Index: Value]]
        let personalData: [Date: [Int: Decimal]] = [
            // 01/05/2025
            calendar.date(from: DateComponents(year: 2025, month: 5, day: 1)) ?? Date(): [
                0: 18503,  // Monzo Cash ISA
                1: 59134,  // Monzo Savings
                2: 21763,  // T212 Cash ISA
                3: 3695,   // T212 S&S ISA
                4: 44620,  // HL Active Savings
                5: 11827,  // HL S&S ISA
                6: 68048   // HL GSIPP
            ],
            // 01/06/2025
            calendar.date(from: DateComponents(year: 2025, month: 6, day: 1)) ?? Date(): [
                0: 18564,  // Monzo Cash ISA
                1: 59329,  // Monzo Savings
                2: 21846,  // T212 Cash ISA
                3: 4231,   // T212 S&S ISA
                4: 44776,  // HL Active Savings
                5: 12045,  // HL S&S ISA
                6: 70900   // HL GSIPP
            ],
            // 26/06/2025
            calendar.date(from: DateComponents(year: 2025, month: 6, day: 26)) ?? Date(): [
                0: 18564,  // Monzo Cash ISA (unchanged)
                1: 53924,  // Monzo Savings
                2: 21903,  // T212 Cash ISA
                3: 4286,   // T212 S&S ISA
                4: 44776,  // HL Active Savings (unchanged)
                5: 12243,  // HL S&S ISA
                6: 71838   // HL GSIPP
            ],
            // 18/07/2025
            calendar.date(from: DateComponents(year: 2025, month: 7, day: 18)) ?? Date(): [
                0: 18619,  // Monzo Cash ISA
                1: 38097,  // Monzo Savings
                2: 21956,  // T212 Cash ISA
                3: 20538,  // T212 S&S ISA
                4: 44918,  // HL Active Savings
                5: 12426,  // HL S&S ISA
                6: 75075   // HL GSIPP
            ],
            // 22/07/2025
            calendar.date(from: DateComponents(year: 2025, month: 7, day: 22)) ?? Date(): [
                0: 18619,  // Monzo Cash ISA (unchanged)
                1: 38097,  // Monzo Savings (unchanged)
                2: 21966,  // T212 Cash ISA
                3: 20529,  // T212 S&S ISA
                4: 44918,  // HL Active Savings (unchanged)
                5: 12468,  // HL S&S ISA
                6: 75229   // HL GSIPP
            ],
            // 01/08/2025
            calendar.date(from: DateComponents(year: 2025, month: 8, day: 1)) ?? Date(): [
                0: 18669,  // Monzo Cash ISA
                1: 38194,  // Monzo Savings
                2: 21990,  // T212 Cash ISA
                3: 20612,  // T212 S&S ISA
                4: 45107,  // HL Active Savings
                5: 12520,  // HL S&S ISA
                6: 77570   // HL GSIPP
            ]
        ]
        
        // Generate updates for each date
        for (date, accountValues) in personalData.sorted(by: { $0.key < $1.key }) {
            for (accountIndex, value) in accountValues {
                if accountIndex < accounts.count {
                    let account = accounts[accountIndex]
                    
                    // Only create update if value changed from previous or it's the first update
                    let latestUpdate = account.updates.sorted { $0.date < $1.date }.last
                    let shouldCreateUpdate = account.updates.isEmpty || latestUpdate?.value != value
                    
                    if shouldCreateUpdate {
                        let update = AccountUpdate(value: value, account: account)
                        update.date = date.addingTimeInterval(8 * 3600) // Set to 08:00 (8 AM)
                        modelContext.insert(update)
                        
                        print("   \(account.name): \(date.formatted(date: .abbreviated, time: .omitted)) = £\(value)")
                    }
                }
            }
        }
    }
    
    // MARK: - Test Data Set 2 (Large Historic Data)
    
    private static func createSet2Accounts(modelContext: ModelContext) -> [Account] {
        let accountData: [(String, Decimal, Int)] = [
            ("ISA Savings", 5000, -24),           // 2 years ago
            ("Pension Fund", 45000, -24),         // 2 years ago  
            ("Emergency Fund", 3000, -24),        // 2 years ago
            ("Investment Account", 8000, -24),    // 2 years ago
            ("House Deposit", 15000, -24),        // 2 years ago
            ("Crypto Portfolio", 2000, -24)       // 2 years ago
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
        }
        
        return accounts
    }
    
    private static func generateSet2Updates(for accounts: [Account], modelContext: ModelContext) {
        for (index, account) in accounts.enumerated() {
            generateRegularUpdates(for: account, accountIndex: index, modelContext: modelContext)
        }
    }
    
    // MARK: - Test Data Set 3 (Simple Pattern Data)
    
    private static func createSet3Accounts(modelContext: ModelContext) -> [Account] {
        let accountData: [(String, Decimal, Int)] = [
            ("Account 1 (1st of month)", 0, -6),    // 6 months ago, £100 on 1st of each month
            ("Account 2 (15th of month)", 0, -6)    // 6 months ago, £100 on 15th of each month
        ]
        
        var accounts: [Account] = []
        let calendar = Calendar.current
        
        for (name, initialValue, monthsAgo) in accountData {
            let account = Account(name: name)
            
            // Set creation date to 6 months ago
            let creationDate = calendar.date(byAdding: .month, value: monthsAgo, to: Date()) ?? Date()
            account.createdAt = calendar.startOfDay(for: creationDate)
            
            modelContext.insert(account)
            accounts.append(account)
            
            print("   Created \(name) on \(account.createdAt.formatted(date: .abbreviated, time: .omitted))")
        }
        
        return accounts
    }
    
    private static func generateSet3Updates(for accounts: [Account], modelContext: ModelContext) {
        for account in accounts {
            if account.name.contains("Account 1") {
                generateAccount1Pattern(for: account, modelContext: modelContext) // 1st of each month
            } else if account.name.contains("Account 2") {
                generateAccount2Pattern(for: account, modelContext: modelContext) // 15th of each month
            }
        }
    }
    
    // MARK: - Update Generation Methods
    
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
            
            // Move to next update period (roughly 2 weeks)
            currentDate = calendar.date(byAdding: .day, value: Int.random(in: 12...16), to: currentDate) ?? currentDate
        }
    }
    
    private static func generateAccount1Pattern(for account: Account, modelContext: ModelContext) {
        let calendar = Calendar.current
        let startDate = account.createdAt
        let endDate = Date()
        
        print("📋 Generating Account 1 pattern: £100 on 1st of each month for 6 months")
        
        var currentValue: Decimal = 0 // Starting at £0
        var updateCount = 0
        
        // Start from the month after account creation
        var currentMonth = calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        
        // Generate exactly 6 monthly updates
        for monthOffset in 0..<6 {
            let targetMonth = calendar.date(byAdding: .month, value: monthOffset, to: currentMonth) ?? currentMonth
            
            // Update on the 1st of the month
            if let firstOfMonth = calendar.date(bySetting: .day, value: 1, of: targetMonth) {
                if firstOfMonth <= endDate {
                    currentValue += 100 // Add £100
                    
                    let update = AccountUpdate(value: currentValue, account: account)
                    update.date = firstOfMonth.addingTimeInterval(10 * 3600) // 10 AM
                    modelContext.insert(update)
                    updateCount += 1
                    
                    print("   \(firstOfMonth.formatted(date: .abbreviated, time: .omitted)): £\(currentValue) (+£100)")
                }
            }
        }
        
        print("   Generated \(updateCount) updates for Account 1 (£100 each, total £\(currentValue))")
    }
    
    private static func generateAccount2Pattern(for account: Account, modelContext: ModelContext) {
        let calendar = Calendar.current
        let startDate = account.createdAt
        let endDate = Date()
        
        print("📋 Generating Account 2 pattern: £100 on 15th of each month for 6 months")
        
        var currentValue: Decimal = 0 // Starting at £0
        var updateCount = 0
        
        // Start from the month after account creation
        var currentMonth = calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        
        // Generate exactly 6 monthly updates
        for monthOffset in 0..<6 {
            let targetMonth = calendar.date(byAdding: .month, value: monthOffset, to: currentMonth) ?? currentMonth
            
            // Update on the 15th of the month
            if let fifteenthOfMonth = calendar.date(bySetting: .day, value: 15, of: targetMonth) {
                if fifteenthOfMonth <= endDate {
                    currentValue += 100 // Add £100
                    
                    let update = AccountUpdate(value: currentValue, account: account)
                    update.date = fifteenthOfMonth.addingTimeInterval(14 * 3600) // 2 PM
                    modelContext.insert(update)
                    updateCount += 1
                    
                    print("   \(fifteenthOfMonth.formatted(date: .abbreviated, time: .omitted)): £\(currentValue) (+£100)")
                }
            }
        }
        
        print("   Generated \(updateCount) updates for Account 2 (£100 each, total £\(currentValue))")
    }
    
    private static func calculateNextValue(for account: Account, at date: Date, accountIndex: Int) -> Decimal {
        // Get current value (chronologically latest update)
        let currentValue = account.updates
            .sorted { $0.date < $1.date }
            .last?.value ?? 0
        
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
