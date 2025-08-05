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
                        AccountChart(account: account, interpolationMethod: .linear)
                            .frame(height: 200)
                        
                        HStack {
                            Text("Based on \(account.updates.count) account updates")
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
        // Get the chronologically latest update (not just the last in array)
        account.updates
            .sorted { $0.date < $1.date }
            .last?.value ?? 0
    }
    
    private var sortedUpdates: [AccountUpdate] {
        account.updates.sorted { $0.date > $1.date }
    }
    
    // SIMPLIFIED: Charts now get data directly from account updates
    
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
        
        
        // SIMPLIFIED: Just create the update - charts handle the rest automatically
        let update = AccountUpdate(value: value, account: account)
        modelContext.insert(update)
        
        // Save to database
        do {
            try modelContext.save()
        } catch {
            print("❌ Error saving update: \(error)")
        }
        
        showingUpdateValue = false
        newValue = ""
    }
    
    private func deleteUpdates(offsets: IndexSet) {
        withAnimation {
            
            for index in offsets {
                let updateToDelete = sortedUpdates[index]
                
                
                // SIMPLIFIED: Just delete the update - charts update automatically
                if let accountIndex = account.updates.firstIndex(of: updateToDelete) {
                    account.updates.remove(at: accountIndex)
                }
                modelContext.delete(updateToDelete)
            }
            
            // Save changes
            do {
                try modelContext.save()
            } catch {
                print("❌ Error deleting updates: \(error)")
            }
        }
    }
}
