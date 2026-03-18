import Foundation

public enum TokenSaverSource: String, Codable, CaseIterable, Sendable {
    case distill
    case safeDistill = "safe-distill"
}

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
    public let source: TokenSaverSource
    public let status: TokenSaverEventStatus
    public let model: String
    public let rawInputBytes: Int
    public let smallModelInputBytes: Int
    public let summaryOutputBytes: Int
    public let rawLines: Int
    public let estimatedRawInputTokens: Int
    public let estimatedSmallModelInputTokens: Int
    public let estimatedSummaryOutputTokens: Int
    public let estimatedBigModelTokensSaved: Int
    public let estimatedSmallModelInputReduction: Int
    public let durationMS: Int
    public let guardBlocked: Bool
    public let blockerCategory: String

    public init(
        schemaVersion: Int = 2,
        timestamp: Date,
        tool: String,
        provider: String,
        source: TokenSaverSource,
        status: TokenSaverEventStatus,
        model: String,
        rawInputBytes: Int,
        smallModelInputBytes: Int,
        summaryOutputBytes: Int,
        rawLines: Int,
        estimatedRawInputTokens: Int,
        estimatedSmallModelInputTokens: Int,
        estimatedSummaryOutputTokens: Int,
        estimatedBigModelTokensSaved: Int,
        estimatedSmallModelInputReduction: Int,
        durationMS: Int,
        guardBlocked: Bool,
        blockerCategory: String)
    {
        self.schemaVersion = schemaVersion
        self.timestamp = timestamp
        self.tool = tool
        self.provider = provider
        self.source = source
        self.status = status
        self.model = model
        self.rawInputBytes = rawInputBytes
        self.smallModelInputBytes = smallModelInputBytes
        self.summaryOutputBytes = summaryOutputBytes
        self.rawLines = rawLines
        self.estimatedRawInputTokens = estimatedRawInputTokens
        self.estimatedSmallModelInputTokens = estimatedSmallModelInputTokens
        self.estimatedSummaryOutputTokens = estimatedSummaryOutputTokens
        self.estimatedBigModelTokensSaved = estimatedBigModelTokensSaved
        self.estimatedSmallModelInputReduction = estimatedSmallModelInputReduction
        self.durationMS = durationMS
        self.guardBlocked = guardBlocked
        self.blockerCategory = blockerCategory
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case timestamp
        case tool
        case provider
        case source
        case status
        case model
        case rawInputBytes = "raw_input_bytes"
        case smallModelInputBytes = "small_model_input_bytes"
        case summaryOutputBytes = "summary_output_bytes"
        case rawLines = "raw_lines"
        case estimatedRawInputTokens = "estimated_raw_input_tokens"
        case estimatedSmallModelInputTokens = "estimated_small_model_input_tokens"
        case estimatedSummaryOutputTokens = "estimated_summary_output_tokens"
        case estimatedBigModelTokensSaved = "estimated_big_model_tokens_saved"
        case estimatedSmallModelInputReduction = "estimated_small_model_input_reduction"
        case durationMS = "duration_ms"
        case guardBlocked = "guard_blocked"
        case blockerCategory = "blocker_category"

        // Legacy fields.
        case rawBytes = "raw_bytes"
        case excerptBytes = "excerpt_bytes"
        case estimatedRawTokens = "estimated_raw_tokens"
        case estimatedExcerptTokens = "estimated_excerpt_tokens"
        case estimatedTokensSaved = "estimated_tokens_saved"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.tool = try container.decode(String.self, forKey: .tool)
        self.provider = try container.decode(String.self, forKey: .provider)
        self.status = try container.decode(TokenSaverEventStatus.self, forKey: .status)
        self.model = try container.decode(String.self, forKey: .model)
        self.rawLines = try container.decodeIfPresent(Int.self, forKey: .rawLines) ?? 0
        self.durationMS = try container.decodeIfPresent(Int.self, forKey: .durationMS) ?? 0
        self.guardBlocked = try container.decodeIfPresent(Bool.self, forKey: .guardBlocked) ?? false
        self.blockerCategory = try container.decodeIfPresent(String.self, forKey: .blockerCategory) ?? "none"

        let legacyRawBytes = try container.decodeIfPresent(Int.self, forKey: .rawBytes)
        let legacyExcerptBytes = try container.decodeIfPresent(Int.self, forKey: .excerptBytes)
        let legacyRawTokens = try container.decodeIfPresent(Int.self, forKey: .estimatedRawTokens)
        let legacyExcerptTokens = try container.decodeIfPresent(Int.self, forKey: .estimatedExcerptTokens)
        let legacySavedTokens = try container.decodeIfPresent(Int.self, forKey: .estimatedTokensSaved)

        self.source =
            try container.decodeIfPresent(TokenSaverSource.self, forKey: .source)
            ?? (self.tool == "safe-distill" ? .safeDistill : .distill)
        self.rawInputBytes =
            try container.decodeIfPresent(Int.self, forKey: .rawInputBytes)
            ?? legacyRawBytes
            ?? 0
        self.smallModelInputBytes =
            try container.decodeIfPresent(Int.self, forKey: .smallModelInputBytes)
            ?? legacyExcerptBytes
            ?? self.rawInputBytes
        self.summaryOutputBytes =
            try container.decodeIfPresent(Int.self, forKey: .summaryOutputBytes)
            ?? legacyExcerptBytes
            ?? 0
        self.estimatedRawInputTokens =
            try container.decodeIfPresent(Int.self, forKey: .estimatedRawInputTokens)
            ?? legacyRawTokens
            ?? 0
        self.estimatedSmallModelInputTokens =
            try container.decodeIfPresent(Int.self, forKey: .estimatedSmallModelInputTokens)
            ?? legacyExcerptTokens
            ?? self.estimatedRawInputTokens
        self.estimatedSummaryOutputTokens =
            try container.decodeIfPresent(Int.self, forKey: .estimatedSummaryOutputTokens)
            ?? legacyExcerptTokens
            ?? 0
        self.estimatedBigModelTokensSaved =
            try container.decodeIfPresent(Int.self, forKey: .estimatedBigModelTokensSaved)
            ?? legacySavedTokens
            ?? max(0, self.estimatedRawInputTokens - self.estimatedSummaryOutputTokens)
        self.estimatedSmallModelInputReduction =
            try container.decodeIfPresent(Int.self, forKey: .estimatedSmallModelInputReduction)
            ?? max(0, self.estimatedRawInputTokens - self.estimatedSmallModelInputTokens)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.schemaVersion, forKey: .schemaVersion)
        try container.encode(self.timestamp, forKey: .timestamp)
        try container.encode(self.tool, forKey: .tool)
        try container.encode(self.provider, forKey: .provider)
        try container.encode(self.source, forKey: .source)
        try container.encode(self.status, forKey: .status)
        try container.encode(self.model, forKey: .model)
        try container.encode(self.rawInputBytes, forKey: .rawInputBytes)
        try container.encode(self.smallModelInputBytes, forKey: .smallModelInputBytes)
        try container.encode(self.summaryOutputBytes, forKey: .summaryOutputBytes)
        try container.encode(self.rawLines, forKey: .rawLines)
        try container.encode(self.estimatedRawInputTokens, forKey: .estimatedRawInputTokens)
        try container.encode(self.estimatedSmallModelInputTokens, forKey: .estimatedSmallModelInputTokens)
        try container.encode(self.estimatedSummaryOutputTokens, forKey: .estimatedSummaryOutputTokens)
        try container.encode(self.estimatedBigModelTokensSaved, forKey: .estimatedBigModelTokensSaved)
        try container.encode(self.estimatedSmallModelInputReduction, forKey: .estimatedSmallModelInputReduction)
        try container.encode(self.durationMS, forKey: .durationMS)
        try container.encode(self.guardBlocked, forKey: .guardBlocked)
        try container.encode(self.blockerCategory, forKey: .blockerCategory)
    }
}
