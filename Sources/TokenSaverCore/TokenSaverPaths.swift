import Foundation

public enum TokenSaverPaths {
    public static let appGroupID = "group.com.hjsthejoker.tokensaver"

    public static func eventsRoot() -> URL {
        Path.homeDirectory
            .appendingPathComponent(".codex", isDirectory: true)
            .appendingPathComponent("tokensaver", isDirectory: true)
            .appendingPathComponent("events", isDirectory: true)
    }

    public static func backupRoot() -> URL {
        Path.homeDirectory
            .appendingPathComponent(".codex", isDirectory: true)
            .appendingPathComponent("backups", isDirectory: true)
            .appendingPathComponent("tokensaver-bootstrap", isDirectory: true)
    }

    public static func widgetSnapshotURL(bundleID: String? = Bundle.main.bundleIdentifier) -> URL {
        let fm = FileManager.default
        #if os(macOS)
        if let bundleID,
           let groupURL = fm.containerURL(forSecurityApplicationGroupIdentifier: appGroupID(for: bundleID))
        {
            return groupURL.appendingPathComponent("widget-snapshot.json", isDirectory: false)
        }
        #endif
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fm.temporaryDirectory
        let dir = base.appendingPathComponent("TokenSaver", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("widget-snapshot.json", isDirectory: false)
    }

    public static func appGroupID(for bundleID: String) -> String {
        bundleID.contains(".debug") ? "\(appGroupID).debug" : appGroupID
    }
}

public enum Path {
    public static let homeDirectory = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
}
