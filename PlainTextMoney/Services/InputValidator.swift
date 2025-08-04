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
    
    // MARK: - Validation Result
    enum ValidationResult {
        case valid(Decimal)
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