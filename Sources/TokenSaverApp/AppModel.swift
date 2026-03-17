import AppKit
import Foundation
import Observation
import TokenSaverCore

@MainActor
@Observable
final class AppModel {
    var summary: TokenSaverSummary = .empty
    var lastRefresh: Date?
    var refreshIntervalSeconds: Double = 120
    var showDebugDetails: Bool = false
    private var refreshTask: Task<Void, Never>?

    init() {
        self.refresh()
        self.startRefreshLoop()
    }

    func refresh() {
        let summary = TokenSaverStore.loadSummary()
        self.summary = summary
        self.lastRefresh = Date()
        TokenSaverWidgetSnapshotStore.save(TokenSaverWidgetSnapshot(summary: summary))
    }

    func openEventsFolder() {
        NSWorkspace.shared.open(TokenSaverPaths.eventsRoot())
    }

    func openBackupsFolder() {
        NSWorkspace.shared.open(TokenSaverPaths.backupRoot())
    }

    private func startRefreshLoop() {
        self.refreshTask?.cancel()
        self.refreshTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?.refreshIntervalSeconds ?? 120))
                self?.refresh()
            }
        }
    }
}
