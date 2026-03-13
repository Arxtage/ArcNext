import Foundation
import Testing

@testable import ArcNextCore

@Suite("SplitNode")
struct SplitNodeTests {
    @Test("Single leaf contains one pane")
    func singleLeaf() {
        let paneID = UUID()
        let node = SplitNode.leaf(paneID: paneID)
        #expect(node.paneCount == 1)
        #expect(node.allPaneIDs == [paneID])
        #expect(node.containsPane(paneID))
    }

    @Test("Insert split at leaf creates two panes")
    func insertSplit() {
        let paneA = UUID()
        let paneB = UUID()
        let node = SplitNode.leaf(paneID: paneA)
        let result = node.insertSplit(at: paneA, newPaneID: paneB, direction: .vertical)
        #expect(result.paneCount == 2)
        #expect(result.containsPane(paneA))
        #expect(result.containsPane(paneB))
    }

    @Test("Insert split at non-matching leaf is no-op")
    func insertSplitNoMatch() {
        let paneA = UUID()
        let paneB = UUID()
        let target = UUID()
        let node = SplitNode.leaf(paneID: paneA)
        let result = node.insertSplit(at: target, newPaneID: paneB, direction: .vertical)
        #expect(result == node)
    }

    @Test("Remove pane collapses parent split")
    func removePane() {
        let paneA = UUID()
        let paneB = UUID()
        let node = SplitNode.split(
            direction: .vertical,
            ratio: 0.5,
            first: .leaf(paneID: paneA),
            second: .leaf(paneID: paneB)
        )
        let result = node.removePane(paneA)
        #expect(result == .leaf(paneID: paneB))
    }

    @Test("Remove only pane returns nil")
    func removeOnlyPane() {
        let paneA = UUID()
        let node = SplitNode.leaf(paneID: paneA)
        let result = node.removePane(paneA)
        #expect(result == nil)
    }

    @Test("Nested split pane count is correct")
    func nestedSplit() {
        let a = UUID(), b = UUID(), c = UUID()
        let node = SplitNode.split(
            direction: .horizontal,
            ratio: 0.5,
            first: .leaf(paneID: a),
            second: .split(
                direction: .vertical,
                ratio: 0.5,
                first: .leaf(paneID: b),
                second: .leaf(paneID: c)
            )
        )
        #expect(node.paneCount == 3)
        #expect(Set(node.allPaneIDs) == Set([a, b, c]))
    }

    @Test("Remove middle pane in nested split")
    func removeMiddlePane() {
        let a = UUID(), b = UUID(), c = UUID()
        let node = SplitNode.split(
            direction: .horizontal,
            ratio: 0.5,
            first: .leaf(paneID: a),
            second: .split(
                direction: .vertical,
                ratio: 0.5,
                first: .leaf(paneID: b),
                second: .leaf(paneID: c)
            )
        )
        let result = node.removePane(b)
        #expect(result?.paneCount == 2)
        #expect(result?.containsPane(a) == true)
        #expect(result?.containsPane(c) == true)
        #expect(result?.containsPane(b) == false)
    }
}
