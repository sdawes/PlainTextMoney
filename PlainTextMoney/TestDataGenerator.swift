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
        case set1  // Personal finance data (8 accounts, 8 dates)
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
            ("T212 Invest", calendar.date(from: DateComponents(year: 2025, month: 8, day: 14)) ?? Date())
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
                4: 45069,  // HL Active Savings
                5: 12520,  // HL S&S ISA
                6: 77570   // HL GSIPP
            ],
            // 14/08/2025
            calendar.date(from: DateComponents(year: 2025, month: 8, day: 14)) ?? Date(): [
                0: 18669,  // Monzo Cash ISA (unchanged)
                1: 37000,  // Monzo Savings
                2: 22021,  // T212 Cash ISA
                3: 20629,  // T212 S&S ISA
                4: 45069,  // HL Active Savings (unchanged)
                5: 12520,  // HL S&S ISA (unchanged)
                6: 77393,  // HL GSIPP
                7: 1102    // T212 Invest (first appearance)
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
                                // T212 Invest gets its own time on its creation date (14/08/2025)
                                update.date = date.addingTimeInterval(10 * 3600 + 30 * 60) // 10:30 AM
                            } else {
                                // Initial updates for accounts created on 01/05/2025 are staggered
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
    
    // MARK: - Test Data Set 2 (Realistic 5-Year UK Financial Portfolio)
    
    private static func createSet2Accounts(modelContext: ModelContext) -> [Account] {
        // Create accounts with realistic UK financial institutions
        // Portfolio designed to reach ~£500,000 with pension-heavy allocation
        let accountData: [(String, Int)] = [
            ("Aviva Workplace Pension", -60),      // Started 5 years ago
            ("Trading 212 Stocks ISA", -48),       // Started 4 years ago
            ("HL Active Savings", -36),            // Started 3 years ago
            ("Flagstone Savings", -30),            // Started 2.5 years ago
            ("HL Fund & Share Account", -42),      // Started 3.5 years ago
            ("Crypto Exchange", -24)               // Started 2 years ago
        ]
        
        var accounts: [Account] = []
        let calendar = Calendar.current
        let baseDate = Date()
        
        for (name, monthsAgo) in accountData {
            let account = Account(name: name)
            account.createdAt = calendar.date(byAdding: .month, value: monthsAgo, to: baseDate) ?? baseDate
            modelContext.insert(account)
            accounts.append(account)
        }
        
        return accounts
    }
    
    private static func generateSet2Updates(for accounts: [Account], modelContext: ModelContext) {
        let calendar = Calendar.current
        
        // Hard-coded realistic financial data over 5 years
        // 6 accounts: Aviva Pension, T212 ISA, HL Active Savings, Flagstone, HL Fund & Share, Crypto
        // Updates roughly twice per month for 5 years = ~120 dates
        
        // Create update dates and values
        // Target: ~£500k total, pension-heavy (~£320k pension, £180k other accounts)
        let updates: [(year: Int, month: Int, day: Int, values: [Decimal])] = [
            // 2020 - Starting values
            (2020, 1, 5, [50000, 0, 0, 0, 0, 0]),  // Only pension exists
            (2020, 1, 20, [50500, 0, 0, 0, 0, 0]),
            (2020, 2, 5, [51200, 0, 0, 0, 0, 0]),
            (2020, 2, 20, [51800, 0, 0, 0, 0, 0]),
            (2020, 3, 5, [52500, 0, 0, 0, 0, 0]),
            (2020, 3, 20, [53200, 0, 0, 0, 0, 0]),
            (2020, 4, 5, [54000, 0, 0, 0, 0, 0]),
            (2020, 4, 20, [54700, 0, 0, 0, 0, 0]),
            (2020, 5, 5, [55500, 0, 0, 0, 0, 0]),
            (2020, 5, 20, [56200, 0, 0, 0, 0, 0]),
            (2020, 6, 5, [57000, 0, 0, 0, 0, 0]),
            (2020, 6, 20, [57800, 0, 0, 0, 0, 0]),
            (2020, 7, 5, [58600, 0, 0, 0, 0, 0]),
            (2020, 7, 20, [59400, 0, 0, 0, 0, 0]),
            (2020, 8, 5, [60300, 0, 0, 0, 0, 0]),
            (2020, 8, 20, [61100, 0, 0, 0, 0, 0]),
            (2020, 9, 5, [62000, 0, 0, 0, 0, 0]),
            (2020, 9, 20, [62800, 0, 0, 0, 0, 0]),
            (2020, 10, 5, [63700, 0, 0, 0, 0, 0]),
            (2020, 10, 20, [64600, 0, 0, 0, 0, 0]),
            (2020, 11, 5, [65500, 0, 0, 0, 0, 0]),
            (2020, 11, 20, [66400, 0, 0, 0, 0, 0]),
            (2020, 12, 5, [67300, 0, 0, 0, 0, 0]),
            (2020, 12, 20, [68200, 0, 0, 0, 0, 0]),
            
            // 2021 - T212 ISA starts, HL Fund & Share starts mid-year
            (2021, 1, 5, [69200, 5000, 0, 0, 0, 0]),  // T212 ISA opens with £5k
            (2021, 1, 20, [70100, 5100, 0, 0, 0, 0]),
            (2021, 2, 5, [71100, 5200, 0, 0, 0, 0]),
            (2021, 2, 20, [72000, 5350, 0, 0, 0, 0]),
            (2021, 3, 5, [73000, 5500, 0, 0, 0, 0]),
            (2021, 3, 20, [74000, 5600, 0, 0, 0, 0]),
            (2021, 4, 5, [75000, 5750, 0, 0, 0, 0]),
            (2021, 4, 20, [76000, 5900, 0, 0, 0, 0]),
            (2021, 5, 5, [77100, 6100, 0, 0, 0, 0]),
            (2021, 5, 20, [78200, 6250, 0, 0, 0, 0]),
            (2021, 6, 5, [79300, 6400, 0, 0, 10000, 0]),  // HL Fund & Share opens
            (2021, 6, 20, [80400, 6600, 0, 0, 10200, 0]),
            (2021, 7, 5, [81500, 6800, 0, 0, 10400, 0]),
            (2021, 7, 20, [82700, 7000, 0, 0, 10600, 0]),
            (2021, 8, 5, [83900, 7200, 0, 0, 10800, 0]),
            (2021, 8, 20, [85100, 7400, 0, 0, 11000, 0]),
            (2021, 9, 5, [86300, 7600, 0, 0, 11200, 0]),
            (2021, 9, 20, [87500, 7800, 0, 0, 11400, 0]),
            (2021, 10, 5, [88700, 8000, 0, 0, 11600, 0]),
            (2021, 10, 20, [90000, 8200, 0, 0, 11800, 0]),
            (2021, 11, 5, [91300, 8400, 0, 0, 12000, 0]),
            (2021, 11, 20, [92600, 8600, 0, 0, 12200, 0]),
            (2021, 12, 5, [93900, 8800, 0, 0, 12400, 0]),
            (2021, 12, 20, [95200, 9000, 0, 0, 12600, 0]),
            
            // 2022 - HL Active Savings starts, Flagstone mid-year
            (2022, 1, 5, [96600, 9200, 15000, 0, 12800, 0]),  // HL Active Savings opens
            (2022, 1, 20, [98000, 9400, 15050, 0, 13000, 0]),
            (2022, 2, 5, [99400, 9600, 15100, 0, 13200, 0]),
            (2022, 2, 20, [100800, 9800, 15150, 0, 13400, 0]),
            (2022, 3, 5, [102200, 10000, 15200, 0, 13600, 0]),
            (2022, 3, 20, [103700, 10200, 15250, 0, 13800, 0]),
            (2022, 4, 5, [105200, 10400, 15300, 0, 14000, 0]),
            (2022, 4, 20, [106700, 10600, 15350, 0, 14200, 0]),
            (2022, 5, 5, [108200, 10800, 15400, 0, 14400, 0]),
            (2022, 5, 20, [109700, 11000, 15450, 0, 14600, 0]),
            (2022, 6, 5, [111200, 11200, 15500, 20000, 14800, 0]),  // Flagstone opens
            (2022, 6, 20, [112800, 11400, 15550, 20100, 15000, 0]),
            (2022, 7, 5, [114400, 11600, 15600, 20200, 15200, 0]),
            (2022, 7, 20, [116000, 11800, 15650, 20300, 15400, 0]),
            (2022, 8, 5, [117600, 12000, 15700, 20400, 15600, 0]),
            (2022, 8, 20, [119200, 12200, 15750, 20500, 15800, 0]),
            (2022, 9, 5, [120900, 12400, 15800, 20600, 16000, 0]),
            (2022, 9, 20, [122600, 12600, 15850, 20700, 16200, 0]),
            (2022, 10, 5, [124300, 12800, 15900, 20800, 16400, 0]),
            (2022, 10, 20, [126000, 13000, 15950, 20900, 16600, 0]),
            (2022, 11, 5, [127700, 13200, 16000, 21000, 16800, 0]),
            (2022, 11, 20, [129400, 13400, 16050, 21100, 17000, 0]),
            (2022, 12, 5, [131200, 13600, 16100, 21200, 17200, 0]),
            (2022, 12, 20, [133000, 13800, 16150, 21300, 17400, 0]),
            
            // 2023 - Crypto starts, all accounts growing
            (2023, 1, 5, [134900, 14000, 16200, 21400, 17600, 2000]),  // Crypto opens
            (2023, 1, 20, [136800, 14200, 16250, 21500, 17800, 2100]),
            (2023, 2, 5, [138700, 14400, 16300, 21600, 18000, 2200]),
            (2023, 2, 20, [140600, 14600, 16350, 21700, 18200, 2300]),
            (2023, 3, 5, [142500, 14800, 16400, 21800, 18400, 2400]),
            (2023, 3, 20, [144500, 15000, 16450, 21900, 18600, 2500]),
            (2023, 4, 5, [146500, 15200, 16500, 22000, 18800, 2600]),
            (2023, 4, 20, [148500, 15400, 16550, 22100, 19000, 2700]),
            (2023, 5, 5, [150500, 15600, 16600, 22200, 19200, 2800]),
            (2023, 5, 20, [152500, 15800, 16650, 22300, 19400, 2900]),
            (2023, 6, 5, [154600, 16000, 16700, 22400, 19600, 3000]),
            (2023, 6, 20, [156700, 16200, 16750, 22500, 19800, 3100]),
            (2023, 7, 5, [158800, 16400, 16800, 22600, 20000, 3200]),
            (2023, 7, 20, [160900, 16600, 16850, 22700, 20200, 3300]),
            (2023, 8, 5, [163000, 16800, 16900, 22800, 20400, 3400]),
            (2023, 8, 20, [165200, 17000, 16950, 22900, 20600, 3500]),
            (2023, 9, 5, [167400, 17200, 17000, 23000, 20800, 3600]),
            (2023, 9, 20, [169600, 17400, 17050, 23100, 21000, 3700]),
            (2023, 10, 5, [171800, 17600, 17100, 23200, 21200, 3800]),
            (2023, 10, 20, [174000, 17800, 17150, 23300, 21400, 3900]),
            (2023, 11, 5, [176300, 18000, 17200, 23400, 21600, 4000]),
            (2023, 11, 20, [178600, 18200, 17250, 23500, 21800, 4100]),
            (2023, 12, 5, [180900, 18400, 17300, 23600, 22000, 4200]),
            (2023, 12, 20, [183200, 18600, 17350, 23700, 22200, 4300]),
            
            // 2024 - Strong growth year
            (2024, 1, 5, [185600, 18800, 17400, 23800, 22400, 4400]),
            (2024, 1, 20, [188000, 19000, 17450, 23900, 22600, 4500]),
            (2024, 2, 5, [190400, 19200, 17500, 24000, 22800, 4600]),
            (2024, 2, 20, [192800, 19400, 17550, 24100, 23000, 4700]),
            (2024, 3, 5, [195300, 19600, 17600, 24200, 23200, 4800]),
            (2024, 3, 20, [197800, 19800, 17650, 24300, 23400, 4900]),
            (2024, 4, 5, [200300, 20000, 17700, 24400, 23600, 5000]),
            (2024, 4, 20, [202800, 20200, 17750, 24500, 23800, 5100]),
            (2024, 5, 5, [205400, 20400, 17800, 24600, 24000, 5200]),
            (2024, 5, 20, [208000, 20600, 17850, 24700, 24200, 5300]),
            (2024, 6, 5, [210600, 20800, 17900, 24800, 24400, 5400]),
            (2024, 6, 20, [213200, 21000, 17950, 24900, 24600, 5500]),
            (2024, 7, 5, [215900, 21200, 18000, 25000, 24800, 5600]),
            (2024, 7, 20, [218600, 21400, 18050, 25100, 25000, 5700]),
            (2024, 8, 5, [221300, 21600, 18100, 25200, 25200, 5800]),
            (2024, 8, 20, [224000, 21800, 18150, 25300, 25400, 5900]),
            (2024, 9, 5, [226800, 22000, 18200, 25400, 25600, 6000]),
            (2024, 9, 20, [229600, 22200, 18250, 25500, 25800, 6100]),
            (2024, 10, 5, [232400, 22400, 18300, 25600, 26000, 6200]),
            (2024, 10, 20, [235200, 22600, 18350, 25700, 26200, 6300]),
            (2024, 11, 5, [238100, 22800, 18400, 25800, 26400, 6400]),
            (2024, 11, 20, [241000, 23000, 18450, 25900, 26600, 6500]),
            (2024, 12, 5, [243900, 23200, 18500, 26000, 26800, 6600]),
            (2024, 12, 20, [246800, 23400, 18550, 26100, 27000, 6700]),
            
            // 2025 - Year to date (reaching target ~£500k)
            (2025, 1, 5, [302000, 28500, 22100, 28200, 32200, 9500]),
            (2025, 1, 20, [305200, 28700, 22150, 28300, 32400, 9700]),
            (2025, 2, 5, [308400, 28900, 22200, 28400, 32600, 9900]),
            (2025, 2, 20, [311600, 29100, 22250, 28500, 32800, 10100]),
            (2025, 3, 5, [314900, 29300, 22300, 28600, 33000, 10300]),
            (2025, 3, 20, [318200, 29500, 22350, 28700, 33200, 10500]),
            (2025, 4, 5, [321500, 29700, 22400, 28800, 33400, 10700]),
            (2025, 4, 20, [324900, 29900, 22450, 28900, 33600, 10900]),
            (2025, 5, 5, [328300, 30100, 22500, 29000, 33800, 11100]),
            (2025, 5, 20, [331700, 30300, 22550, 29100, 34000, 11300]),
            (2025, 6, 5, [335200, 30500, 22600, 29200, 34200, 11500]),
            (2025, 6, 20, [338700, 30700, 22650, 29300, 34400, 11700]),
            (2025, 7, 5, [342200, 30900, 22700, 29400, 34600, 11900]),
            (2025, 7, 20, [345800, 31100, 22750, 29500, 34800, 12100]),
            (2025, 8, 5, [349400, 31300, 22800, 29600, 35000, 12300]),
            (2025, 8, 10, [353000, 31500, 22850, 29700, 35200, 12500]),
            // Final portfolio value: £483,750 (73% in pension)
        ]
        
        // Generate updates for each date
        for (year, month, day, values) in updates {
            if let updateDate = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                // Process each account
                for (index, account) in accounts.enumerated() {
                    // Check if this account should have a value at this date
                    let accountStartDate = account.createdAt
                    
                    // Only create update if account exists at this date and has a non-zero value
                    if updateDate >= accountStartDate && index < values.count && values[index] > 0 {
                        let update = AccountUpdate(value: values[index], account: account)
                        
                        // Set varied realistic time patterns
                        var hour: Int
                        var minute: Int
                        var dayOffset = 0
                        
                        // Create more realistic variation in update timing
                        switch index {
                        case 0: // Pension - usually updated on same day, morning
                            hour = Int.random(in: 8...10)
                            minute = Int.random(in: 0...59)
                        case 1: // T212 ISA - often updated same day but different time
                            hour = Int.random(in: 10...14)
                            minute = Int.random(in: 0...59)
                            // Sometimes updated a day or two later
                            if Int.random(in: 1...4) == 1 {
                                dayOffset = Int.random(in: 1...3)
                            }
                        case 2: // HL Active Savings - banking hours
                            hour = Int.random(in: 9...16)
                            minute = Int.random(in: 0...59)
                            // Sometimes a few days later
                            if Int.random(in: 1...3) == 1 {
                                dayOffset = Int.random(in: 1...2)
                            }
                        case 3: // Flagstone - often updated later in the week
                            hour = Int.random(in: 11...17)
                            minute = Int.random(in: 0...59)
                            // Frequently updated several days later
                            if Int.random(in: 1...2) == 1 {
                                dayOffset = Int.random(in: 2...7)
                            }
                        case 4: // HL Fund & Share - business hours
                            hour = Int.random(in: 9...15)
                            minute = Int.random(in: 0...59)
                            // Sometimes updated same day, sometimes later
                            if Int.random(in: 1...3) == 1 {
                                dayOffset = Int.random(in: 1...4)
                            }
                        case 5: // Crypto - can be updated any time
                            hour = Int.random(in: 6...23)
                            minute = Int.random(in: 0...59)
                            // Very varied timing - sometimes much later
                            if Int.random(in: 1...3) == 1 {
                                dayOffset = Int.random(in: 1...10)
                            }
                        default:
                            hour = Int.random(in: 9...17)
                            minute = Int.random(in: 0...59)
                        }
                        
                        // Apply day offset and set time
                        let adjustedDate = calendar.date(byAdding: .day, value: dayOffset, to: updateDate) ?? updateDate
                        update.date = calendar.date(bySettingHour: hour, minute: minute, second: Int.random(in: 0...59), of: adjustedDate) ?? adjustedDate
                        
                        modelContext.insert(update)
                    }
                }
            }
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
            for _ in 0..<2 {
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

