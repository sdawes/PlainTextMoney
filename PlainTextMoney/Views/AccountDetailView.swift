//
//  AccountDetailView.swift
//  PlainTextMoney
//
//  Created by Stephen Dawes on 29/07/2025.
//

import SwiftUI
import SwiftData
import Charts

@MainActor
struct AccountDetailView: View {
    let account: Account
    @Binding var selectedPeriod: PerformanceCalculationService.TimePeriod
    @Environment(\.modelContext) private var modelContext
    @State private var showingUpdateValue = false
    @State private var newValue = ""
    @State private var validationError = ""
    
    private var periodDisplayName: String {
        switch selectedPeriod {
        case .lastUpdate:
            return "Recent Updates"
        case .oneMonth:
            return "Past Month"
        case .threeMonths:
            return "Past 3 Months"
        case .oneYear:
            return "Past Year"
        case .allTime:
            return "Max"
        }
    }
    
    private var chartStartDate: Date? {
        let calendar = Calendar.current
        let sortedUpdates = account.updates.sorted { $0.date < $1.date }
        
        switch selectedPeriod {
        case .lastUpdate:
            // Show from the second-to-last update
            if sortedUpdates.count >= 2 {
                return sortedUpdates[sortedUpdates.count - 2].date
            }
            return nil
        case .oneMonth:
            return calendar.date(byAdding: .day, value: -30, to: Date())
        case .threeMonths:
            return calendar.date(byAdding: .day, value: -90, to: Date())
        case .oneYear:
            return calendar.date(byAdding: .day, value: -365, to: Date())
        case .allTime:
            return nil // Show all data
        }
    }
    
    private var visibleUpdateCount: Int {
        if let startDate = chartStartDate {
            // Count updates that are on or after the start date
            return account.updates.filter { $0.date >= startDate }.count
        } else {
            // No filter, return all updates
            return account.updates.count
        }
    }
    
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
                        // Period Picker - synced with Dashboard
                        Picker("Time Period", selection: $selectedPeriod) {
                            ForEach(PerformanceCalculationService.TimePeriod.allCases) { period in
                                Text(period.displayName).tag(period)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        AccountChart(account: account, startDate: chartStartDate, interpolationMethod: .linear)
                            .frame(height: 200)
                        
                        HStack {
                            Text("Based on \(visibleUpdateCount) \(visibleUpdateCount == 1 ? "update" : "updates") in this period")
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
                        .onChange(of: newValue) { oldValue, newValue in
                            validateInput(newValue)
                        }
                    
                    if !validationError.isEmpty {
                        Text(validationError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Update Value")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingUpdateValue = false
                        newValue = ""
                        validationError = ""
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveUpdate()
                    }
                    .disabled(!isValidToSave)
                }
            }
        }
    }
    
    private var isValidToSave: Bool {
        if newValue.isEmpty {
            return false
        }
        
        if case .valid = InputValidator.validateMonetaryInput(newValue) {
            return true
        }
        return false
    }
    
    private func validateInput(_ input: String) {
        switch InputValidator.validateMonetaryInput(input) {
        case .valid:
            validationError = ""
        case .invalid(let error):
            validationError = error
        }
    }
    
    private func saveUpdate() {
        // Use validated value from InputValidator
        switch InputValidator.validateMonetaryInput(newValue) {
        case .valid(let value):
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
            validationError = ""
        case .invalid:
            // This shouldn't happen as button is disabled when invalid
            return
        }
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
