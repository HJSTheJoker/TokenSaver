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
        var ratios: [Double] = []
        var dayBuckets: [String: (savedTokens: Int, runs: Int)] = [:]

        let formatter = dayFormatter

        for event in sorted {
            let eventDayStart = calendar.startOfDay(for: event.timestamp)
            let dayKey = formatter.string(from: eventDayStart)
            let existing = dayBuckets[dayKey] ?? (0, 0)
            dayBuckets[dayKey] = (existing.savedTokens + max(0, event.estimatedTokensSaved), existing.runs + 1)

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

            if event.rawBytes > 0 {
                ratios.append(1 - min(1, Double(event.excerptBytes) / Double(event.rawBytes)))
            }

            if eventDayStart == todayStart {
                todaySavedTokens += max(0, event.estimatedTokensSaved)
            }
            if eventDayStart >= sevenDaysAgo {
                last7DaysSavedTokens += max(0, event.estimatedTokensSaved)
            }
            if eventDayStart >= thirtyDaysAgo {
                last30DaysSavedTokens += max(0, event.estimatedTokensSaved)
            }
        }

        let daily = dayBuckets.keys.sorted().map { key in
            let bucket = dayBuckets[key] ?? (0, 0)
            return TokenSaverDailyPoint(day: key, savedTokens: bucket.savedTokens, runs: bucket.runs)
        }

        let averageCompressionRatio = ratios.isEmpty ? 0 : ratios.reduce(0, +) / Double(ratios.count)

        return TokenSaverSummary(
            todaySavedTokens: todaySavedTokens,
            last7DaysSavedTokens: last7DaysSavedTokens,
            last30DaysSavedTokens: last30DaysSavedTokens,
            successfulRuns: successfulRuns,
            blockedRuns: blockedRuns,
            failedRuns: failedRuns,
            averageCompressionRatio: averageCompressionRatio,
            latestModel: sorted.first?.model,
            lastUpdated: sorted.first?.timestamp,
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
