import Foundation

public struct TokenSaverDailyPoint: Codable, Equatable, Sendable {
    public let day: String
    public let savedTokens: Int
    public let runs: Int

    public init(day: String, savedTokens: Int, runs: Int) {
        self.day = day
        self.savedTokens = savedTokens
        self.runs = runs
    }
}

public struct TokenSaverSummary: Codable, Equatable, Sendable {
    public let todaySavedTokens: Int
    public let last7DaysSavedTokens: Int
    public let last30DaysSavedTokens: Int
    public let successfulRuns: Int
    public let blockedRuns: Int
    public let failedRuns: Int
    public let averageCompressionRatio: Double
    public let latestModel: String?
    public let lastUpdated: Date?
    public let daily: [TokenSaverDailyPoint]

    public static let empty = TokenSaverSummary(
        todaySavedTokens: 0,
        last7DaysSavedTokens: 0,
        last30DaysSavedTokens: 0,
        successfulRuns: 0,
        blockedRuns: 0,
        failedRuns: 0,
        averageCompressionRatio: 0,
        latestModel: nil,
        lastUpdated: nil,
        daily: [])
}

public extension TokenSaverSummary {
    var totalRuns: Int {
        self.successfulRuns + self.blockedRuns + self.failedRuns
    }

    var successRate: Double {
        guard self.totalRuns > 0 else { return 0 }
        return Double(self.successfulRuns) / Double(self.totalRuns)
    }
}
