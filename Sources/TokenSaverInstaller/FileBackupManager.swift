import CryptoKit
import Foundation
import TokenSaverCore

public enum FileBackupManager {
    public static func createBackup(files: [(source: URL, relativeBackupPath: String)]) throws -> BackupManifest {
        let now = Date()
        let timestamp = Self.timestampFormatter.string(from: now)
        let backupRoot = TokenSaverPaths.backupRoot().appendingPathComponent(timestamp, isDirectory: true)
        try FileManager.default.createDirectory(at: backupRoot, withIntermediateDirectories: true)

        var manifestFiles: [BackupManifestFile] = []
        for file in files {
            let destination = backupRoot.appendingPathComponent(file.relativeBackupPath, isDirectory: false)
            try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: file.source, to: destination)

            let sourceAttributes = try FileManager.default.attributesOfItem(atPath: file.source.path)
            let data = try Data(contentsOf: destination)
            let hash = SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
            let modified = (sourceAttributes[.modificationDate] as? Date) ?? now
            let size = (sourceAttributes[.size] as? NSNumber)?.intValue ?? data.count
            let permissions = (sourceAttributes[.posixPermissions] as? NSNumber)?.intValue ?? 0o644

            manifestFiles.append(
                BackupManifestFile(
                    originalPath: file.source.path,
                    backupPath: destination.path,
                    relativeBackupPath: file.relativeBackupPath,
                    fileSize: size,
                    modifiedTimeEpoch: Int(modified.timeIntervalSince1970),
                    modifiedTimeISO8601: Self.iso8601(modified),
                    mode: String(format: "0o%03o", permissions),
                    sha256: hash))
        }

        let manifest = BackupManifest(
            backupTimestamp: timestamp,
            backupCreatedAtISO8601: Self.iso8601(now),
            backupRoot: backupRoot.path,
            files: manifestFiles)
        let manifestURL = backupRoot.appendingPathComponent("manifest.json", isDirectory: false)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(manifest).write(to: manifestURL, options: [.atomic])
        return manifest
    }

    public static func latestManifest() -> BackupManifest? {
        let root = TokenSaverPaths.backupRoot()
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles])
        else { return nil }

        let manifestURL = contents.sorted(by: { $0.lastPathComponent > $1.lastPathComponent }).first?
            .appendingPathComponent("manifest.json", isDirectory: false)
        guard let manifestURL, let data = try? Data(contentsOf: manifestURL) else { return nil }
        return try? JSONDecoder().decode(BackupManifest.self, from: data)
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return formatter
    }()

    private static func iso8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }
}
