//
//  DashboardView.swift
//  PlainTextMoney
//
//  Created by Stephen Dawes on 29/07/2025.
//

import SwiftUI
import SwiftData

@MainActor
struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [Account]
    @State private var showingAddAccount = false
    @State private var selectedPeriod: PerformanceCalculationService.TimePeriod = .lastUpdate
    
    // Portfolio Engine for background calculations
    @State private var portfolioEngine: PortfolioEngine?
    
    // Async calculation results
    @State private var portfolioPerformanceData: (percentage: Double, absolute: Decimal, isPositive: Bool, hasData: Bool, actualPeriodLabel: String) = (0, 0, true, false, "")
    @State private var portfolioTimeline: [ChartDataPoint] = []
    @State private var isCalculating = false
    
    var body: some View {
        NavigationStack {
            List {
                // Portfolio Summary Section
                Section("Portfolio Total") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("£\(totalPortfolioValue.formatted())")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(activeAccountCount) accounts")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Portfolio Performance Display
                        if portfolioPerformanceData.hasData {
                            HStack {
                                Text(portfolioPerformanceData.actualPeriodLabel)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                if isCalculating {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    HStack(spacing: 4) {
                                        Text("\(portfolioPerformanceData.isPositive ? "" : "-")\(abs(portfolioPerformanceData.percentage), specifier: "%.1f")%")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(portfolioPerformanceData.isPositive ? .green : .red)
                                            .minimumScaleFactor(0.7)
                                            .lineLimit(1)
                                        
                                        Text("(\(portfolioPerformanceData.isPositive ? "" : "-")£\(abs(portfolioPerformanceData.absolute).formatted()))")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(portfolioPerformanceData.isPositive ? .green : .red)
                                            .minimumScaleFactor(0.7)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        
                        // Time Period Picker
                        Picker("Time Period", selection: $selectedPeriod) {
                            ForEach(PerformanceCalculationService.TimePeriod.allCases) { period in
                                Text(period.displayName).tag(period)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                }
                
                // Portfolio Value Chart Section
                Section("Portfolio Chart") {
                    VStack(spacing: 12) {
                        if portfolioTimeline.isEmpty && isCalculating {
                            ProgressView("Calculating...")
                                .frame(height: 200)
                        } else {
                            PortfolioChart(data: portfolioTimeline)
                                .frame(height: 200)
                                .id("\(portfolioTimeline.count)-\(selectedPeriod.rawValue)") // Force refresh when timeline or period changes
                        }
                        
                        HStack {
                            Text("Based on \(portfolioTimeline.count) data points")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Accounts Section
                Section("Accounts") {
                ForEach(accounts, id: \.name) { account in
                    NavigationLink(destination: AccountDetailView(account: account, selectedPeriod: $selectedPeriod)) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(account.name)
                                    .font(.headline)
                                Spacer()
                                Text("£\(currentValue(for: account).formatted())")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            HStack {
                                Text(contextLabel(for: account, period: selectedPeriod))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                // Calculate performance based on selected period
                                let performanceData = calculateAccountPerformance(account: account, period: selectedPeriod)
                                
                                if performanceData.hasData {
                                    HStack(spacing: 4) {
                                        Text("\(performanceData.isPositive ? "" : "-")\(abs(performanceData.percentage), specifier: "%.1f")%")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(performanceData.isPositive ? .green : .red)
                                        
                                        Text("(\(performanceData.isPositive ? "" : "-")£\(abs(performanceData.absolute).formatted()))")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(performanceData.isPositive ? .green : .red)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteAccounts)
                }
            }
            .toolbarBackground(.regularMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Plain Text Wealth")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddAccount = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AddAccountView()
            }
            .overlay(alignment: .bottomLeading) {
                #if DEBUG
                debugTestDataButton
                #endif
            }
            .task {
                // Initialize portfolio engine with model context
                if portfolioEngine == nil {
                    portfolioEngine = PortfolioEngine(modelContainer: modelContext.container)
                }
                await updatePortfolioData()
            }
            .onChange(of: selectedPeriod) { _, _ in
                Task {
                    await updatePortfolioData()
                }
            }
            .onChange(of: accounts.count) { _, _ in
                Task {
                    await updatePortfolioData()
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func accountIDsSnapshot() -> [PersistentIdentifier] {
        activeAccounts.map(\.persistentModelID)
    }
    
    // MARK: - Async Data Updates
    
    private func updatePortfolioData() async {
        guard let engine = portfolioEngine else { return }
        
        isCalculating = true
        defer { isCalculating = false }
        
        // Extract account IDs safely on MainActor
        let accountIDs = accountIDsSnapshot()
        
        // Calculate performance data on background actor
        async let performanceTask = engine.calculatePortfolioPerformance(
            accountIDs: accountIDs,
            period: selectedPeriod
        )
        
        // Generate timeline on background actor
        async let timelineTask = engine.generateFilteredPortfolioTimeline(
            accountIDs: accountIDs,
            startDate: portfolioChartStartDate,
            period: selectedPeriod
        )
        
        // Await both results
        let (performance, timeline) = await (performanceTask, timelineTask)
        
        // Update UI on main thread
        await MainActor.run {
            self.portfolioPerformanceData = performance
            self.portfolioTimeline = timeline
        }
    }
    
    private func currentValue(for account: Account) -> Decimal {
        // Get the chronologically latest update (not just the last in array)
        let latestUpdate = account.updates
            .sorted { $0.date < $1.date }
            .last
        
        
        return latestUpdate?.value ?? 0
    }
    
    private func lastUpdatedDate(for account: Account) -> Date {
        // Get the chronologically latest update date
        let latestUpdate = account.updates
            .sorted { $0.date < $1.date }
            .last
        
        return latestUpdate?.date ?? account.createdAt
    }
    
    private func percentageChange(for account: Account) -> (percentage: Double, isPositive: Bool) {
        let sortedUpdates = account.updates.sorted { $0.date < $1.date }
        
        guard let firstUpdate = sortedUpdates.first,
              let lastUpdate = sortedUpdates.last,
              firstUpdate.value > 0 else {
            return (0.0, true) // No change or no initial value
        }
        
        let change = ((lastUpdate.value - firstUpdate.value) / firstUpdate.value) * 100
        return (Double(truncating: change as NSNumber), change >= 0)
    }
    
    private func absoluteValueChange(for account: Account) -> (change: Decimal, isPositive: Bool) {
        let sortedUpdates = account.updates.sorted { $0.date < $1.date }
        
        guard let firstUpdate = sortedUpdates.first,
              let lastUpdate = sortedUpdates.last,
              firstUpdate != lastUpdate else {
            return (0, true) // No change or only one update
        }
        
        let absoluteChange = lastUpdate.value - firstUpdate.value
        return (absoluteChange, absoluteChange >= 0)
    }
    
    private func calculateAccountPerformance(account: Account, period: PerformanceCalculationService.TimePeriod) -> (percentage: Double, absolute: Decimal, isPositive: Bool, hasData: Bool) {
        switch period {
        case .lastUpdate:
            return PerformanceCalculationService.calculateAccountChangeFromLastUpdate(account: account)
        case .oneMonth:
            return PerformanceCalculationService.calculateAccountChangeOneMonth(account: account)
        case .oneYear:
            return PerformanceCalculationService.calculateAccountChangeOneYear(account: account)
        case .allTime:
            return PerformanceCalculationService.calculateAccountChangeAllTime(account: account)
        }
    }
    
    private var portfolioChartStartDate: Date? {
        let calendar = Calendar.current
        
        switch selectedPeriod {
        case .lastUpdate:
            // For last update, we'll calculate this in the engine
            // The engine will determine the second-to-last portfolio point
            return nil // Let engine handle this case
        case .oneMonth:
            return calendar.date(byAdding: .day, value: -30, to: Date())
        case .oneYear:
            return calendar.date(byAdding: .day, value: -365, to: Date())
        case .allTime:
            return nil // Show all data
        }
    }
    
    private func contextLabel(for account: Account, period: PerformanceCalculationService.TimePeriod) -> String {
        switch period {
        case .lastUpdate:
            let date = lastUpdatedDate(for: account)
            return "Since last update (\(date.formatted(date: .abbreviated, time: .omitted)))"
            
        case .oneMonth:
            return "Past month"
            
        case .oneYear:
            return "Past year"
            
        case .allTime:
            let sortedUpdates = account.updates.sorted { $0.date < $1.date }
            let firstDate = sortedUpdates.first?.date ?? account.createdAt
            return "Since start (\(firstDate.formatted(date: .abbreviated, time: .omitted)))"
        }
    }
    
    private var totalPortfolioValue: Decimal {
        // SIMPLIFIED: Always calculate in real-time from current account values
        let total = activeAccounts.reduce(0) { total, account in
            total + currentValue(for: account)
        }
        
        
        return total
    }
    
    private var activeAccountCount: Int {
        activeAccounts.count
    }
    
    // PERFORMANCE: Cache active accounts to avoid repeated filtering
    private var activeAccounts: [Account] {
        accounts.filter { $0.isActive }
    }
    
    private var totalUpdateCount: Int {
        accounts.reduce(0) { total, account in
            total + account.updates.count
        }
    }
    
    private func deleteAccounts(offsets: IndexSet) {
        withAnimation {
            var earliestDeletedDate: Date?
            
            for index in offsets {
                let accountToDelete = accounts[index]
                
                // Find the earliest update date from this account to invalidate history
                if let firstUpdate = accountToDelete.updates.sorted(by: { $0.date < $1.date }).first {
                    if earliestDeletedDate == nil || firstUpdate.date < earliestDeletedDate! {
                        earliestDeletedDate = firstUpdate.date
                    }
                }
                
                // Delete the account - SwiftData will cascade delete updates
                modelContext.delete(accountToDelete)
            }
            
            // Save changes
            do {
                try modelContext.save()
                
                // NOTE: Portfolio history invalidation disabled (incremental history system removed)
            } catch {
                print("Error deleting accounts: \(error)")
            }
        }
    }
    
    
    #if DEBUG
    private var debugTestDataButton: some View {
        HStack(spacing: 6) {
            Button("Set 1") {
                TestDataGenerator.generateTestDataSet1(modelContext: modelContext)
            }
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.blue.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(4)
            
            Button("Set 2") {
                TestDataGenerator.generateTestDataSet2(modelContext: modelContext)
            }
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.cyan.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(4)
            
            Button("Set 3") {
                TestDataGenerator.generateTestDataSet3(modelContext: modelContext)
            }
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.indigo.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(4)
            
            Button("Clear") {
                TestDataGenerator.clearAllData(modelContext: modelContext)
            }
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.red.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(4)
        }
        .padding(.leading, 16)
        .padding(.bottom, 16)
    }
    #endif
}

