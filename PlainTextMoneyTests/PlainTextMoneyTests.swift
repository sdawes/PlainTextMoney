//
//  PlainTextMoneyTests.swift
//  PlainTextMoneyTests
//
//  Created by Stephen Dawes on 10/08/2025.
//

import Testing
import SwiftData
import Foundation
@testable import PlainTextMoney

/// Basic test suite for project setup validation
@MainActor
struct PlainTextMoneyTests {
    
    @Test func projectSetup_BasicImports() throws {
        // Given: Project modules should be importable
        // When: Tests run
        // Then: All imports should work without compilation errors
        #expect(true, "Project imports are working correctly")
    }
    
    @Test func swiftData_ModelSetup() throws {
        // Given: SwiftData models should be properly configured
        let container = try ModelContainer(
            for: Account.self, AccountUpdate.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        
        // When: Create a basic context
        let context = ModelContext(container)
        
        // Then: Should be able to create models
        let account = Account(name: "Test Account")
        context.insert(account)
        
        #expect(account.name == "Test Account")
        #expect(account.isActive == true)
        #expect(account.updates.isEmpty)
    }
    
    @Test func services_AreInstantiable() throws {
        // Given: Core services
        // When: Try to access service methods
        // Then: Should be able to call validation methods
        let result = InputValidator.validateMonetaryInput("100.50")
        
        switch result {
        case .valid(let decimal):
            #expect(decimal == 100.50)
        case .invalid(let error):
            Issue.record("Valid input should not fail: \(error)")
        }
    }
}