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
                source: .safeDistill,
                status: .ok,
                model: "qwen3.5:2b",
                rawInputBytes: 1_000,
                smallModelInputBytes: 200,
                summaryOutputBytes: 120,
                rawLines: 10,
                estimatedRawInputTokens: 250,
                estimatedSmallModelInputTokens: 50,
                estimatedSummaryOutputTokens: 30,
                estimatedBigModelTokensSaved: 220,
                estimatedSmallModelInputReduction: 200,
                durationMS: 100,
                guardBlocked: false,
                blockerCategory: "none"),
            TokenSaverEvent(
                timestamp: ISO8601DateFormatter().date(from: "2026-03-15T08:00:00Z")!,
                tool: "distill",
                provider: "codex",
                source: .distill,
                status: .ok,
                model: "qwen3.5:2b",
                rawInputBytes: 2_000,
                smallModelInputBytes: 2_000,
                summaryOutputBytes: 600,
                rawLines: 20,
                estimatedRawInputTokens: 500,
                estimatedSmallModelInputTokens: 500,
                estimatedSummaryOutputTokens: 150,
                estimatedBigModelTokensSaved: 350,
                estimatedSmallModelInputReduction: 0,
                durationMS: 50,
                guardBlocked: false,
                blockerCategory: "none"),
        ]

        let summary = TokenSaverSummaryBuilder.build(events: events, now: now, calendar: Calendar(identifier: .gregorian))
        #expect(summary.todayBigModelTokensSaved == 220)
        #expect(summary.last7DaysBigModelTokensSaved == 570)
        #expect(summary.last30DaysBigModelTokensSaved == 570)
        #expect(summary.successfulRuns == 2)
        #expect(summary.blockedRuns == 0)
        #expect(summary.failedRuns == 0)
        #expect(summary.latestModel == "qwen3.5:2b")
        #expect(summary.distillBreakdown.bigModelTokensSaved == 350)
        #expect(summary.safeDistillBreakdown.bigModelTokensSaved == 220)
    }

    @Test
    func decodesLegacySafeDistillShape() throws {
        let json = """
        {"schema_version":1,"timestamp":"2026-03-17T22:00:00Z","tool":"safe-distill","provider":"codex","status":"ok","model":"qwen3.5:2b","raw_bytes":12000,"excerpt_bytes":4200,"raw_lines":320,"estimated_raw_tokens":3000,"estimated_excerpt_tokens":1050,"estimated_tokens_saved":1950,"duration_ms":280,"guard_blocked":false,"blocker_category":"none"}
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let event = try decoder.decode(TokenSaverEvent.self, from: Data(json.utf8))
        #expect(event.source == .safeDistill)
        #expect(event.rawInputBytes == 12_000)
        #expect(event.smallModelInputBytes == 4_200)
        #expect(event.estimatedBigModelTokensSaved == 1_950)
    }
}
