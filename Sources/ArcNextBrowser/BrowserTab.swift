import Foundation

// P2 stub: Browser tab content backed by WKWebView.
// This module exists to reserve the namespace and validate the multi-module build.
// Implementation deferred to P2.

public struct BrowserTabStub: Identifiable, Sendable {
    public let id: UUID
    public let url: URL

    public init(id: UUID = UUID(), url: URL) {
        self.id = id
        self.url = url
    }
}
