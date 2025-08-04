//
//  DashboardView.swift
//  PlainTextMoney
//
//  Created by Stephen Dawes on 29/07/2025.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [Account]
    @State private var showingAddAccount = false
    
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
                            Spacer()
                            Text("\(activeAccountCount) accounts")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Portfolio Value Chart Section
                Section("Portfolio Chart") {
                    VStack(spacing: 12) {
                        PortfolioChart(accounts: accounts)
                            .frame(height: 200)
                            .id("\(accounts.count)-\(totalUpdateCount)") // Force refresh when accounts or updates change
                        
                        HStack {
                            Text("Based on \(totalUpdateCount) account updates")
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
                    NavigationLink(destination: AccountDetailView(account: account)) {
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
                                Text("Created: \(account.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteAccounts)
                }
            }
            .toolbar {
                Button(action: { showingAddAccount = true }) {
                    Image(systemName: "plus")
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
        }
    }
    
    private func currentValue(for account: Account) -> Decimal {
        // Get the chronologically latest update (not just the last in array)
        let latestUpdate = account.updates
            .sorted { $0.date < $1.date }
            .last
        
        #if DEBUG
        if let latest = latestUpdate {
            print("   Current value for \(account.name): £\(latest.value) from \(latest.date.formatted(date: .abbreviated, time: .standard))")
        } else {
            print("   Current value for \(account.name): £0 (no updates)")
        }
        #endif
        
        return latestUpdate?.value ?? 0
    }
    
    
    private var totalPortfolioValue: Decimal {
        // SIMPLIFIED: Always calculate in real-time from current account values
        let total = activeAccounts.reduce(0) { total, account in
            total + currentValue(for: account)
        }
        
        #if DEBUG
        print("💰 Portfolio total: £\(total) from \(activeAccounts.count) active accounts (total accounts: \(accounts.count))")
        for account in activeAccounts {
            let currentVal = currentValue(for: account)
            print("   \(account.name): £\(currentVal) (\(account.updates.count) updates)")
        }
        #endif
        
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
            for index in offsets {
                let accountToDelete = accounts[index]
                
                // SIMPLIFIED: Just delete the account - charts update automatically
                modelContext.delete(accountToDelete)
            }
            
            // Save changes
            do {
                try modelContext.save()
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

