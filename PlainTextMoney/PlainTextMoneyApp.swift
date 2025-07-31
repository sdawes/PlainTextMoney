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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Account.self, AccountUpdate.self, AccountSnapshot.self, PortfolioSnapshot.self])
    }
}
