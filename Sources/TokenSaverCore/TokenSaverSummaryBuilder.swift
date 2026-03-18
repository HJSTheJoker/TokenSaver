import Foundation

public enum TokenSaverSummaryBuilder {
    public static func build(events: [TokenSaverEvent], now: Date = Date(), calendar: Calendar = .current) -> TokenSaverSummary {
        guard !events.isEmpty else { return .empty }

        let sorted = events.sorted { $0.timestamp > $1.timestamp }
        let todayStart = calendar.startOfDay(for: now)
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: todayStart) ?? todayStart
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -29, to: todayStart) ?? todayStart

        var todaySavedTokens = 0
        var last7DaysSavedTokens = 0
        var last30DaysSavedTokens = 0
        var successfulRuns = 0
        var blockedRuns = 0
        var failedRuns = 0
        var bigModelRatios: [Double] = []
        var smallModelRatios: [Double] = []
        var sourceBuckets: [TokenSaverSource: (runCount: Int, savedTokens: Int)] = [:]
        var dayBuckets: [String: (savedTokens: Int, runs: Int, distillTokensSaved: Int, safeDistillTokensSaved: Int)] = [:]

        let formatter = dayFormatter

        for event in sorted {
            let eventDayStart = calendar.startOfDay(for: event.timestamp)
            let dayKey = formatter.string(from: eventDayStart)
            let existing = dayBuckets[dayKey] ?? (0, 0, 0, 0)
            let saved = max(0, event.estimatedBigModelTokensSaved)
            let distillSaved = event.source == .distill ? saved : 0
            let safeSaved = event.source == .safeDistill ? saved : 0
            dayBuckets[dayKey] = (
                existing.savedTokens + saved,
                existing.runs + 1,
                existing.distillTokensSaved + distillSaved,
                existing.safeDistillTokensSaved + safeSaved
            )
            let sourceExisting = sourceBuckets[event.source] ?? (0, 0)
            sourceBuckets[event.source] = (sourceExisting.runCount + 1, sourceExisting.savedTokens + saved)

            switch event.status {
            case .ok:
                successfulRuns += 1
            case .blocked:
                blockedRuns += 1
            case .failed:
                failedRuns += 1
            case .dryRun:
                break
            }

            if event.rawInputBytes > 0 {
                bigModelRatios.append(1 - min(1, Double(event.summaryOutputBytes) / Double(event.rawInputBytes)))
                smallModelRatios.append(1 - min(1, Double(event.smallModelInputBytes) / Double(event.rawInputBytes)))
            }

            if eventDayStart == todayStart {
                todaySavedTokens += saved
            }
            if eventDayStart >= sevenDaysAgo {
                last7DaysSavedTokens += saved
            }
            if eventDayStart >= thirtyDaysAgo {
                last30DaysSavedTokens += saved
            }
        }

        let daily = dayBuckets.keys.sorted().map { key in
            let bucket = dayBuckets[key] ?? (0, 0, 0, 0)
            return TokenSaverDailyPoint(
                day: key,
                bigModelTokensSaved: bucket.savedTokens,
                runs: bucket.runs,
                distillTokensSaved: bucket.distillTokensSaved,
                safeDistillTokensSaved: bucket.safeDistillTokensSaved)
        }
        let sourceBreakdown = TokenSaverSource.allCases.map { source in
            let bucket = sourceBuckets[source] ?? (0, 0)
            return TokenSaverSourceSummary(source: source, runCount: bucket.runCount, bigModelTokensSaved: bucket.savedTokens)
        }
        let averageBigModelCompressionRatio = bigModelRatios.isEmpty ? 0 : bigModelRatios.reduce(0, +) / Double(bigModelRatios.count)
        let averageSmallModelInputReductionRatio = smallModelRatios.isEmpty ? 0 : smallModelRatios.reduce(0, +) / Double(smallModelRatios.count)

        return TokenSaverSummary(
            todayBigModelTokensSaved: todaySavedTokens,
            last7DaysBigModelTokensSaved: last7DaysSavedTokens,
            last30DaysBigModelTokensSaved: last30DaysSavedTokens,
            successfulRuns: successfulRuns,
            blockedRuns: blockedRuns,
            failedRuns: failedRuns,
            averageBigModelCompressionRatio: averageBigModelCompressionRatio,
            averageSmallModelInputReductionRatio: averageSmallModelInputReductionRatio,
            latestModel: sorted.first?.model,
            lastUpdated: sorted.first?.timestamp,
            sourceBreakdown: sourceBreakdown,
            daily: daily)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
