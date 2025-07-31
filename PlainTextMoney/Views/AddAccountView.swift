//
//  AddAccountView.swift
//  PlainTextMoney
//
//  Created by Stephen Dawes on 29/07/2025.
//

import SwiftUI
import SwiftData

struct AddAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var accountName = ""
    @State private var initialValue = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Account Details") {
                    TextField("Account name", text: $accountName)
                    TextField("Initial value", text: $initialValue)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAccount()
                    }
                    .disabled(accountName.isEmpty || initialValue.isEmpty)
                }
            }
        }
    }
    
    private func saveAccount() {
        guard let value = Decimal(string: initialValue) else { return }
        
        let newAccount = Account(name: accountName)
        modelContext.insert(newAccount)
        
        let initialUpdate = AccountUpdate(value: value, account: newAccount)
        modelContext.insert(initialUpdate)
        
        // Create initial account snapshot
        SnapshotService.updateAccountSnapshot(for: newAccount, value: value, modelContext: modelContext)
        
        dismiss()
    }
}