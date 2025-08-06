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
    @State private var validationError = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Account Details") {
                    TextField("Account name", text: $accountName)
                    TextField("Initial value", text: $initialValue)
                        .keyboardType(.decimalPad)
                        .onChange(of: initialValue) { oldValue, newValue in
                            validateInput(newValue)
                        }
                    
                    if !validationError.isEmpty {
                        Text(validationError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
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
                    .disabled(!isValidToSave)
                }
            }
        }
    }
    
    private var isValidToSave: Bool {
        if accountName.isEmpty || initialValue.isEmpty {
            return false
        }
        
        if case .valid = InputValidator.validateMonetaryInput(initialValue) {
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
    
    private func saveAccount() {
        // Use validated value from InputValidator
        switch InputValidator.validateMonetaryInput(initialValue) {
        case .valid(let value):
            let newAccount = Account(name: accountName)
            modelContext.insert(newAccount)
            
            let initialUpdate = AccountUpdate(value: value, account: newAccount)
            modelContext.insert(initialUpdate)
            
            // Save to database
            do {
                try modelContext.save()
            } catch {
                print("Error saving account: \(error)")
            }
            
            dismiss()
        case .invalid:
            // This shouldn't happen as button is disabled when invalid
            return
        }
    }
}