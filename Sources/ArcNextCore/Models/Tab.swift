import Foundation

@Observable
public final class Tab: Identifiable {
    public let id: UUID
    public var title: String
    public var isPinned: Bool
    public var groupID: UUID?
    public var createdAt: Date
    public var lastAccessedAt: Date
    public let contentType: TabContentType
    public let contentID: UUID

    public init(
        id: UUID = UUID(),
        title: String,
        isPinned: Bool = false,
        groupID: UUID? = nil,
        contentType: TabContentType = .terminal,
        contentID: UUID
    ) {
        self.id = id
        self.title = title
        self.isPinned = isPinned
        self.groupID = groupID
        self.createdAt = Date()
        self.lastAccessedAt = Date()
        self.contentType = contentType
        self.contentID = contentID
    }

    public func touch() {
        lastAccessedAt = Date()
    }
}

extension Tab: Codable {
    enum CodingKeys: String, CodingKey {
        case id, title, isPinned, groupID, createdAt, lastAccessedAt, contentType, contentID
    }

    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            title: try container.decode(String.self, forKey: .title),
            isPinned: try container.decode(Bool.self, forKey: .isPinned),
            groupID: try container.decodeIfPresent(UUID.self, forKey: .groupID),
            contentType: try container.decode(TabContentType.self, forKey: .contentType),
            contentID: try container.decode(UUID.self, forKey: .contentID)
        )
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastAccessedAt = try container.decode(Date.self, forKey: .lastAccessedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(isPinned, forKey: .isPinned)
        try container.encodeIfPresent(groupID, forKey: .groupID)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastAccessedAt, forKey: .lastAccessedAt)
        try container.encode(contentType, forKey: .contentType)
        try container.encode(contentID, forKey: .contentID)
    }
}
