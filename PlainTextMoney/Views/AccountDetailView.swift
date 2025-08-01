//
//  AccountDetailView.swift
//  PlainTextMoney
//
//  Created by Stephen Dawes on 29/07/2025.
//

import SwiftUI
import SwiftData
import Charts

struct AccountDetailView: View {
    let account: Account
    @Environment(\.modelContext) private var modelContext
    @Query private var allSnapshots: [AccountSnapshot]
    @State private var showingUpdateValue = false
    @State private var newValue = ""
    
    var body: some View {
        NavigationStack {
            List {
                // Current Value Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Current Value")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        HStack {
                            Text("£\(currentValue.formatted())")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Spacer()
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color(.systemGray6))
                
                // Account Value Chart Section
                Section("Value Chart") {
                    VStack(spacing: 12) {
                        AccountChart(dataPoints: chartDataPoints, interpolationMethod: .monotone)
                            .frame(height: 200)
                        
                        HStack {
                            Text("Based on \(accountSnapshots.count) daily snapshots")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Update History Section
                Section("Update History") {
                    if account.updates.isEmpty {
                        Text("No updates yet")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(sortedUpdates, id: \.date) { update in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("£\(update.value.formatted())")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(update.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                        .onDelete(perform: deleteUpdates)
                    }
                }
            }
            .navigationTitle(account.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                Button("Update Value") {
                    showingUpdateValue = true
                }
            }
            .sheet(isPresented: $showingUpdateValue) {
                updateValueSheet
            }
        }
    }
    
    private var currentValue: Decimal {
        account.updates.last?.value ?? 0
    }
    
    private var sortedUpdates: [AccountUpdate] {
        account.updates.sorted { $0.date > $1.date }
    }
    
    private var accountSnapshots: [AccountSnapshot] {
        allSnapshots.filter { $0.account == account }
    }
    
    private var chartDataPoints: [ChartDataPoint] {
        let sortedSnapshots = accountSnapshots.sorted { $0.date < $1.date }
        return sortedSnapshots.map { snapshot in
            ChartDataPoint(date: snapshot.date, value: snapshot.value)
        }
    }
    
    private var updateValueSheet: some View {
        NavigationStack {
            Form {
                Section("New Value") {
                    TextField("Enter new value", text: $newValue)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Update Value")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingUpdateValue = false
                        newValue = ""
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveUpdate()
                    }
                    .disabled(newValue.isEmpty)
                }
            }
        }
    }
    
    private func saveUpdate() {
        guard let value = Decimal(string: newValue) else { return }
        
        let update = AccountUpdate(value: value, account: account)
        modelContext.insert(update)
        
        // Create/update account snapshot
        SnapshotService.updateAccountSnapshot(for: account, value: value, modelContext: modelContext)
        
        // Update portfolio snapshot for today
        SnapshotService.updatePortfolioSnapshot(modelContext: modelContext)
        
        showingUpdateValue = false
        newValue = ""
    }
    
    private func deleteUpdates(offsets: IndexSet) {
        withAnimation {
            var earliestDeletedDate: Date? = nil
            
            for index in offsets {
                let updateToDelete = sortedUpdates[index]
                
                // Track the earliest deleted date for portfolio recalculation
                if let earliest = earliestDeletedDate {
                    earliestDeletedDate = min(earliest, updateToDelete.date)
                } else {
                    earliestDeletedDate = updateToDelete.date
                }
                
                // Use SnapshotService to handle deletion and snapshot recalculation
                SnapshotService.deleteAccountUpdate(updateToDelete, from: account, modelContext: modelContext)
            }
            
            // Recalculate portfolio snapshots in background to avoid blocking UI
            if let earliestDate = earliestDeletedDate {
                Task {
                    await SnapshotService.recalculatePortfolioSnapshotsAsync(from: earliestDate, modelContext: modelContext)
                }
            }
        }
    }
}
