//
//  AddAccountView.swift
//  PlainTextMoney
//
//  Created by Stephen Dawes on 29/07/2025.
//

import SwiftUI
import SwiftData

@MainActor
struct AddAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var accounts: [Account]
    
    @State private var accountName = ""
    @State private var initialValue = ""
    @State private var nameValidationError = ""
    @State private var valueValidationError = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Account Details") {
                    TextField("Account name", text: $accountName)
                        .onChange(of: accountName) { oldValue, newValue in
                            validateAccountName(newValue)
                        }
                    
                    if !nameValidationError.isEmpty {
                        Text(nameValidationError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    TextField("Initial value", text: $initialValue)
                        .keyboardType(.decimalPad)
                        .onChange(of: initialValue) { oldValue, newValue in
                            validateMonetaryInput(newValue)
                        }
                    
                    if !valueValidationError.isEmpty {
                        Text(valueValidationError)
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
        // Check if both fields have input
        if accountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || initialValue.isEmpty {
            return false
        }
        
        // Get existing account names for duplicate check
        let existingNames = accounts.map { $0.name }
        
        // Validate account name
        if case .invalid = InputValidator.validateAccountName(accountName, existingNames: existingNames) {
            return false
        }
        
        // Validate monetary value
        if case .invalid = InputValidator.validateMonetaryInput(initialValue) {
            return false
        }
        
        return true
    }
    
    private func validateAccountName(_ input: String) {
        // Don't validate if empty (will show error on save attempt)
        if input.isEmpty {
            nameValidationError = ""
            return
        }
        
        // Get existing account names for duplicate check
        let existingNames = accounts.map { $0.name }
        
        switch InputValidator.validateAccountName(input, existingNames: existingNames) {
        case .valid:
            nameValidationError = ""
        case .invalid(let error):
            nameValidationError = error
        }
    }
    
    private func validateMonetaryInput(_ input: String) {
        // Don't validate if empty (will show error on save attempt)
        if input.isEmpty {
            valueValidationError = ""
            return
        }
        
        switch InputValidator.validateMonetaryInput(input) {
        case .valid:
            valueValidationError = ""
        case .invalid(let error):
            valueValidationError = error
        }
    }
    
    private func saveAccount() {
        // Get existing account names for final duplicate check
        let existingNames = accounts.map { $0.name }
        
        // Validate account name one more time before saving
        guard case .valid(let validatedName) = InputValidator.validateAccountName(accountName, existingNames: existingNames) else {
            // This shouldn't happen as button is disabled when invalid
            return
        }
        
        // Use validated value from InputValidator
        guard case .valid(let value) = InputValidator.validateMonetaryInput(initialValue) else {
            // This shouldn't happen as button is disabled when invalid
            return
        }
        
        // Create account with validated name (trimmed)
        let newAccount = Account(name: validatedName)
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
    }
}