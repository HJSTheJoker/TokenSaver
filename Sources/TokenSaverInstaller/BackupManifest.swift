import Foundation
import TokenSaverCore

public struct BackupManifestFile: Codable, Equatable, Sendable {
    public let originalPath: String
    public let backupPath: String
    public let relativeBackupPath: String
    public let fileSize: Int
    public let modifiedTimeEpoch: Int
    public let modifiedTimeISO8601: String
    public let mode: String
    public let sha256: String
}

public struct BackupManifest: Codable, Equatable, Sendable {
    public let backupTimestamp: String
    public let backupCreatedAtISO8601: String
    public let backupRoot: String
    public let files: [BackupManifestFile]
}
