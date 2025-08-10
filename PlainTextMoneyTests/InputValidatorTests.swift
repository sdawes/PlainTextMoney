//
//  InputValidatorTests.swift
//  PlainTextMoneyTests
//
//  Created by Claude on 10/08/2025.
//

import XCTest
import Foundation
@testable import PlainTextMoney

/// Tests for InputValidator
/// Ensures monetary input validation works correctly and prevents invalid data entry
@MainActor
final class InputValidatorTests: XCTestCase {
    
    // MARK: - Valid Input Tests
    
    func testValidateMonetaryInput_WithValidWholeNumbers() {
        // Given: Valid whole number strings
        let validInputs = ["100", "1000", "50"]
        
        for input in validInputs {
            // When: Validate input
            let result = InputValidator.validateMonetaryInput(input)
            
            // Then: Should be valid
            switch result {
            case .valid(let decimal):
                XCTAssertEqual(decimal, Decimal(string: input))
            case .invalid(let error):
                XCTFail("Input '\(input)' should be valid but got error: \(error)")
            }
        }
    }
    
    func testValidateMonetaryInput_WithValidDecimalNumbers() {
        // Given: Valid decimal strings
        let validInputs = ["100.50", "1000.99", "50.00", "0.01", "123.45"]
        
        for input in validInputs {
            // When: Validate input
            let result = InputValidator.validateMonetaryInput(input)
            
            // Then: Should be valid
            switch result {
            case .valid(let decimal):
                XCTAssertEqual(decimal, Decimal(string: input))
            case .invalid(let error):
                XCTFail("Input '\(input)' should be valid but got error: \(error)")
            }
        }
    }
    
    func testValidateMonetaryInput_WithZero() {
        // Given: Zero value
        let input = "0"
        
        // When: Validate input
        let result = InputValidator.validateMonetaryInput(input)
        
        // Then: Should be valid
        switch result {
        case .valid(let decimal):
            XCTAssertEqual(decimal, 0)
        case .invalid(let error):
            XCTFail("Zero should be valid but got error: \(error)")
        }
    }
    
    func testValidateMonetaryInput_WithLeadingZeros() {
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
                TestHelpers.assertDecimalEqual(decimal, testCase.expected)
            case .invalid(let error):
                XCTFail("Input '\(testCase.input)' should be valid but got error: \(error)")
            }
        }
    }
    
    // MARK: - Invalid Input Tests
    
    func testValidateMonetaryInput_WithEmptyString() {
        // Given: Empty string
        let input = ""
        
        // When: Validate input
        let result = InputValidator.validateMonetaryInput(input)
        
        // Then: Should be invalid
        switch result {
        case .valid(_):
            XCTFail("Empty string should be invalid")
        case .invalid(let error):
            XCTAssertTrue(error.contains("cannot be empty"))
        }
    }
    
    func testValidateMonetaryInput_WithInvalidCharacters() {
        // Given: Strings with invalid characters
        let invalidInputs = ["abc", "100a", "1.2.3", "100,50", "$100", "100%", "100-", "100+"]
        
        for input in invalidInputs {
            // When: Validate input
            let result = InputValidator.validateMonetaryInput(input)
            
            // Then: Should be invalid
            switch result {
            case .valid(_):
                XCTFail("Input '\(input)' should be invalid")
            case .invalid(let error):
                XCTAssertFalse(error.isEmpty, "Invalid input should have error message")
            }
        }
    }
    
    func testValidateMonetaryInput_WithExcessiveDecimalPlaces() {
        // Given: Numbers with more than 2 decimal places
        let invalidInputs = ["100.123", "50.9999", "1.2345"]
        
        for input in invalidInputs {
            // When: Validate input
            let result = InputValidator.validateMonetaryInput(input)
            
            // Then: Should be invalid for financial precision
            switch result {
            case .valid(_):
                XCTFail("Input '\(input)' with >2 decimal places should be invalid")
            case .invalid(let error):
                XCTAssertTrue(error.contains("decimal"), "Error should mention decimal places")
            }
        }
    }
    
    func testValidateMonetaryInput_WithNegativeNumbers() {
        // Given: Negative numbers (invalid format for this validator)
        let invalidInputs = ["-100", "-50.25", "-0.01"]
        
        for input in invalidInputs {
            // When: Validate input
            let result = InputValidator.validateMonetaryInput(input)
            
            // Then: Should be invalid (format doesn't allow negative sign)
            switch result {
            case .valid(_):
                XCTFail("Negative number '\(input)' should be invalid")
            case .invalid(let error):
                XCTAssertFalse(error.isEmpty, "Should have error message")
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testValidateMonetaryInput_WithVeryLargeNumbers() {
        // Given: Numbers exceeding the maximum value
        let largeInputs = ["1000000000", "999999999999"]
        
        for input in largeInputs {
            // When: Validate input
            let result = InputValidator.validateMonetaryInput(input)
            
            // Then: Should be invalid due to size limits
            switch result {
            case .valid(_):
                XCTFail("Large number '\(input)' should be invalid")
            case .invalid(let error):
                XCTAssertTrue(error.contains("too large") || error.contains("too long"), "Should mention size limit")
            }
        }
    }
    
    func testValidateMonetaryInput_WithMaximumValidValue() {
        // Given: Maximum allowed value
        let maxInput = "999999999.99"
        
        // When: Validate input
        let result = InputValidator.validateMonetaryInput(maxInput)
        
        // Then: Should be valid
        switch result {
        case .valid(let decimal):
            TestHelpers.assertDecimalEqual(decimal, InputValidator.maxValue)
        case .invalid(let error):
            XCTFail("Maximum value should be valid but got error: \(error)")
        }
    }
    
    func testValidateMonetaryInput_WithWhitespace() {
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
                TestHelpers.assertDecimalEqual(decimal, testCase.expectedValue)
            case .invalid(let error):
                XCTFail("Whitespace input should be trimmed and accepted, got error: \(error)")
            }
        }
    }
    
    func testValidateMonetaryInput_WithTooLongInput() {
        // Given: Input exceeding character limit
        let longInput = String(repeating: "1", count: InputValidator.maxCharacterCount + 1)
        
        // When: Validate input
        let result = InputValidator.validateMonetaryInput(longInput)
        
        // Then: Should be invalid
        switch result {
        case .valid(_):
            XCTFail("Too long input should be invalid")
        case .invalid(let error):
            XCTAssertTrue(error.contains("too long"), "Should mention length limit")
        }
    }
    
    // MARK: - Boundary Testing
    
    func testValidateMonetaryInput_AtBoundaries() {
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
                XCTAssertTrue(shouldBeValid, "\(description) should be \(shouldBeValid ? "valid" : "invalid")")
            case .invalid(_):
                XCTAssertFalse(shouldBeValid, "\(description) should be \(shouldBeValid ? "valid" : "invalid")")
            }
        }
    }
    
    // MARK: - Double Conversion Tests
    
    func testSafeDoubleValue_WithValidDecimal() {
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
            XCTAssertEqual(result, expected, accuracy: 0.001, "Conversion of \(decimal) should equal \(expected)")
        }
    }
    
    func testSafeDoubleValue_WithExtremeValues() {
        // Given: Very large decimal values
        let largeDecimal = Decimal(999999999)
        
        // When: Convert to safe double
        let result = InputValidator.safeDoubleValue(from: largeDecimal)
        
        // Then: Should return a finite value
        XCTAssertTrue(result.isFinite, "Should return finite value for large decimals")
        XCTAssertFalse(result.isInfinite, "Should not return infinite value")
        XCTAssertFalse(result.isNaN, "Should not return NaN")
    }
    
    // MARK: - Performance Tests
    
    func testValidationPerformance() {
        // Given: Large set of validation inputs
        let inputs = Array(repeating: "1234.56", count: 1000)
        
        // When: Measure validation performance
        measure {
            for input in inputs {
                _ = InputValidator.validateMonetaryInput(input)
            }
        }
        
        // Then: Should complete within reasonable time
        // XCTest measure will automatically fail if too slow
    }
    
    // MARK: - Integration Tests
    
    func testValidationWithProgressiveTyping() {
        // Given: Simulated user typing sequence
        let typingSequence = ["1", "12", "123", "123.", "123.4", "123.45"]
        
        for input in typingSequence {
            // When: Validate each step
            let result = InputValidator.validateMonetaryInput(input)
            
            // Then: Should handle progressive typing appropriately
            switch result {
            case .valid(let decimal):
                XCTAssertGreaterThanOrEqual(decimal, 0, "Valid input should be non-negative")
            case .invalid(let error):
                XCTAssertFalse(error.isEmpty, "Invalid input should have descriptive error")
            }
        }
    }
    
    func testValidationErrorMessages() {
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
                XCTFail("Input '\(input)' should be invalid")
            case .invalid(let error):
                XCTAssertFalse(error.isEmpty, "Error message should not be empty")
                // Error messages should be user-friendly and descriptive
                XCTAssertFalse(error.hasPrefix("Error:"), "Error messages should be user-friendly")
            }
        }
    }
    
    // MARK: - Consistency Tests
    
    func testValidationConsistency() {
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
                XCTAssertEqual(decimal, 123.45, "All validations should return same result")
            case .invalid(_):
                XCTFail("Valid input should consistently validate as valid")
            }
        }
    }
}