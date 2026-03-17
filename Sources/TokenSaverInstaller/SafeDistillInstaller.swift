import CryptoKit
import Foundation

public struct InstallerResult: Sendable {
    public let message: String
    public let backupManifest: BackupManifest?
}

public enum SafeDistillInstallerError: LocalizedError {
    case unsupportedFileShape
    case alreadyInstalled
    case latestBackupMissing

    public var errorDescription: String? {
        switch self {
        case .unsupportedFileShape:
            return "safe-distill does not match the expected patch points for TokenSaver v1."
        case .alreadyInstalled:
            return "TokenSaver integration is already installed."
        case .latestBackupMissing:
            return "No TokenSaver backup manifest was found for uninstall."
        }
    }
}

public enum SafeDistillInstaller {
    public static let safeDistillURL = URL(fileURLWithPath: "/Users/harrysmith/.codex/bin/safe-distill", isDirectory: false)
    public static let skillURL = URL(fileURLWithPath: "/Users/harrysmith/.agents/skills/distill-default/SKILL.md", isDirectory: false)
    public static let agentsURL = URL(fileURLWithPath: "/Users/harrysmith/.codex/AGENTS.md", isDirectory: false)

    private static let beginMarker = "# TOKENSAVER EVENT EMITTER BEGIN"
    private static let endMarker = "# TOKENSAVER EVENT EMITTER END"

    public static func install() throws -> InstallerResult {
        let original = try String(contentsOf: self.safeDistillURL, encoding: .utf8)
        guard !original.contains(beginMarker) else { throw SafeDistillInstallerError.alreadyInstalled }

        let manifest = try FileBackupManager.createBackup(files: [
            (self.safeDistillURL, "bin/safe-distill"),
            (self.skillURL, "skills/distill-default/SKILL.md"),
            (self.agentsURL, "config/AGENTS.md"),
        ])

        let patched = try self.makePatchedScript(from: original)
        try patched.write(to: self.safeDistillURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: self.safeDistillURL.path)
        return InstallerResult(
            message: "Installed TokenSaver hook into safe-distill.",
            backupManifest: manifest)
    }

    public static func uninstall() throws -> InstallerResult {
        guard let manifest = FileBackupManager.latestManifest() else {
            throw SafeDistillInstallerError.latestBackupMissing
        }
        for file in manifest.files {
            try FileManager.default.removeItemIfExists(atPath: file.originalPath)
            try FileManager.default.copyItem(atPath: file.backupPath, toPath: file.originalPath)
            if let mode = Int(file.mode.replacingOccurrences(of: "0o", with: ""), radix: 8) {
                try FileManager.default.setAttributes([.posixPermissions: mode], ofItemAtPath: file.originalPath)
            }
        }
        return InstallerResult(
            message: "Restored safe-distill from backup \(manifest.backupTimestamp).",
            backupManifest: manifest)
    }

    private static func makePatchedScript(from original: String) throws -> String {
        let helperAnchor = "\nif __name__ == \"__main__\":\n"
        let successAnchor = "        sys.stdout.write(result.stdout)\n        maybe_stop_model(pre_existing_models)\n        cleanup_log(log_path, keep=False)\n        return 0\n"
        let blockedAnchor = "            return 0 if status == \"ok\" else 2\n"

        guard original.contains(helperAnchor),
              original.contains(successAnchor),
              original.contains(blockedAnchor)
        else {
            throw SafeDistillInstallerError.unsupportedFileShape
        }

        let helper = """

\(beginMarker)
def estimate_tokens_from_bytes(byte_count: int) -> int:
    return max(0, int(round(byte_count / 4)))


def write_tokensaver_event(
    *,
    status: str,
    question: str,
    log_path: str,
    excerpt: str,
    total_lines: int,
    duration_ms: int,
    blocker: str,
    guard_blocked: bool,
) -> None:
    try:
        from datetime import datetime, timezone
        import json

        home = Path.home()
        now = datetime.now(timezone.utc)
        event_dir = home / ".codex" / "tokensaver" / "events" / now.strftime("%Y") / now.strftime("%m")
        event_dir.mkdir(parents=True, exist_ok=True)
        event_path = event_dir / f"{now.strftime('%d')}.jsonl"

        raw_bytes = os.path.getsize(log_path) if os.path.exists(log_path) else len(excerpt.encode("utf-8"))
        excerpt_bytes = len(excerpt.encode("utf-8"))
        raw_tokens = estimate_tokens_from_bytes(raw_bytes)
        excerpt_tokens = estimate_tokens_from_bytes(excerpt_bytes)
        event = {
            "schema_version": 1,
            "timestamp": now.isoformat(),
            "tool": "safe-distill",
            "provider": "codex",
            "status": status,
            "model": SAFE_MODEL,
            "raw_bytes": raw_bytes,
            "excerpt_bytes": excerpt_bytes,
            "raw_lines": total_lines,
            "estimated_raw_tokens": raw_tokens,
            "estimated_excerpt_tokens": excerpt_tokens,
            "estimated_tokens_saved": max(0, raw_tokens - excerpt_tokens),
            "duration_ms": max(0, duration_ms),
            "guard_blocked": guard_blocked,
            "blocker_category": blocker or "none",
        }
        with event_path.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(event, separators=(",", ":")) + "\\n")
    except Exception:
        return
\(endMarker)
"""

        var patched = original.replacingOccurrences(of: helperAnchor, with: "\(helper)\(helperAnchor)")
        patched = patched.replacingOccurrences(
            of: blockedAnchor,
            with: """
            write_tokensaver_event(
                status=status,
                question=args.question,
                log_path=log_path,
                excerpt=excerpt,
                total_lines=0,
                duration_ms=0,
                blocker=blocker,
                guard_blocked=status != "ok",
            )
            return 0 if status == "ok" else 2
""")
        patched = patched.replacingOccurrences(
            of: successAnchor,
            with: """
        write_tokensaver_event(
            status="ok",
            question=args.question,
            log_path=log_path,
            excerpt=excerpt,
            total_lines=0,
            duration_ms=0,
            blocker="none",
            guard_blocked=False,
        )
        sys.stdout.write(result.stdout)
        maybe_stop_model(pre_existing_models)
        cleanup_log(log_path, keep=False)
        return 0
""")
        return patched
    }

    static func makePatchedScriptForTesting(_ original: String) throws -> String {
        try self.makePatchedScript(from: original)
    }
}

private extension FileManager {
    func removeItemIfExists(atPath path: String) throws {
        if self.fileExists(atPath: path) {
            try self.removeItem(atPath: path)
        }
    }
}
