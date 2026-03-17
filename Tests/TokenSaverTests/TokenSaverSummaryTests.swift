import Foundation
import Testing
@testable import TokenSaverCore

struct TokenSaverSummaryTests {
    @Test
    func aggregatesTokenSavingsAcrossWindows() throws {
        let now = ISO8601DateFormatter().date(from: "2026-03-17T12:00:00Z")!
        let events = [
            TokenSaverEvent(
                timestamp: ISO8601DateFormatter().date(from: "2026-03-17T08:00:00Z")!,
                tool: "safe-distill",
                provider: "codex",
                status: .ok,
                model: "qwen3.5:2b",
                rawBytes: 1_000,
                excerptBytes: 200,
                rawLines: 10,
                estimatedRawTokens: 250,
                estimatedExcerptTokens: 50,
                estimatedTokensSaved: 200,
                durationMS: 100,
                guardBlocked: false,
                blockerCategory: "none"),
            TokenSaverEvent(
                timestamp: ISO8601DateFormatter().date(from: "2026-03-15T08:00:00Z")!,
                tool: "safe-distill",
                provider: "codex",
                status: .blocked,
                model: "qwen3.5:2b",
                rawBytes: 2_000,
                excerptBytes: 500,
                rawLines: 20,
                estimatedRawTokens: 500,
                estimatedExcerptTokens: 125,
                estimatedTokensSaved: 375,
                durationMS: 50,
                guardBlocked: true,
                blockerCategory: "memory-pressure"),
        ]

        let summary = TokenSaverSummaryBuilder.build(events: events, now: now, calendar: Calendar(identifier: .gregorian))
        #expect(summary.todaySavedTokens == 200)
        #expect(summary.last7DaysSavedTokens == 575)
        #expect(summary.last30DaysSavedTokens == 575)
        #expect(summary.successfulRuns == 1)
        #expect(summary.blockedRuns == 1)
        #expect(summary.failedRuns == 0)
        #expect(summary.latestModel == "qwen3.5:2b")
    }
}
