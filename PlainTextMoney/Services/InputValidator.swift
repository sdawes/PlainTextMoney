//
//  InputValidator.swift
//  PlainTextMoney
//
//  Created by Claude on 03/08/2025.
//

import Foundation

struct InputValidator {
    
    // MARK: - Validation Limits
    static let maxValue: Decimal = 999_999_999.99
    static let minValue: Decimal = 0.00
    static let maxCharacterCount = 15
    static let maxAccountNameLength = 50
    static let minAccountNameLength = 1
    
    // MARK: - Validation Result
    enum ValidationResult {
        case valid(Decimal)
        case invalid(String)
    }
    
    enum AccountNameValidationResult {
        case valid(String)
        case invalid(String)
    }
    
    // MARK: - Main Validation Method
    static func validateMonetaryInput(_ input: String) -> ValidationResult {
        // Remove whitespace
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if empty
        guard !trimmedInput.isEmpty else {
            return .invalid("Value cannot be empty")
        }
        
        // Check character limit
        guard trimmedInput.count <= maxCharacterCount else {
            return .invalid("Value too long (max \(maxCharacterCount) characters)")
        }
        
        // Check for valid decimal format
        guard isValidDecimalFormat(trimmedInput) else {
            return .invalid("Invalid number format")
        }
        
        // Try to convert to Decimal
        guard let decimal = Decimal(string: trimmedInput) else {
            return .invalid("Invalid number")
        }
        
        // Check bounds
        guard decimal >= minValue else {
            return .invalid("Value cannot be negative")
        }
        
        guard decimal <= maxValue else {
            return .invalid("Value too large (max £\(formatCurrency(maxValue)))")
        }
        
        // Check decimal places (max 2 for currency)
        if hasMoreThanTwoDecimalPlaces(decimal) {
            return .invalid("Maximum 2 decimal places allowed")
        }
        
        return .valid(decimal)
    }
    
    // MARK: - Helper Methods
    private static func isValidDecimalFormat(_ input: String) -> Bool {
        // Allow digits, at most one decimal point, and optional negative sign at start
        let pattern = "^[0-9]+(\\.?[0-9]*)$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: input.utf16.count)
        return regex?.firstMatch(in: input, options: [], range: range) != nil
    }
    
    private static func hasMoreThanTwoDecimalPlaces(_ decimal: Decimal) -> Bool {
        // Simple approach: multiply by 100 and check if it's a whole number
        let scaled = decimal * 100
        let rounded = Decimal(Int(NSDecimalNumber(decimal: scaled).doubleValue))
        return scaled != rounded
    }
    
    private static func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
    }
    
    // MARK: - Account Name Validation
    static func validateAccountName(_ input: String, existingNames: [String] = []) -> AccountNameValidationResult {
        // Trim whitespace from beginning and end
        let trimmedName = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if empty after trimming
        guard !trimmedName.isEmpty else {
            return .invalid("Account name cannot be empty")
        }
        
        // Check minimum length
        guard trimmedName.count >= minAccountNameLength else {
            return .invalid("Account name must be at least \(minAccountNameLength) character")
        }
        
        // Check maximum length (prevent buffer overflow attacks)
        guard trimmedName.count <= maxAccountNameLength else {
            return .invalid("Account name too long (max \(maxAccountNameLength) characters)")
        }
        
        // Additional check: Ensure the base string isn't too long even before normalization
        // This catches strings with excessive combining characters
        if trimmedName.utf16.count > maxAccountNameLength * 3 {
            return .invalid("Account name contains too many complex characters")
        }
        
        // Check for null bytes (security: prevent null byte injection)
        if trimmedName.contains("\0") {
            return .invalid("Account name contains invalid characters")
        }
        
        // Check for control characters (security: prevent terminal escape sequences)
        let controlCharacterSet = CharacterSet.controlCharacters
        if trimmedName.rangeOfCharacter(from: controlCharacterSet) != nil {
            return .invalid("Account name contains invalid control characters")
        }
        
        // Check for duplicate names (case-insensitive comparison)
        let normalizedName = trimmedName.lowercased()
        let normalizedExisting = existingNames.map { $0.lowercased() }
        if normalizedExisting.contains(normalizedName) {
            return .invalid("An account with this name already exists")
        }
        
        // Additional security: Check for very long Unicode sequences that could cause issues
        // Some Unicode characters can be extremely long when normalized
        let normalizedLength = trimmedName.precomposedStringWithCanonicalMapping.count
        let decomposedLength = trimmedName.decomposedStringWithCanonicalMapping.count
        
        // If either normalization form is excessively long, reject it
        if normalizedLength > maxAccountNameLength * 2 || decomposedLength > maxAccountNameLength * 3 {
            return .invalid("Account name contains complex characters that exceed limits")
        }
        
        return .valid(trimmedName)
    }
    
    // MARK: - Safe Chart Conversion
    static func safeDoubleValue(from decimal: Decimal) -> Double {
        // Convert to NSDecimalNumber first
        let decimalNumber = NSDecimalNumber(decimal: decimal)
        
        // Check if it's within Double range
        let doubleValue = decimalNumber.doubleValue
        
        // Handle overflow/underflow
        if doubleValue.isInfinite || doubleValue.isNaN {
            // Return a safe maximum value for charts
            return decimal >= 0 ? Double.greatestFiniteMagnitude / 1000 : -Double.greatestFiniteMagnitude / 1000
        }
        
        return doubleValue
    }
}