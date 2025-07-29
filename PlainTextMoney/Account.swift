import SwiftData
import Foundation

@Model
class Account {
    var name: String
    var createdAt: Date
    var isActive: Bool
    var closedAt: Date?
    
    init(name: String) {
        self.name = name
        self.createdAt = Date()
        self.isActive = true
        self.closedAt = nil
    }
}