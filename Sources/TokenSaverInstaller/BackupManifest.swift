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

    enum CodingKeys: String, CodingKey {
        case originalPath = "original_path"
        case backupPath = "backup_path"
        case relativeBackupPath = "relative_backup_path"
        case fileSize = "file_size"
        case modifiedTimeEpoch = "modified_time_epoch"
        case modifiedTimeISO8601 = "modified_time_iso8601"
        case mode
        case sha256
    }
}

public struct BackupManifest: Codable, Equatable, Sendable {
    public let backupTimestamp: String
    public let backupCreatedAtISO8601: String
    public let backupRoot: String
    public let files: [BackupManifestFile]

    enum CodingKeys: String, CodingKey {
        case backupTimestamp = "backup_timestamp"
        case backupCreatedAtISO8601 = "backup_created_at_iso8601"
        case backupRoot = "backup_root"
        case files
    }
}
