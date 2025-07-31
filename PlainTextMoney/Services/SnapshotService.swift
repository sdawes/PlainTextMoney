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
    #endif
}