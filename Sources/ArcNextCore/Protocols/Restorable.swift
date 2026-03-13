import Foundation

/// Types that can serialize/deserialize their state for session restore.
public protocol Restorable {
    associatedtype Snapshot: Codable & Sendable
    func snapshot() -> Snapshot
    static func restore(from snapshot: Snapshot) throws -> Self
}
