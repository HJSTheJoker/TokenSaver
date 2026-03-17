import Foundation

public struct TokenSaverWidgetSnapshot: Codable, Equatable, Sendable {
    public let generatedAt: Date
    public let todaySavedTokens: Int
    public let last30DaysSavedTokens: Int
    public let successRate: Double
    public let totalRuns: Int
    public let latestModel: String?
    public let lastUpdated: Date?

    public init(summary: TokenSaverSummary, generatedAt: Date = Date()) {
        self.generatedAt = generatedAt
        self.todaySavedTokens = summary.todaySavedTokens
        self.last30DaysSavedTokens = summary.last30DaysSavedTokens
        self.successRate = summary.successRate
        self.totalRuns = summary.totalRuns
        self.latestModel = summary.latestModel
        self.lastUpdated = summary.lastUpdated
    }
}

public enum TokenSaverWidgetSnapshotStore {
    public static func load(bundleID: String? = Bundle.main.bundleIdentifier) -> TokenSaverWidgetSnapshot? {
        guard let data = try? Data(contentsOf: TokenSaverPaths.widgetSnapshotURL(bundleID: bundleID)) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(TokenSaverWidgetSnapshot.self, from: data)
    }

    public static func save(_ snapshot: TokenSaverWidgetSnapshot, bundleID: String? = Bundle.main.bundleIdentifier) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: TokenSaverPaths.widgetSnapshotURL(bundleID: bundleID), options: [.atomic])
    }
}
