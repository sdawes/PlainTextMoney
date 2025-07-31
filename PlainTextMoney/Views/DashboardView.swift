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
        account.updates.last?.value ?? 0
    }
    
    
    private var totalPortfolioValue: Decimal {
        accounts.filter { $0.isActive }.reduce(0) { total, account in
            total + currentValue(for: account)
        }
    }
    
    private var activeAccountCount: Int {
        accounts.filter { $0.isActive }.count
    }
    
    private func deleteAccounts(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(accounts[index])
            }
        }
    }
    
    #if DEBUG
    private func debugSnapshots() {
        print("\n🔍 SNAPSHOT DEBUG REPORT")
        print("========================")
        
        // First show comprehensive verification
        let _ = SnapshotService.verifyAllAccountSnapshots(accounts: accounts.filter({ $0.isActive }))
        
        print("\n📋 DETAILED ACCOUNT ANALYSIS:")
        print("=============================")
        for account in accounts.filter({ $0.isActive }) {
            SnapshotService.printSnapshotDebugInfo(for: account)
        }
    }
    
    private var debugTestDataButton: some View {
        VStack(spacing: 8) {
            Button("Load Test Data") {
                TestDataGenerator.generateTestData(modelContext: modelContext)
            }
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(6)
            
            Button("Clear All") {
                TestDataGenerator.clearAllData(modelContext: modelContext)
            }
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.red.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(6)
            
            Button("Debug Snapshots") {
                debugSnapshots()
            }
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(6)
            
        }
        .padding(.leading, 16)
        .padding(.bottom, 16)
    }
    #endif
}

