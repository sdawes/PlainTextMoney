//
//  SnapshotService.swift
//  PlainTextMoney
//
//  Created by Stephen Dawes on 30/07/2025.
//

import SwiftData
import Foundation

class SnapshotService {
    
    static func updateAccountSnapshot(for account: Account, value: Decimal, date: Date = Date(), modelContext: ModelContext) {
        let snapshotDate = Calendar.current.startOfDay(for: date)
        
        #if DEBUG
        print("📸 Creating snapshot for \(account.name) on \(snapshotDate.formatted(date: .abbreviated, time: .omitted)) = £\(value)")
        #endif
        
        // First, fill any missing snapshots between last snapshot and this date
        fillMissingSnapshots(for: account, upTo: snapshotDate, modelContext: modelContext)
        
        // Find existing snapshot for this account and date
        let existingSnapshot = account.snapshots.first { snapshot in
            Calendar.current.isDate(snapshot.date, inSameDayAs: snapshotDate)
        }
        
        if let existingSnapshot = existingSnapshot {
            // Update existing snapshot with new value
            existingSnapshot.value = value
        } else {
            // Create new snapshot
            let newSnapshot = AccountSnapshot(date: snapshotDate, value: value, account: account)
            modelContext.insert(newSnapshot)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error updating account snapshot: \(error)")
        }
    }
    
    static func fillMissingSnapshots(for account: Account, upTo endDate: Date, modelContext: ModelContext) {
        let endDate = Calendar.current.startOfDay(for: endDate)
        
        #if DEBUG
        print("🔧 Filling gaps for \(account.name) up to \(endDate.formatted(date: .abbreviated, time: .omitted))")
        #endif
        
        // Start from account creation date
        let accountStartDate = Calendar.current.startOfDay(for: account.createdAt)
        
        // Get all existing snapshots sorted by date
        let existingSnapshots = account.snapshots.sorted { $0.date < $1.date }
        
        #if DEBUG
        print("   Existing snapshots: \(existingSnapshots.count)")
        print("   Date range: \(accountStartDate.formatted(date: .abbreviated, time: .omitted)) to \(endDate.formatted(date: .abbreviated, time: .omitted))")
        #endif
        
        // Fill every single day from account creation to end date
        var currentDate = accountStartDate
        var gapsFilledCount = 0
        
        while currentDate <= endDate {
            // Check if snapshot already exists for this date
            let snapshotExists = existingSnapshots.contains { snapshot in
                Calendar.current.isDate(snapshot.date, inSameDayAs: currentDate)
            }
            
            if !snapshotExists {
                // Find the value to carry forward for this date
                let valueToUse = getValueForDate(account: account, date: currentDate, existingSnapshots: existingSnapshots)
                
                if let value = valueToUse {
                    let gapSnapshot = AccountSnapshot(date: currentDate, value: value, account: account)
                    modelContext.insert(gapSnapshot)
                    gapsFilledCount += 1
                }
            }
            
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        #if DEBUG
        print("   Created \(gapsFilledCount) gap snapshots")
        #endif
    }
    
    private static func getValueForDate(account: Account, date: Date, existingSnapshots: [AccountSnapshot]) -> Decimal? {
        // First check if there's an update on this exact date
        if let updateForDate = account.updates.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            return updateForDate.value
        }
        
        // Otherwise, find the most recent update before this date
        let updatesBeforeDate = account.updates
            .filter { $0.date <= date }
            .sorted { $0.date > $1.date }
        
        if let mostRecentUpdate = updatesBeforeDate.first {
            return mostRecentUpdate.value
        }
        
        // Fallback: check existing snapshots before this date
        let snapshotsBeforeDate = existingSnapshots
            .filter { $0.date < date }
            .sorted { $0.date > $1.date }
        
        return snapshotsBeforeDate.first?.value
    }
    
    static func getLatestSnapshot(for account: Account, on date: Date = Date()) -> AccountSnapshot? {
        let snapshotDate = Calendar.current.startOfDay(for: date)
        
        // Find snapshot for the specific date, or most recent before that date
        return account.snapshots
            .filter { $0.date <= snapshotDate }
            .sorted { $0.date > $1.date }
            .first
    }
    
    static func getCurrentSnapshotValue(for account: Account) -> Decimal {
        if let latestSnapshot = getLatestSnapshot(for: account) {
            return latestSnapshot.value
        }
        // Fallback to latest update if no snapshots exist
        return account.updates.last?.value ?? 0
    }
    
    static func ensureCompleteSnapshotCoverage(for account: Account, modelContext: ModelContext) {
        // Fill all gaps from account creation to today
        fillMissingSnapshots(for: account, upTo: Date(), modelContext: modelContext)
    }
    
    static func deleteAccountUpdate(_ update: AccountUpdate, from account: Account, modelContext: ModelContext) {
        let deletionDate = Calendar.current.startOfDay(for: update.date)
        
        #if DEBUG
        print("🗑️ Deleting update for \(account.name) on \(deletionDate.formatted(date: .abbreviated, time: .omitted)) = £\(update.value)")
        #endif
        
        // Delete the update first
        modelContext.delete(update)
        
        // Find the date range that needs recalculation
        let nextUpdateDate = findNextUpdateDate(after: deletionDate, in: account)
        let endDate = nextUpdateDate ?? Date()
        
        #if DEBUG
        print("   Recalculating snapshots from \(deletionDate.formatted(date: .abbreviated, time: .omitted)) to \(endDate.formatted(date: .abbreviated, time: .omitted))")
        #endif
        
        // Recalculate snapshots in the affected range
        recalculateSnapshotRange(for: account, from: deletionDate, to: endDate, modelContext: modelContext)
        
        do {
            try modelContext.save()
            #if DEBUG
            print("   ✅ Deletion and recalculation complete")
            #endif
        } catch {
            print("Error saving after deletion: \(error)")
        }
    }
    
    private static func findNextUpdateDate(after date: Date, in account: Account) -> Date? {
        return account.updates
            .filter { $0.date > date }
            .sorted { $0.date < $1.date }
            .first?.date
    }
    
    private static func recalculateSnapshotRange(for account: Account, from startDate: Date, to endDate: Date, modelContext: ModelContext) {
        // Find the value to carry forward from before the deletion
        let previousValue = findPreviousValue(before: startDate, in: account)
        
        #if DEBUG
        if let prev = previousValue {
            print("   Previous value to carry forward: £\(prev)")
        } else {
            print("   No previous value found - this was likely the first update")
        }
        #endif
        
        // Delete existing snapshots in the affected range
        let snapshotsToDelete = account.snapshots.filter { snapshot in
            snapshot.date >= startDate && snapshot.date < endDate
        }
        
        #if DEBUG
        print("   Deleting \(snapshotsToDelete.count) existing snapshots in range")
        #endif
        
        for snapshot in snapshotsToDelete {
            modelContext.delete(snapshot)
        }
        
        // Recreate snapshots with correct values
        var currentDate = startDate
        var snapshotsCreated = 0
        
        while currentDate < endDate {
            // Check if there are any remaining updates on this specific date (after deletion)
            let updatesForDate = account.updates.filter { update in
                Calendar.current.isDate(update.date, inSameDayAs: currentDate)
            }.sorted { $0.date > $1.date } // Get latest update for the day
            
            let valueToUse: Decimal
            if let latestUpdateForDay = updatesForDate.first {
                // Use the latest update value for this day
                valueToUse = latestUpdateForDay.value
            } else if let carryForward = previousValue {
                // Carry forward from previous value
                valueToUse = carryForward
            } else {
                // Edge case: no previous value available (deleted the very first update)
                // Look for any remaining updates in the account to get a base value
                if let anyRemainingUpdate = account.updates.sorted(by: { $0.date < $1.date }).first {
                    valueToUse = anyRemainingUpdate.value
                } else {
                    // Truly no updates left - this shouldn't happen in normal usage
                    valueToUse = 0
                    #if DEBUG
                    print("   ⚠️ Warning: No updates remaining for account, using £0")
                    #endif
                }
            }
            
            let newSnapshot = AccountSnapshot(date: currentDate, value: valueToUse, account: account)
            modelContext.insert(newSnapshot)
            snapshotsCreated += 1
            
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        #if DEBUG
        print("   Created \(snapshotsCreated) new snapshots")
        #endif
    }
    
    private static func findPreviousValue(before date: Date, in account: Account) -> Decimal? {
        // Find the most recent update before the deletion date
        let previousUpdates = account.updates
            .filter { $0.date < date }
            .sorted { $0.date > $1.date }
        
        return previousUpdates.first?.value
    }
    
    static func debugSimpleTestAccount(accounts: [Account]) {
        if let simpleAccount = accounts.first(where: { $0.name == "Simple Test Account" }) {
            print("🧪 SIMPLE TEST ACCOUNT ANALYSIS")
            print("===============================")
            
            let sortedUpdates = simpleAccount.updates.sorted { $0.date < $1.date }
            let sortedSnapshots = simpleAccount.snapshots.sorted { $0.date < $1.date }
            
            print("📊 Summary:")
            print("   Account created: \(simpleAccount.createdAt.formatted(date: .abbreviated, time: .omitted))")
            print("   Updates: \(sortedUpdates.count)")
            print("   Snapshots: \(sortedSnapshots.count)")
            
            print("\n📅 All Updates:")
            for update in sortedUpdates {
                print("   \(update.date.formatted(date: .abbreviated, time: .shortened)): £\(update.value)")
            }
            
            if sortedSnapshots.count > 0 {
                print("\n📸 Sample Snapshots (first 10):")
                for snapshot in sortedSnapshots.prefix(10) {
                    print("   \(snapshot.date.formatted(date: .abbreviated, time: .omitted)): £\(snapshot.value)")
                }
                
                if sortedSnapshots.count > 10 {
                    print("   ... and \(sortedSnapshots.count - 10) more snapshots")
                }
                
                print("\n📈 Chart Data Ready:")
                print("   Total data points for chart: \(sortedSnapshots.count)")
                if let firstSnapshot = sortedSnapshots.first, let lastSnapshot = sortedSnapshots.last {
                    print("   Value range: £\(firstSnapshot.value) to £\(lastSnapshot.value)")
                    print("   Date range: \(firstSnapshot.date.formatted(date: .abbreviated, time: .omitted)) to \(lastSnapshot.date.formatted(date: .abbreviated, time: .omitted))")
                }
            }
            
            print("===============================\n")
        } else {
            print("❌ Simple Test Account not found")
        }
    }
    
    #if DEBUG
    static func printSnapshotDebugInfo(for account: Account) {
        print("=== Debug: Snapshots for \(account.name) ===")
        let sortedSnapshots = account.snapshots.sorted { $0.date < $1.date }
        
        if sortedSnapshots.isEmpty {
            print("❌ No snapshots found")
            return
        }
        
        // Calculate expected snapshot count
        let accountStart = Calendar.current.startOfDay(for: account.createdAt)
        let today = Calendar.current.startOfDay(for: Date())
        let expectedDays = Calendar.current.dateComponents([.day], from: accountStart, to: today).day ?? 0
        let expectedSnapshots = expectedDays + 1 // inclusive of both start and end dates
        
        print("📊 Snapshot Coverage Analysis:")
        print("   Total snapshots: \(sortedSnapshots.count)")
        print("   Expected snapshots: \(expectedSnapshots) (from \(accountStart.formatted(date: .abbreviated, time: .omitted)) to \(today.formatted(date: .abbreviated, time: .omitted)))")
        print("   Updates: \(account.updates.count)")
        
        if sortedSnapshots.count == expectedSnapshots {
            print("   ✅ PERFECT COVERAGE - No gaps!")
        } else {
            print("   ❌ MISSING \(expectedSnapshots - sortedSnapshots.count) snapshots")
        }
        
        // Check for gaps
        var gapCount = 0
        for i in 1..<sortedSnapshots.count {
            let previousDate = sortedSnapshots[i-1].date
            let currentDate = sortedSnapshots[i].date
            
            let daysBetween = Calendar.current.dateComponents([.day], from: previousDate, to: currentDate).day ?? 0
            
            if daysBetween > 1 {
                let missingDays = daysBetween - 1
                gapCount += missingDays
                print("   ❌ GAP: \(missingDays) missing days between \(previousDate.formatted(date: .abbreviated, time: .omitted)) and \(currentDate.formatted(date: .abbreviated, time: .omitted))")
            }
        }
        
        if gapCount == 0 {
            print("   ✅ No gaps detected - continuous daily coverage")
        } else {
            print("   ❌ Total gap days: \(gapCount)")
        }
        
        // Show first and last snapshots for date range verification
        if let firstSnapshot = sortedSnapshots.first {
            print("📅 Date Range:")
            print("   First: \(firstSnapshot.date.formatted(date: .abbreviated, time: .omitted)) = £\(firstSnapshot.value)")
        }
        if let lastSnapshot = sortedSnapshots.last, sortedSnapshots.count > 1 {
            print("   Last:  \(lastSnapshot.date.formatted(date: .abbreviated, time: .omitted)) = £\(lastSnapshot.value)")
        }
        
        print("=== End Debug ===\n")
    }
    
    static func verifyAllAccountSnapshots(accounts: [Account]) -> Bool {
        print("🔍 COMPREHENSIVE SNAPSHOT VERIFICATION")
        print("=====================================")
        
        var allAccountsPerfect = true
        var totalSnapshots = 0
        var totalExpectedSnapshots = 0
        
        for account in accounts.filter({ $0.isActive }) {
            let sortedSnapshots = account.snapshots.sorted { $0.date < $1.date }
            let accountStart = Calendar.current.startOfDay(for: account.createdAt)
            let today = Calendar.current.startOfDay(for: Date())
            let expectedDays = Calendar.current.dateComponents([.day], from: accountStart, to: today).day ?? 0
            let expectedSnapshots = expectedDays + 1
            
            totalSnapshots += sortedSnapshots.count
            totalExpectedSnapshots += expectedSnapshots
            
            let isPerfect = sortedSnapshots.count == expectedSnapshots
            if !isPerfect {
                allAccountsPerfect = false
            }
            
            print("\(isPerfect ? "✅" : "❌") \(account.name): \(sortedSnapshots.count)/\(expectedSnapshots) snapshots")
        }
        
        print("\n📊 OVERALL SUMMARY:")
        print("Total snapshots: \(totalSnapshots)")
        print("Expected total: \(totalExpectedSnapshots)")
        print("Accounts: \(accounts.filter({ $0.isActive }).count)")
        print("Status: \(allAccountsPerfect ? "✅ PERFECT" : "❌ INCOMPLETE")")
        
        return allAccountsPerfect
    }
    
    static func debugDeletionScenario(for account: Account) {
        print("🔍 DELETION SCENARIO DEBUG FOR \(account.name)")
        print("==========================================")
        
        let sortedUpdates = account.updates.sorted { $0.date < $1.date }
        let sortedSnapshots = account.snapshots.sorted { $0.date < $1.date }
        
        print("📊 Current State:")
        print("   Updates: \(sortedUpdates.count)")
        print("   Snapshots: \(sortedSnapshots.count)")
        
        if !sortedUpdates.isEmpty {
            print("\n📅 Recent Updates:")
            for update in sortedUpdates.suffix(5) {
                print("   \(update.date.formatted(date: .abbreviated, time: .shortened)): £\(update.value)")
            }
        }
        
        if !sortedSnapshots.isEmpty {
            print("\n📸 Recent Snapshots:")
            for snapshot in sortedSnapshots.suffix(5) {
                print("   \(snapshot.date.formatted(date: .abbreviated, time: .omitted)): £\(snapshot.value)")
            }
        }
        
        print("==========================================\n")
    }
    
    static func verifyPortfolioSnapshots(modelContext: ModelContext) -> Bool {
        print("🔍 PORTFOLIO SNAPSHOT VERIFICATION")
        print("==================================")
        
        // Get all portfolio snapshots
        let portfolioDescriptor = FetchDescriptor<PortfolioSnapshot>()
        
        guard let allSnapshots = try? modelContext.fetch(portfolioDescriptor) else {
            print("❌ Error fetching portfolio snapshots")
            return false
        }
        
        // Sort snapshots by date
        let snapshots = allSnapshots.sorted { $0.date < $1.date }
        
        if snapshots.isEmpty {
            print("❌ No portfolio snapshots found")
            return false
        }
        
        // Get accounts to determine expected date range
        let accountDescriptor = FetchDescriptor<Account>()
        guard let accounts = try? modelContext.fetch(accountDescriptor),
              !accounts.isEmpty else {
            print("❌ No accounts found")
            return false
        }
        
        let earliestAccountDate = accounts.map { $0.createdAt }.min() ?? Date()
        let startDate = Calendar.current.startOfDay(for: earliestAccountDate)
        let today = Calendar.current.startOfDay(for: Date())
        let expectedDays = Calendar.current.dateComponents([.day], from: startDate, to: today).day ?? 0
        let expectedSnapshots = expectedDays + 1
        
        print("📊 Portfolio Snapshot Analysis:")
        print("   Total snapshots: \(snapshots.count)")
        print("   Expected snapshots: \(expectedSnapshots) (from \(startDate.formatted(date: .abbreviated, time: .omitted)) to \(today.formatted(date: .abbreviated, time: .omitted)))")
        
        let isPerfect = snapshots.count == expectedSnapshots
        print("   Status: \(isPerfect ? "✅ PERFECT COVERAGE" : "❌ MISSING SNAPSHOTS")")
        
        // Check for gaps
        var gapCount = 0
        for i in 1..<snapshots.count {
            let previousDate = snapshots[i-1].date
            let currentDate = snapshots[i].date
            
            let daysBetween = Calendar.current.dateComponents([.day], from: previousDate, to: currentDate).day ?? 0
            
            if daysBetween > 1 {
                let missingDays = daysBetween - 1
                gapCount += missingDays
                print("   ❌ GAP: \(missingDays) missing days between \(previousDate.formatted(date: .abbreviated, time: .omitted)) and \(currentDate.formatted(date: .abbreviated, time: .omitted))")
            }
        }
        
        if gapCount == 0 {
            print("   ✅ No gaps detected - continuous daily coverage")
        } else {
            print("   ❌ Total gap days: \(gapCount)")
        }
        
        // Show value range
        if let firstSnapshot = snapshots.first {
            print("📅 Portfolio Value Range:")
            print("   First: \(firstSnapshot.date.formatted(date: Date.FormatStyle.DateStyle.abbreviated, time: Date.FormatStyle.TimeStyle.omitted)) = £\(firstSnapshot.totalValue)")
        }
        if let lastSnapshot = snapshots.last, snapshots.count > 1 {
            print("   Latest: \(lastSnapshot.date.formatted(date: Date.FormatStyle.DateStyle.abbreviated, time: Date.FormatStyle.TimeStyle.omitted)) = £\(lastSnapshot.totalValue)")
            
            if let firstSnapshot = snapshots.first {
                let growth = lastSnapshot.totalValue - firstSnapshot.totalValue
                print("   Growth: £\(growth)")
            }
        }
        
        print("==================================\n")
        return isPerfect && gapCount == 0
    }
    
    static func debugPortfolioSnapshots(modelContext: ModelContext) {
        print("🔍 DETAILED PORTFOLIO SNAPSHOT DEBUG")
        print("===================================")
        
        let portfolioDescriptor = FetchDescriptor<PortfolioSnapshot>()
        
        guard let allSnapshots = try? modelContext.fetch(portfolioDescriptor) else {
            print("❌ Error fetching portfolio snapshots")
            return
        }
        
        // Sort snapshots by date
        let snapshots = allSnapshots.sorted { $0.date < $1.date }
        
        print("📊 Found \(snapshots.count) portfolio snapshots:")
        
        for (index, snapshot) in snapshots.enumerated() {
            let dateStr = snapshot.date.formatted(date: Date.FormatStyle.DateStyle.abbreviated, time: Date.FormatStyle.TimeStyle.omitted)
            print("   \(index + 1). \(dateStr): £\(snapshot.totalValue)")
            
            // Show only first 10 and last 10 if there are many
            if snapshots.count > 20 && index == 9 {
                let remaining = snapshots.count - 20
                print("   ... (\(remaining) more snapshots) ...")
                // Skip to the last 10
                continue
            }
            
            if snapshots.count > 20 && index < snapshots.count - 10 && index > 9 {
                continue
            }
        }
        
        print("===================================\n")
    }
    #endif
    
    // MARK: - Portfolio Snapshot Management
    
    static func updatePortfolioSnapshot(for date: Date = Date(), modelContext: ModelContext) {
        let snapshotDate = Calendar.current.startOfDay(for: date)
        
        // Calculate total portfolio value from all active accounts
        let totalValue = calculatePortfolioTotal(for: snapshotDate, modelContext: modelContext)
        
        #if DEBUG
        print("📊 Creating portfolio snapshot for \(snapshotDate.formatted(date: .abbreviated, time: .omitted)) = £\(totalValue)")
        #endif
        
        // Find existing portfolio snapshot for this date
        let portfolioDescriptor = FetchDescriptor<PortfolioSnapshot>()
        let allSnapshots = try? modelContext.fetch(portfolioDescriptor)
        let existingSnapshot = allSnapshots?.first { snapshot in
            Calendar.current.isDate(snapshot.date, inSameDayAs: snapshotDate)
        }
        
        if let existingSnapshot = existingSnapshot {
            // Update existing snapshot
            existingSnapshot.totalValue = totalValue
        } else {
            // Create new snapshot
            let newSnapshot = PortfolioSnapshot(date: snapshotDate, totalValue: totalValue)
            modelContext.insert(newSnapshot)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error updating portfolio snapshot: \(error)")
        }
    }
    
    static func recalculatePortfolioSnapshots(from startDate: Date, modelContext: ModelContext) {
        let startDate = Calendar.current.startOfDay(for: startDate)
        let today = Calendar.current.startOfDay(for: Date())
        
        #if DEBUG
        print("🔄 Recalculating portfolio snapshots from \(startDate.formatted(date: .abbreviated, time: .omitted)) to \(today.formatted(date: .abbreviated, time: .omitted))")
        #endif
        
        // Delete existing portfolio snapshots in the affected range
        let portfolioDescriptor = FetchDescriptor<PortfolioSnapshot>()
        if let allSnapshots = try? modelContext.fetch(portfolioDescriptor) {
            let snapshotsToDelete = allSnapshots.filter { snapshot in
                snapshot.date >= startDate
            }
            
            for snapshot in snapshotsToDelete {
                modelContext.delete(snapshot)
            }
        }
        
        // Recreate snapshots day by day
        var currentDate = startDate
        while currentDate <= today {
            let totalValue = calculatePortfolioTotal(for: currentDate, modelContext: modelContext)
            let newSnapshot = PortfolioSnapshot(date: currentDate, totalValue: totalValue)
            modelContext.insert(newSnapshot)
            
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        do {
            try modelContext.save()
            #if DEBUG
            print("✅ Portfolio snapshot recalculation complete")
            #endif
        } catch {
            print("Error recalculating portfolio snapshots: \(error)")
        }
    }
    
    static func recalculatePortfolioSnapshotsAsync(from startDate: Date, modelContext: ModelContext) async {
        let startDate = Calendar.current.startOfDay(for: startDate)
        let today = Calendar.current.startOfDay(for: Date())
        
        #if DEBUG
        print("🔄 [ASYNC] Recalculating portfolio snapshots from \(startDate.formatted(date: .abbreviated, time: .omitted)) to \(today.formatted(date: .abbreviated, time: .omitted))")
        #endif
        
        // Perform the expensive work on a background thread
        await Task.detached {
            // Fetch accounts once for the entire operation
            let accountsDescriptor = FetchDescriptor<Account>()
            guard let allAccounts = try? modelContext.fetch(accountsDescriptor) else {
                #if DEBUG
                print("❌ Failed to fetch accounts for portfolio recalculation")
                #endif
                return
            }
            
            let activeAccounts = allAccounts.filter { $0.isActive }
            
            #if DEBUG
            print("📋 Recalculating with \(activeAccounts.count) active accounts")
            #endif
            
            // Delete existing portfolio snapshots in the affected range
            let portfolioDescriptor = FetchDescriptor<PortfolioSnapshot>()
            if let allSnapshots = try? modelContext.fetch(portfolioDescriptor) {
                let snapshotsToDelete = allSnapshots.filter { snapshot in
                    snapshot.date >= startDate
                }
                
                #if DEBUG
                print("🗑️ Deleting \(snapshotsToDelete.count) existing portfolio snapshots")
                #endif
                
                for snapshot in snapshotsToDelete {
                    modelContext.delete(snapshot)
                }
            }
            
            // Create new snapshots in batches for better performance
            var newSnapshots: [PortfolioSnapshot] = []
            var currentDate = startDate
            var dayCount = 0
            
            while currentDate <= today {
                let totalValue = calculatePortfolioTotalOptimized(for: currentDate, accounts: activeAccounts)
                let newSnapshot = PortfolioSnapshot(date: currentDate, totalValue: totalValue)
                newSnapshots.append(newSnapshot)
                dayCount += 1
                
                currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            
            #if DEBUG
            print("📊 Created \(newSnapshots.count) new portfolio snapshots")
            #endif
            
            // Insert all snapshots in batch
            for snapshot in newSnapshots {
                modelContext.insert(snapshot)
            }
            
            // Save all changes at once
            do {
                try modelContext.save()
                #if DEBUG
                print("✅ [ASYNC] Portfolio snapshot recalculation complete - \(dayCount) days processed")
                #endif
            } catch {
                #if DEBUG
                print("❌ Error saving portfolio snapshots: \(error)")
                #endif
            }
        }.value
    }
    
    // Optimized version that doesn't fetch accounts from database each time
    private static func calculatePortfolioTotalOptimized(for date: Date, accounts: [Account]) -> Decimal {
        let snapshotDate = Calendar.current.startOfDay(for: date)
        var totalValue: Decimal = 0
        
        for account in accounts {
            if let accountValue = getAccountValueAt(date: snapshotDate, for: account) {
                totalValue += accountValue
            }
        }
        
        return totalValue
    }
    
    static func calculatePortfolioTotal(for date: Date, modelContext: ModelContext) -> Decimal {
        let snapshotDate = Calendar.current.startOfDay(for: date)
        
        // Get all active accounts
        let accountsDescriptor = FetchDescriptor<Account>()
        
        guard let allAccounts = try? modelContext.fetch(accountsDescriptor) else {
            return 0
        }
        
        // Filter for active accounts
        let accounts = allAccounts.filter { $0.isActive }
        
        var totalValue: Decimal = 0
        
        for account in accounts {
            // Find the latest account value at or before the snapshot date
            if let accountValue = getAccountValueAt(date: snapshotDate, for: account) {
                totalValue += accountValue
            }
        }
        
        return totalValue
    }
    
    static func getAccountValueAt(date: Date, for account: Account) -> Decimal? {
        let snapshotDate = Calendar.current.startOfDay(for: date)
        
        // First try to get value from account snapshots
        let accountSnapshot = account.snapshots.first { snapshot in
            Calendar.current.isDate(snapshot.date, inSameDayAs: snapshotDate)
        }
        
        if let snapshot = accountSnapshot {
            return snapshot.value
        }
        
        // Fallback: find the latest update before or on this date
        let updatesBeforeDate = account.updates
            .filter { $0.date <= snapshotDate }
            .sorted { $0.date > $1.date }
        
        return updatesBeforeDate.first?.value
    }
    
    static func ensurePortfolioSnapshotCoverage(modelContext: ModelContext) {
        #if DEBUG
        print("🔧 Starting portfolio snapshot coverage...")
        #endif
        
        // Get the earliest account creation date
        let accountsDescriptor = FetchDescriptor<Account>()
        guard let accounts = try? modelContext.fetch(accountsDescriptor),
              !accounts.isEmpty else {
            #if DEBUG
            print("❌ No accounts found for portfolio snapshots")
            #endif
            return
        }
        
        #if DEBUG
        print("📋 Found \(accounts.count) accounts for portfolio calculation")
        #endif
        
        let earliestDate = accounts.map { $0.createdAt }.min() ?? Date()
        let startDate = Calendar.current.startOfDay(for: earliestDate)
        let today = Calendar.current.startOfDay(for: Date())
        
        #if DEBUG
        print("🔧 Ensuring portfolio snapshot coverage from \(startDate.formatted(date: .abbreviated, time: .omitted)) to \(today.formatted(date: .abbreviated, time: .omitted))")
        #endif
        
        // Check for missing portfolio snapshots and fill gaps
        let portfolioDescriptor = FetchDescriptor<PortfolioSnapshot>()
        let allPortfolioSnapshots = try? modelContext.fetch(portfolioDescriptor)
        
        #if DEBUG
        print("📊 Found \(allPortfolioSnapshots?.count ?? 0) existing portfolio snapshots")
        #endif
        
        var currentDate = startDate
        var createdCount = 0
        while currentDate <= today {
            let existingSnapshot = allPortfolioSnapshots?.first { snapshot in
                Calendar.current.isDate(snapshot.date, inSameDayAs: currentDate)
            }
            
            if existingSnapshot == nil {
                let totalValue = calculatePortfolioTotal(for: currentDate, modelContext: modelContext)
                let newSnapshot = PortfolioSnapshot(date: currentDate, totalValue: totalValue)
                modelContext.insert(newSnapshot)
                createdCount += 1
                
                #if DEBUG
                if createdCount <= 5 || createdCount % 100 == 0 {
                    print("📸 Created portfolio snapshot \(createdCount): \(currentDate.formatted(date: .abbreviated, time: .omitted)) = £\(totalValue)")
                }
                #endif
            }
            
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        #if DEBUG
        print("📊 Created \(createdCount) portfolio snapshots")
        #endif
        
        do {
            try modelContext.save()
        } catch {
            print("Error ensuring portfolio snapshot coverage: \(error)")
        }
    }
}