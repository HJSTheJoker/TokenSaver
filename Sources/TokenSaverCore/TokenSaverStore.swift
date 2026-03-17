import Foundation

public enum TokenSaverStore {
    public static func loadEvents(root: URL = TokenSaverPaths.eventsRoot()) -> [TokenSaverEvent] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: root.path) else { return [] }

        guard let enumerator = fm.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey]) else {
            return []
        }

        var events: [TokenSaverEvent] = []
        for case let url as URL in enumerator where url.pathExtension.lowercased() == "jsonl" {
            events.append(contentsOf: self.decodeEvents(from: url))
        }
        return events
    }

    public static func loadSummary(root: URL = TokenSaverPaths.eventsRoot(), now: Date = Date()) -> TokenSaverSummary {
        let events = self.loadEvents(root: root)
        return TokenSaverSummaryBuilder.build(events: events, now: now)
    }

    private static func decodeEvents(from url: URL) -> [TokenSaverEvent] {
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return contents
            .split(whereSeparator: \.isNewline)
            .compactMap { line in
                guard let data = line.data(using: .utf8) else { return nil }
                return try? decoder.decode(TokenSaverEvent.self, from: data)
            }
    }
}
