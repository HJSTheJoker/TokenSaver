import Foundation

public struct TokenSaverDailyPoint: Codable, Equatable, Sendable {
    public let day: String
    public let bigModelTokensSaved: Int
    public let runs: Int
    public let distillTokensSaved: Int
    public let safeDistillTokensSaved: Int

    public init(day: String, bigModelTokensSaved: Int, runs: Int, distillTokensSaved: Int, safeDistillTokensSaved: Int) {
        self.day = day
        self.bigModelTokensSaved = bigModelTokensSaved
        self.runs = runs
        self.distillTokensSaved = distillTokensSaved
        self.safeDistillTokensSaved = safeDistillTokensSaved
    }
}

public struct TokenSaverSourceSummary: Codable, Equatable, Sendable {
    public let source: TokenSaverSource
    public let runCount: Int
    public let bigModelTokensSaved: Int

    public init(source: TokenSaverSource, runCount: Int, bigModelTokensSaved: Int) {
        self.source = source
        self.runCount = runCount
        self.bigModelTokensSaved = bigModelTokensSaved
    }
}

public struct TokenSaverSummary: Codable, Equatable, Sendable {
    public let todayBigModelTokensSaved: Int
    public let last7DaysBigModelTokensSaved: Int
    public let last30DaysBigModelTokensSaved: Int
    public let successfulRuns: Int
    public let blockedRuns: Int
    public let failedRuns: Int
    public let averageBigModelCompressionRatio: Double
    public let averageSmallModelInputReductionRatio: Double
    public let latestModel: String?
    public let lastUpdated: Date?
    public let sourceBreakdown: [TokenSaverSourceSummary]
    public let daily: [TokenSaverDailyPoint]

    public static let empty = TokenSaverSummary(
        todayBigModelTokensSaved: 0,
        last7DaysBigModelTokensSaved: 0,
        last30DaysBigModelTokensSaved: 0,
        successfulRuns: 0,
        blockedRuns: 0,
        failedRuns: 0,
        averageBigModelCompressionRatio: 0,
        averageSmallModelInputReductionRatio: 0,
        latestModel: nil,
        lastUpdated: nil,
        sourceBreakdown: [],
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

    var distillBreakdown: TokenSaverSourceSummary {
        self.sourceBreakdown.first(where: { $0.source == .distill })
            ?? TokenSaverSourceSummary(source: .distill, runCount: 0, bigModelTokensSaved: 0)
    }

    var safeDistillBreakdown: TokenSaverSourceSummary {
        self.sourceBreakdown.first(where: { $0.source == .safeDistill })
            ?? TokenSaverSourceSummary(source: .safeDistill, runCount: 0, bigModelTokensSaved: 0)
    }
}
