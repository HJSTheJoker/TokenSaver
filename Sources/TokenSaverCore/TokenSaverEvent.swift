import Foundation

public enum TokenSaverEventStatus: String, Codable, CaseIterable, Sendable {
    case ok
    case blocked
    case failed
    case dryRun = "dry_run"
}

public struct TokenSaverEvent: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let timestamp: Date
    public let tool: String
    public let provider: String
    public let status: TokenSaverEventStatus
    public let model: String
    public let rawBytes: Int
    public let excerptBytes: Int
    public let rawLines: Int
    public let estimatedRawTokens: Int
    public let estimatedExcerptTokens: Int
    public let estimatedTokensSaved: Int
    public let durationMS: Int
    public let guardBlocked: Bool
    public let blockerCategory: String

    public init(
        schemaVersion: Int = 1,
        timestamp: Date,
        tool: String,
        provider: String,
        status: TokenSaverEventStatus,
        model: String,
        rawBytes: Int,
        excerptBytes: Int,
        rawLines: Int,
        estimatedRawTokens: Int,
        estimatedExcerptTokens: Int,
        estimatedTokensSaved: Int,
        durationMS: Int,
        guardBlocked: Bool,
        blockerCategory: String)
    {
        self.schemaVersion = schemaVersion
        self.timestamp = timestamp
        self.tool = tool
        self.provider = provider
        self.status = status
        self.model = model
        self.rawBytes = rawBytes
        self.excerptBytes = excerptBytes
        self.rawLines = rawLines
        self.estimatedRawTokens = estimatedRawTokens
        self.estimatedExcerptTokens = estimatedExcerptTokens
        self.estimatedTokensSaved = estimatedTokensSaved
        self.durationMS = durationMS
        self.guardBlocked = guardBlocked
        self.blockerCategory = blockerCategory
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case timestamp
        case tool
        case provider
        case status
        case model
        case rawBytes = "raw_bytes"
        case excerptBytes = "excerpt_bytes"
        case rawLines = "raw_lines"
        case estimatedRawTokens = "estimated_raw_tokens"
        case estimatedExcerptTokens = "estimated_excerpt_tokens"
        case estimatedTokensSaved = "estimated_tokens_saved"
        case durationMS = "duration_ms"
        case guardBlocked = "guard_blocked"
        case blockerCategory = "blocker_category"
    }
}
