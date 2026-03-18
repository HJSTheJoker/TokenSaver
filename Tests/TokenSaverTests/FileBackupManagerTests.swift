import Foundation
import Testing
@testable import TokenSaverInstaller

struct FileBackupManagerTests {
    @Test
    func createBackupSupportsSymlinkSources() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let target = root.appendingPathComponent("distill.js", isDirectory: false)
        let symlink = root.appendingPathComponent("distill", isDirectory: false)
        let script = "#!/usr/bin/env node\nconsole.log('distill');\n"
        try script.write(to: target, atomically: true, encoding: .utf8)
        try FileManager.default.createSymbolicLink(at: symlink, withDestinationURL: target)

        let manifest = try FileBackupManager.createBackup(files: [
            (symlink, "bin/distill"),
        ])

        let backupURL = URL(fileURLWithPath: manifest.files[0].backupPath, isDirectory: false)
        let backupAttributes = try FileManager.default.attributesOfItem(atPath: backupURL.path)
        let backupType = backupAttributes[.type] as? FileAttributeType
        #expect(backupType == .typeSymbolicLink)
        #expect(manifest.files[0].originalPath == symlink.path)
        #expect(manifest.files[0].sha256.isEmpty == false)
    }
}
