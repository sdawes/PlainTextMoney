//
//  AccountDetailView.swift
//  PlainTextMoney
//
//  Created by Stephen Dawes on 29/07/2025.
//

import SwiftUI
import SwiftData

struct AccountDetailView: View {
    let account: Account
    @Environment(\.modelContext) private var modelContext
    @State private var showingUpdateValue = false
    @State private var newValue = ""
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // Current Value Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Value")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("£\(currentValue.formatted())")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Update History Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Update History")
                        .font(.headline)
                    
                    if account.updates.isEmpty {
                        Text("No updates yet")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        List {
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
                        }
                        .listStyle(.plain)
                    }
                }
                
                Spacer()
            }
            .padding()
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
        
        showingUpdateValue = false
        newValue = ""
    }
}