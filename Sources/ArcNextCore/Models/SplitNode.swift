import Foundation

public enum SplitDirection: String, Codable, Sendable {
    case horizontal
    case vertical
}

public indirect enum SplitNode: Codable, Sendable, Equatable {
    case leaf(paneID: UUID)
    case split(direction: SplitDirection, ratio: Double, first: SplitNode, second: SplitNode)

    // MARK: - Queries

    public var allPaneIDs: [UUID] {
        switch self {
        case .leaf(let paneID):
            return [paneID]
        case .split(_, _, let first, let second):
            return first.allPaneIDs + second.allPaneIDs
        }
    }

    public func containsPane(_ paneID: UUID) -> Bool {
        switch self {
        case .leaf(let id):
            return id == paneID
        case .split(_, _, let first, let second):
            return first.containsPane(paneID) || second.containsPane(paneID)
        }
    }

    public var paneCount: Int {
        switch self {
        case .leaf:
            return 1
        case .split(_, _, let first, let second):
            return first.paneCount + second.paneCount
        }
    }

    // MARK: - Mutations (return new tree)

    /// Insert a new pane by splitting an existing pane.
    public func insertSplit(
        at targetPaneID: UUID,
        newPaneID: UUID,
        direction: SplitDirection,
        ratio: Double = 0.5
    ) -> SplitNode {
        switch self {
        case .leaf(let paneID):
            if paneID == targetPaneID {
                return .split(
                    direction: direction,
                    ratio: ratio,
                    first: .leaf(paneID: paneID),
                    second: .leaf(paneID: newPaneID)
                )
            }
            return self
        case .split(let dir, let r, let first, let second):
            return .split(
                direction: dir,
                ratio: r,
                first: first.insertSplit(at: targetPaneID, newPaneID: newPaneID, direction: direction, ratio: ratio),
                second: second.insertSplit(at: targetPaneID, newPaneID: newPaneID, direction: direction, ratio: ratio)
            )
        }
    }

    /// Remove a pane, collapsing the split that contained it.
    public func removePane(_ targetPaneID: UUID) -> SplitNode? {
        switch self {
        case .leaf(let paneID):
            return paneID == targetPaneID ? nil : self
        case .split(let dir, let r, let first, let second):
            let newFirst = first.removePane(targetPaneID)
            let newSecond = second.removePane(targetPaneID)
            switch (newFirst, newSecond) {
            case (nil, nil):
                return nil
            case (let node?, nil):
                return node
            case (nil, let node?):
                return node
            case (let f?, let s?):
                return .split(direction: dir, ratio: r, first: f, second: s)
            }
        }
    }
}
