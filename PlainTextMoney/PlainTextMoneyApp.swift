//
//  PlainTextMoneyApp.swift
//  PlainTextMoney
//
//  Created by Stephen Dawes on 29/07/2025.
//

import SwiftUI
import SwiftData

@main
struct PlainTextMoneyApp: App {
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: Account.self, AccountUpdate.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
