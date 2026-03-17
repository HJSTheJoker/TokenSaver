import SwiftUI
import TokenSaverCore
import WidgetKit

struct TokenSaverEntry: TimelineEntry {
    let date: Date
    let snapshot: TokenSaverWidgetSnapshot
}

struct TokenSaverProvider: TimelineProvider {
    func placeholder(in context: Context) -> TokenSaverEntry {
        TokenSaverEntry(date: Date(), snapshot: TokenSaverWidgetSnapshot(summary: .empty))
    }

    func getSnapshot(in context: Context, completion: @escaping (TokenSaverEntry) -> Void) {
        let snapshot = TokenSaverWidgetSnapshotStore.load() ?? TokenSaverWidgetSnapshot(summary: .empty)
        completion(TokenSaverEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TokenSaverEntry>) -> Void) {
        let snapshot = TokenSaverWidgetSnapshotStore.load() ?? TokenSaverWidgetSnapshot(summary: .empty)
        let entry = TokenSaverEntry(date: Date(), snapshot: snapshot)
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30 * 60))))
    }
}

struct TokenSaverWidget: Widget {
    let kind = "TokenSaverWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: self.kind, provider: TokenSaverProvider()) { entry in
            VStack(alignment: .leading, spacing: 6) {
                Text("TokenSaver")
                    .font(.headline)
                Text("Today: ~\(TokenSaverFormatting.compactInt(entry.snapshot.todaySavedTokens))")
                Text("30d: ~\(TokenSaverFormatting.compactInt(entry.snapshot.last30DaysSavedTokens))")
                Text("Success: \(TokenSaverFormatting.percent(entry.snapshot.successRate))")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding()
        }
        .configurationDisplayName("TokenSaver")
        .description("See distill savings at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
