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
        print("Generating Test Data Set 1...")
        generateTestDataSet(.set1, modelContext: modelContext)
    }
    
    static func generateTestDataSet2(modelContext: ModelContext) {
        print("Generating Test Data Set 2...")
        generateTestDataSet(.set2, modelContext: modelContext)
    }
    
    static func generateTestDataSet3(modelContext: ModelContext) {
        print("Generating Test Data Set 3...")
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
        case set1  // Personal finance data (8 accounts, 5 dates)
        case set2  // Performance test data (8 accounts, 5 years, ~4000 updates)
        case set3  // Simple monthly pattern (2 accounts, £100/month for 6 months)
    }
    
    private static func generateTestDataSet(_ dataSet: TestDataSet, modelContext: ModelContext) {
        clearAllData(modelContext: modelContext)
        
        let accounts: [Account]
        switch dataSet {
        case .set1:
            accounts = createSet1Accounts(modelContext: modelContext)
            generateSet1Updates(for: accounts, modelContext: modelContext)
        case .set2:
            accounts = createSet2Accounts(modelContext: modelContext)
            generateSet2Updates(for: accounts, modelContext: modelContext)
        case .set3:
            accounts = createSet3Accounts(modelContext: modelContext)
            generateSet3Updates(for: accounts, modelContext: modelContext)
        }
        
        // Save context
        try? modelContext.save()
        
        let totalUpdates = accounts.reduce(0) { $0 + $1.updates.count }
        print("Test data generation complete: \(accounts.count) accounts, \(totalUpdates) updates")
        
        if dataSet == .set2 {
            print("Performance test data: ~\(totalUpdates / accounts.count) updates per account")
        }
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
            ("HL GSIPP", calendar.date(from: DateComponents(year: 2025, month: 5, day: 1)) ?? Date()),
            ("T212 Invest", calendar.date(from: DateComponents(year: 2025, month: 8, day: 1)) ?? Date())
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
                6: 77570,  // HL GSIPP
                7: 100     // T212 Invest
            ]
        ]
        
        // Generate updates for each date
        for (date, accountValues) in personalData.sorted(by: { $0.key < $1.key }) {
            var accountsProcessedToday = 0
            
            for (accountIndex, value) in accountValues {
                if accountIndex < accounts.count {
                    let account = accounts[accountIndex]
                    
                    // Only create update if value changed from previous or it's the first update
                    let latestUpdate = account.updates.sorted { $0.date < $1.date }.last
                    let shouldCreateUpdate = account.updates.isEmpty || latestUpdate?.value != value
                    
                    if shouldCreateUpdate {
                        let update = AccountUpdate(value: value, account: account)
                        
                        // Calculate timestamp based on whether this is initial update or subsequent
                        let isInitialUpdate = account.updates.isEmpty
                        let isT212Invest = account.name == "T212 Invest"
                        
                        if isInitialUpdate {
                            if isT212Invest {
                                // T212 Invest gets its own time on its creation date (08/01/2025)
                                update.date = date.addingTimeInterval(10 * 3600 + 30 * 60) // 10:30 AM
                            } else {
                                // Initial updates for accounts created on 05/01/2025 are staggered
                                let minutesOffset = TimeInterval(accountIndex * 2 * 60) // Stagger by 2 minutes each
                                update.date = date.addingTimeInterval(9 * 3600 + minutesOffset) // Start at 09:00 AM
                            }
                        } else {
                            // Subsequent updates get varied realistic times throughout the day
                            let randomHour = Int.random(in: 8...20) // Between 8 AM and 8 PM
                            let randomMinute = Int.random(in: 0...59)
                            let randomSecond = Int.random(in: 0...59)
                            let timeOffset = randomHour * 3600 + randomMinute * 60 + randomSecond
                            update.date = date.addingTimeInterval(TimeInterval(timeOffset))
                        }
                        
                        modelContext.insert(update)
                        accountsProcessedToday += 1
                    }
                }
            }
        }
    }
    
    // MARK: - Test Data Set 2 (Large Historic Data - Performance Testing)
    
    private static func createSet2Accounts(modelContext: ModelContext) -> [Account] {
        let accountData: [(String, Decimal, Int)] = [
            ("ISA Savings", 5000, -60),           // 5 years ago
            ("Pension Fund", 45000, -60),         // 5 years ago  
            ("Emergency Fund", 3000, -60),        // 5 years ago
            ("Investment Account", 8000, -60),    // 5 years ago
            ("House Deposit", 15000, -60),        // 5 years ago
            ("Crypto Portfolio", 2000, -60),      // 5 years ago
            ("Premium Bonds", 10000, -60),        // 5 years ago
            ("Company Shares", 12000, -60)        // 5 years ago
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
        
        for (name, _, monthsAgo) in accountData {
            let account = Account(name: name)
            
            // Set creation date to 6 months ago
            let creationDate = calendar.date(byAdding: .month, value: monthsAgo, to: Date()) ?? Date()
            account.createdAt = calendar.startOfDay(for: creationDate)
            
            modelContext.insert(account)
            accounts.append(account)
            
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
        
        var currentDate = startDate
        var updateCount = 0
        
        // Generate approximately 2 updates per week for 5 years (realistic heavy usage)
        // ~104 updates per year * 5 years = ~520 updates per account
        while currentDate < endDate {
            // Generate 2 updates for this week
            for updateInWeek in 0..<2 {
                // Random day within the week
                let dayOffset = Int.random(in: 0...6) // 0-6 days from start of week
                
                if let updateDate = calendar.date(byAdding: .day, value: dayOffset, to: currentDate) {
                    if updateDate < endDate {
                        let newValue = calculateNextValue(for: account, at: updateDate, accountIndex: accountIndex)
                        
                        let update = AccountUpdate(value: newValue, account: account)
                        // Random time during the day (9 AM to 8 PM)
                        let hourOffset = Double.random(in: 9...20)
                        let minuteOffset = Double.random(in: 0...59)
                        update.date = updateDate.addingTimeInterval(hourOffset * 3600 + minuteOffset * 60)
                        modelContext.insert(update)
                        updateCount += 1
                    }
                }
            }
            
            // Move to next week
            currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate) ?? currentDate
        }
        
        print("Generated \(updateCount) updates for \(account.name)")
    }
    
    private static func generateAccount1Pattern(for account: Account, modelContext: ModelContext) {
        let calendar = Calendar.current
        let startDate = account.createdAt
        let endDate = Date()
        
        
        var currentValue: Decimal = 0 // Starting at £0
        var updateCount = 0
        
        // Start from the month after account creation
        let currentMonth = calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        
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
                    
                }
            }
        }
        
    }
    
    private static func generateAccount2Pattern(for account: Account, modelContext: ModelContext) {
        let calendar = Calendar.current
        let startDate = account.createdAt
        let endDate = Date()
        
        
        var currentValue: Decimal = 0 // Starting at £0
        var updateCount = 0
        
        // Start from the month after account creation
        let currentMonth = calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        
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
                    
                }
            }
        }
        
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
            
        case 6: // Premium Bonds - Stable with occasional prizes
            return Bool.random() && Double.random(in: 0...1) > 0.9 ? Double.random(in: 0.5...2.0) : 0.0
            
        case 7: // Company Shares - Follows market trends with dividends
            let marketTrend = sin(Double(date.timeIntervalSince1970) / (86400 * 365)) * 2.0
            return marketTrend + Double.random(in: -3.0...3.0)
            
        default:
            return Double.random(in: -1.0...2.0)
        }
    }
    
}
#endif

