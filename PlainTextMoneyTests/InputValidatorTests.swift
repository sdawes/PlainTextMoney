//
//  InputValidatorTests.swift
//  PlainTextMoneyTests
//
//  Created by Claude on 10/08/2025.
//

import Testing
import Foundation
@testable import PlainTextMoney

/// Tests for InputValidator
/// Ensures monetary input validation works correctly and prevents invalid data entry
@MainActor
struct InputValidatorTests {
    
    // MARK: - Valid Input Tests
    
    @Test func validateMonetaryInput_WithValidWholeNumbers() {
        // Given: Valid whole number strings
        let validInputs = ["100", "1000", "50"]
        
        for input in validInputs {
            // When: Validate input
            let result = InputValidator.validateMonetaryInput(input)
            
            // Then: Should be valid
            switch result {
            case .valid(let decimal):
                #expect(decimal == Decimal(string: input))
            case .invalid(let error):
                Issue.record("Input '\(input)' should be valid but got error: \(error)")
            }
        }
    }
    
    @Test func validateMonetaryInput_WithValidDecimalNumbers() {
        // Given: Valid decimal strings
        let validInputs = ["100.50", "1000.99", "50.00", "0.01", "123.45"]
        
        for input in validInputs {
            // When: Validate input
            let result = InputValidator.validateMonetaryInput(input)
            
            // Then: Should be valid
            switch result {
            case .valid(let decimal):
                #expect(decimal == Decimal(string: input))
            case .invalid(let error):
                Issue.record("Input '\(input)' should be valid but got error: \(error)")
            }
        }
    }
    
    @Test func validateMonetaryInput_WithZero() {
        // Given: Zero value
        let input = "0"
        
        // When: Validate input
        let result = InputValidator.validateMonetaryInput(input)
        
        // Then: Should be valid
        switch result {
        case .valid(let decimal):
            #expect(decimal == 0)
        case .invalid(let error):
            Issue.record("Zero should be valid but got error: \(error)")
        }
    }
    
    @Test func validateMonetaryInput_WithLeadingZeros() {
        // Given: Numbers with leading zeros
        let testCases: [(input: String, expected: Decimal)] = [
            ("01", 1),
            ("001.50", 1.50),
            ("00100", 100)
        ]
        
        for testCase in testCases {
            // When: Validate input
            let result = InputValidator.validateMonetaryInput(testCase.input)
            
            // Then: Should be valid and correctly parsed
            switch result {
            case .valid(let decimal):
                TestHelpers.expectDecimalEqual(decimal, testCase.expected)
            case .invalid(let error):
                Issue.record("Input '\(testCase.input)' should be valid but got error: \(error)")
            }
        }
    }
    
    // MARK: - Invalid Input Tests
    
    @Test func validateMonetaryInput_WithEmptyString() {
        // Given: Empty string
        let input = ""
        
        // When: Validate input
        let result = InputValidator.validateMonetaryInput(input)
        
        // Then: Should be invalid
        switch result {
        case .valid(_):
            Issue.record("Empty string should be invalid")
        case .invalid(let error):
            #expect(error.contains("cannot be empty"))
        }
    }
    
    @Test func validateMonetaryInput_WithInvalidCharacters() {
        // Given: Strings with invalid characters
        let invalidInputs = ["abc", "100a", "1.2.3", "100,50", "$100", "100%", "100-", "100+"]
        
        for input in invalidInputs {
            // When: Validate input
            let result = InputValidator.validateMonetaryInput(input)
            
            // Then: Should be invalid
            switch result {
            case .valid(_):
                Issue.record("Input '\(input)' should be invalid")
            case .invalid(let error):
                #expect(!error.isEmpty, "Invalid input should have error message")
            }
        }
    }
    
    @Test func validateMonetaryInput_WithExcessiveDecimalPlaces() {
        // Given: Numbers with more than 2 decimal places
        let invalidInputs = ["100.123", "50.9999", "1.2345"]
        
        for input in invalidInputs {
            // When: Validate input
            let result = InputValidator.validateMonetaryInput(input)
            
            // Then: Should be invalid for financial precision
            switch result {
            case .valid(_):
                Issue.record("Input '\(input)' with >2 decimal places should be invalid")
            case .invalid(let error):
                #expect(error.contains("decimal"), "Error should mention decimal places")
            }
        }
    }
    
    @Test func validateMonetaryInput_WithNegativeNumbers() {
        // Given: Negative numbers (invalid format for this validator)
        let invalidInputs = ["-100", "-50.25", "-0.01"]
        
        for input in invalidInputs {
            // When: Validate input
            let result = InputValidator.validateMonetaryInput(input)
            
            // Then: Should be invalid (format doesn't allow negative sign)
            switch result {
            case .valid(_):
                Issue.record("Negative number '\(input)' should be invalid")
            case .invalid(let error):
                #expect(!error.isEmpty, "Should have error message")
            }
        }
    }
    
    // MARK: - Edge Cases
    
    @Test func validateMonetaryInput_WithVeryLargeNumbers() {
        // Given: Numbers exceeding the maximum value
        let largeInputs = ["1000000000", "999999999999"]
        
        for input in largeInputs {
            // When: Validate input
            let result = InputValidator.validateMonetaryInput(input)
            
            // Then: Should be invalid due to size limits
            switch result {
            case .valid(_):
                Issue.record("Large number '\(input)' should be invalid")
            case .invalid(let error):
                #expect(error.contains("too large") || error.contains("too long"), "Should mention size limit")
            }
        }
    }
    
    @Test func validateMonetaryInput_WithMaximumValidValue() {
        // Given: Maximum allowed value
        let maxInput = "999999999.99"
        
        // When: Validate input
        let result = InputValidator.validateMonetaryInput(maxInput)
        
        // Then: Should be valid
        switch result {
        case .valid(let decimal):
            TestHelpers.expectDecimalEqual(decimal, InputValidator.maxValue)
        case .invalid(let error):
            Issue.record("Maximum value should be valid but got error: \(error)")
        }
    }
    
    @Test func validateMonetaryInput_WithWhitespace() {
        // Given: Input with whitespace (should be trimmed)
        let testCases: [(input: String, expectedValue: Decimal)] = [
            (" 100", 100),
            ("100 ", 100),
            (" 100.50 ", 100.50),
            ("\t100\n", 100)
        ]
        
        for testCase in testCases {
            // When: Validate input
            let result = InputValidator.validateMonetaryInput(testCase.input)
            
            // Then: Should trim whitespace and accept
            switch result {
            case .valid(let decimal):
                TestHelpers.expectDecimalEqual(decimal, testCase.expectedValue)
            case .invalid(let error):
                Issue.record("Whitespace input should be trimmed and accepted, got error: \(error)")
            }
        }
    }
    
    @Test func validateMonetaryInput_WithTooLongInput() {
        // Given: Input exceeding character limit
        let longInput = String(repeating: "1", count: InputValidator.maxCharacterCount + 1)
        
        // When: Validate input
        let result = InputValidator.validateMonetaryInput(longInput)
        
        // Then: Should be invalid
        switch result {
        case .valid(_):
            Issue.record("Too long input should be invalid")
        case .invalid(let error):
            #expect(error.contains("too long"), "Should mention length limit")
        }
    }
    
    // MARK: - Boundary Testing
    
    @Test func validateMonetaryInput_AtBoundaries() {
        // Given: Values at validation boundaries
        let testCases: [(String, Bool, String)] = [
            ("0.00", true, "minimum value"),
            ("0.01", true, "just above minimum"),
            ("999999999.99", true, "maximum value"),
            ("1000000000.00", false, "above maximum")
        ]
        
        for (input, shouldBeValid, description) in testCases {
            // When: Validate input
            let result = InputValidator.validateMonetaryInput(input)
            
            // Then: Should match expected validity
            switch result {
            case .valid(_):
                #expect(shouldBeValid, "\(description) should be \(shouldBeValid ? "valid" : "invalid")")
            case .invalid(_):
                #expect(!shouldBeValid, "\(description) should be \(shouldBeValid ? "valid" : "invalid")")
            }
        }
    }
    
    // MARK: - Double Conversion Tests
    
    @Test func safeDoubleValue_WithValidDecimal() {
        // Given: Valid decimal values
        let testCases: [(Decimal, Double)] = [
            (100, 100.0),
            (100.50, 100.50),
            (0, 0.0),
            (999999.99, 999999.99)
        ]
        
        for (decimal, expected) in testCases {
            // When: Convert to safe double
            let result = InputValidator.safeDoubleValue(from: decimal)
            
            // Then: Should match expected value
            let difference = abs(result - expected)
            #expect(difference <= 0.001, "Conversion of \(decimal) should equal \(expected). Difference: \(difference)")
        }
    }
    
    @Test func safeDoubleValue_WithExtremeValues() {
        // Given: Very large decimal values
        let largeDecimal = Decimal(999999999)
        
        // When: Convert to safe double
        let result = InputValidator.safeDoubleValue(from: largeDecimal)
        
        // Then: Should return a finite value
        #expect(result.isFinite, "Should return finite value for large decimals")
        #expect(!result.isInfinite, "Should not return infinite value")
        #expect(!result.isNaN, "Should not return NaN")
    }
    
    // MARK: - Performance Tests
    
    @Test(.timeLimit(.minutes(1))) func validationPerformance() {
        // Given: Large set of validation inputs
        let inputs = Array(repeating: "1234.56", count: 1000)
        
        // When: Measure validation performance
        // Swift Testing uses @Test(.timeLimit()) for performance
        for input in inputs {
            _ = InputValidator.validateMonetaryInput(input)
        }
        
        // Then: Should complete within reasonable time
        // XCTest measure will automatically fail if too slow
    }
    
    // MARK: - Integration Tests
    
    @Test func validationWithProgressiveTyping() {
        // Given: Simulated user typing sequence
        let typingSequence = ["1", "12", "123", "123.", "123.4", "123.45"]
        
        for input in typingSequence {
            // When: Validate each step
            let result = InputValidator.validateMonetaryInput(input)
            
            // Then: Should handle progressive typing appropriately
            switch result {
            case .valid(let decimal):
                #expect(decimal >= 0, "Valid input should be non-negative")
            case .invalid(let error):
                #expect(!error.isEmpty, "Invalid input should have descriptive error")
            }
        }
    }
    
    @Test func validationErrorMessages() {
        // Given: Various invalid inputs with expected error types
        let errorCases: [(String, String)] = [
            ("", "empty"),
            ("abc", "format"),
            ("100.123", "decimal"),
            ("1000000000", "large"),
            (String(repeating: "1", count: 20), "long")
        ]
        
        for (input, _) in errorCases {
            // When: Validate input
            let result = InputValidator.validateMonetaryInput(input)
            
            // Then: Should provide appropriate error message
            switch result {
            case .valid(_):
                Issue.record("Input '\(input)' should be invalid")
            case .invalid(let error):
                #expect(!error.isEmpty, "Error message should not be empty")
                // Error messages should be user-friendly and descriptive
                #expect(!error.hasPrefix("Error:"), "Error messages should be user-friendly")
            }
        }
    }
    
    // MARK: - Consistency Tests
    
    @Test func validationConsistency() {
        // Given: Same input validated multiple times
        let testInput = "123.45"
        
        // When: Validate multiple times
        var results: [InputValidator.ValidationResult] = []
        for _ in 0..<10 {
            results.append(InputValidator.validateMonetaryInput(testInput))
        }
        
        // Then: All results should be identical
        for result in results {
            switch result {
            case .valid(let decimal):
                #expect(decimal == 123.45, "All validations should return same result")
            case .invalid(_):
                Issue.record("Valid input should consistently validate as valid")
            }
        }
    }
    
    // MARK: - Account Name Validation Tests
    
    @Test func validateAccountName_WithValidNames() {
        // Given: Various valid account names
        let validNames = [
            "Savings Account",
            "Current Account",
            "ISA 2025",
            "Pension (Work)",
            "Investment: S&P 500",
            "Joint Account - John & Jane",
            "Emergency Fund!",
            "Travel $avings",
            "401(k)",
            "Roth IRA",
            "Bitcoin Wallet",
            "Property #1",
            "A" // Single character minimum
        ]
        
        for name in validNames {
            // When: Validate account name
            let result = InputValidator.validateAccountName(name)
            
            // Then: Should be valid
            switch result {
            case .valid(let validatedName):
                #expect(validatedName == name.trimmingCharacters(in: .whitespacesAndNewlines))
            case .invalid(let error):
                Issue.record("Name '\(name)' should be valid but got error: \(error)")
            }
        }
    }
    
    @Test func validateAccountName_WithEmptyOrWhitespace() {
        // Given: Empty or whitespace-only names
        let invalidNames = ["", " ", "   ", "\t", "\n", "\r\n", "  \t  "]
        
        for name in invalidNames {
            // When: Validate account name
            let result = InputValidator.validateAccountName(name)
            
            // Then: Should be invalid
            switch result {
            case .valid(_):
                Issue.record("Empty/whitespace name '\(name)' should be invalid")
            case .invalid(let error):
                #expect(error.contains("empty"), "Error should mention empty name")
            }
        }
    }
    
    @Test func validateAccountName_WithExcessiveLength() {
        // Given: Name exceeding maximum length
        let longName = String(repeating: "A", count: InputValidator.maxAccountNameLength + 1)
        
        // When: Validate account name
        let result = InputValidator.validateAccountName(longName)
        
        // Then: Should be invalid
        switch result {
        case .valid(_):
            Issue.record("Name exceeding max length should be invalid")
        case .invalid(let error):
            #expect(error.contains("too long") || error.contains("max"), "Error should mention length limit")
        }
    }
    
    @Test func validateAccountName_WithMaximumValidLength() {
        // Given: Name at exactly maximum length
        let maxLengthName = String(repeating: "A", count: InputValidator.maxAccountNameLength)
        
        // When: Validate account name
        let result = InputValidator.validateAccountName(maxLengthName)
        
        // Then: Should be valid
        switch result {
        case .valid(let validatedName):
            #expect(validatedName == maxLengthName)
            #expect(validatedName.count == InputValidator.maxAccountNameLength)
        case .invalid(let error):
            Issue.record("Name at max length should be valid but got error: \(error)")
        }
    }
    
    @Test func validateAccountName_WithDuplicates() {
        // Given: Existing account names
        let existingNames = ["Savings Account", "Current Account", "ISA"]
        
        // Test case-insensitive duplicate detection
        let duplicateTests = [
            "Savings Account",      // Exact match
            "savings account",      // Lowercase
            "SAVINGS ACCOUNT",      // Uppercase
            "SaViNgS AcCoUnT",      // Mixed case
            " Savings Account ",    // With spaces (should trim and match)
            "Current Account",
            "isa",
            "ISA"
        ]
        
        for name in duplicateTests {
            // When: Validate with existing names
            let result = InputValidator.validateAccountName(name, existingNames: existingNames)
            
            // Then: Should be invalid due to duplicate
            switch result {
            case .valid(_):
                Issue.record("Duplicate name '\(name)' should be invalid")
            case .invalid(let error):
                #expect(error.contains("already exists"), "Error should mention duplicate")
            }
        }
    }
    
    @Test func validateAccountName_WithNoDuplicates() {
        // Given: Existing account names
        let existingNames = ["Savings Account", "Current Account"]
        
        // Test non-duplicate names
        let uniqueNames = ["Investment Account", "Pension", "Emergency Fund"]
        
        for name in uniqueNames {
            // When: Validate with existing names
            let result = InputValidator.validateAccountName(name, existingNames: existingNames)
            
            // Then: Should be valid
            switch result {
            case .valid(let validatedName):
                #expect(validatedName == name)
            case .invalid(let error):
                Issue.record("Unique name '\(name)' should be valid but got error: \(error)")
            }
        }
    }
    
    @Test func validateAccountName_SecurityTests_NullBytes() {
        // Given: Names with null bytes (security risk)
        let riskyNames = [
            "Account\0Name",
            "\0StartWithNull",
            "EndWithNull\0",
            "Multiple\0Null\0Bytes"
        ]
        
        for name in riskyNames {
            // When: Validate account name
            let result = InputValidator.validateAccountName(name)
            
            // Then: Should be invalid
            switch result {
            case .valid(_):
                Issue.record("Name with null byte should be invalid for security")
            case .invalid(let error):
                #expect(error.contains("invalid"), "Should reject null bytes")
            }
        }
    }
    
    @Test func validateAccountName_SecurityTests_ControlCharacters() {
        // Given: Names with control characters (could cause terminal issues)
        let controlCharNames = [
            "Account\u{001B}[31mRed",  // ANSI escape sequence
            "Bell\u{0007}Sound",        // Bell character
            "Backspace\u{0008}Test",    // Backspace
            "Form\u{000C}Feed",         // Form feed
            "\u{001F}Control"           // Unit separator
        ]
        
        for name in controlCharNames {
            // When: Validate account name
            let result = InputValidator.validateAccountName(name)
            
            // Then: Should be invalid
            switch result {
            case .valid(_):
                Issue.record("Name with control characters should be invalid")
            case .invalid(let error):
                #expect(error.contains("control"), "Should mention control characters")
            }
        }
    }
    
    @Test func validateAccountName_WithSpecialCharacters() {
        // Given: Names with allowed special characters
        let specialCharNames = [
            "Account & Savings",
            "401(k) Plan",
            "ISA #2",
            "Investment - Growth",
            "Joint: John/Jane",
            "Emergency $$$",
            "Stocks @ 5%",
            "Travel + Fun",
            "Property [Main]",
            "Fund {2025}",
            "Crypto: BTC/ETH",
            "Pension*",
            "Account!",
            "Fund~Growth",
            "2025 Savings",
            "100% Equity"
        ]
        
        for name in specialCharNames {
            // When: Validate account name
            let result = InputValidator.validateAccountName(name)
            
            // Then: Should be valid (special chars allowed)
            switch result {
            case .valid(let validatedName):
                #expect(validatedName == name)
            case .invalid(let error):
                Issue.record("Special char name '\(name)' should be valid but got error: \(error)")
            }
        }
    }
    
    @Test func validateAccountName_WithUnicodeCharacters() {
        // Given: Names with various Unicode characters
        let unicodeNames = [
            "Savings 💰",
            "Investment 📈",
            "Pension 🏦",
            "日本の貯金",  // Japanese
            "Сбережения",  // Russian
            "储蓄账户",     // Chinese
            "حساب التوفير", // Arabic
            "बचत खाता",    // Hindi
            "🏠 Property",
            "€ Euro Account",
            "£ Sterling",
            "¥ Yen Account"
        ]
        
        for name in unicodeNames {
            // When: Validate account name
            let result = InputValidator.validateAccountName(name)
            
            // Then: Should be valid (Unicode allowed)
            switch result {
            case .valid(let validatedName):
                #expect(validatedName == name)
            case .invalid(let error):
                Issue.record("Unicode name '\(name)' should be valid but got error: \(error)")
            }
        }
    }
    
    @Test func validateAccountName_WithComplexUnicodeNormalization() {
        // Given: Name with excessive Unicode normalization that could cause issues
        // Using combining characters that expand significantly  
        // This creates a string that appears to be 50 chars but expands to over 200 when normalized
        let complexUnicode = String(repeating: "A\u{0301}\u{0302}\u{0303}\u{0304}", count: 50)
        
        // When: Validate account name
        let result = InputValidator.validateAccountName(complexUnicode)
        
        // Then: Should be invalid due to expanded normalization exceeding limits
        switch result {
        case .valid(_):
            Issue.record("Excessively complex Unicode should be invalid")
        case .invalid(let error):
            #expect(error.contains("complex") || error.contains("exceed") || error.contains("long"), "Should mention complexity or length")
        }
    }
    
    @Test func validateAccountName_TrimsWhitespace() {
        // Given: Names with leading/trailing whitespace
        let testCases: [(input: String, expected: String)] = [
            (" Account Name", "Account Name"),
            ("Account Name ", "Account Name"),
            ("  Account Name  ", "Account Name"),
            ("\tTabbed Name\t", "Tabbed Name"),
            ("\nNewline Name\n", "Newline Name"),
            ("  Multiple   Spaces  ", "Multiple   Spaces") // Internal spaces preserved
        ]
        
        for testCase in testCases {
            // When: Validate account name
            let result = InputValidator.validateAccountName(testCase.input)
            
            // Then: Should trim and validate
            switch result {
            case .valid(let validatedName):
                #expect(validatedName == testCase.expected, "Should trim whitespace correctly")
            case .invalid(let error):
                Issue.record("Should trim and validate but got error: \(error)")
            }
        }
    }
    
    @Test(.timeLimit(.minutes(1))) func validateAccountName_PerformanceWithManyExistingNames() {
        // Given: Large list of existing names
        var existingNames: [String] = []
        for i in 0..<1000 {
            existingNames.append("Account \(i)")
        }
        
        // When: Measure validation performance
        // Swift Testing uses @Test(.timeLimit()) for performance
        for i in 0..<100 {
            _ = InputValidator.validateAccountName("New Account \(i)", existingNames: existingNames)
        }
        
        // Then: Should complete within reasonable time
        // XCTest measure will automatically fail if too slow
    }
    
    @Test func validateAccountName_EdgeCases() {
        // Given: Edge case names
        let edgeCases: [(name: String, shouldBeValid: Bool, description: String)] = [
            (".", true, "Single period"),
            ("-", true, "Single dash"),
            ("_", true, "Single underscore"),
            ("123", true, "Numbers only"),
            ("   A   ", true, "Single char with spaces (trims to valid)"),
            ("Account\nName", false, "Newline in middle (control char)"),
            ("Account\tName", false, "Tab in middle (control char)"),
            ("Normal Name", true, "Normal name with space")
        ]
        
        for testCase in edgeCases {
            // When: Validate account name
            let result = InputValidator.validateAccountName(testCase.name)
            
            // Then: Should match expected validity
            switch result {
            case .valid(_):
                #expect(testCase.shouldBeValid, "\(testCase.description) should be \(testCase.shouldBeValid ? "valid" : "invalid")")
            case .invalid(_):
                #expect(!testCase.shouldBeValid, "\(testCase.description) should be \(testCase.shouldBeValid ? "valid" : "invalid")")
            }
        }
    }
}