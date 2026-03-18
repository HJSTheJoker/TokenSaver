import Foundation

public struct InstallerResult: Sendable {
    public let message: String
    public let backupManifest: BackupManifest?
}

public enum SafeDistillInstallerError: LocalizedError {
    case unsupportedFileShape(path: String)
    case alreadyInstalled(path: String)
    case latestBackupMissing

    public var errorDescription: String? {
        switch self {
        case let .unsupportedFileShape(path):
            return "TokenSaver could not safely patch \(path)."
        case let .alreadyInstalled(path):
            return "TokenSaver integration is already installed for \(path)."
        case .latestBackupMissing:
            return "No TokenSaver backup manifest was found for uninstall."
        }
    }
}

public enum SafeDistillInstaller {
    public static let safeDistillURL = URL(fileURLWithPath: "/Users/harrysmith/.codex/bin/safe-distill", isDirectory: false)
    public static let distillURL = URL(fileURLWithPath: "/Users/harrysmith/.volta/tools/image/packages/@samuelfaj/distill/bin/distill", isDirectory: false)
    public static let skillURL = URL(fileURLWithPath: "/Users/harrysmith/.agents/skills/distill-default/SKILL.md", isDirectory: false)
    public static let agentsURL = URL(fileURLWithPath: "/Users/harrysmith/.codex/AGENTS.md", isDirectory: false)

    private static let safeBeginMarker = "# TOKENSAVER SAFE-DISTILL EVENT EMITTER BEGIN"
    private static let safeEndMarker = "# TOKENSAVER SAFE-DISTILL EVENT EMITTER END"
    private static let distillBeginMarker = "// TOKENSAVER DISTILL EVENT EMITTER BEGIN"
    private static let distillEndMarker = "// TOKENSAVER DISTILL EVENT EMITTER END"

    public static func install() throws -> InstallerResult {
        let safeOriginal = try String(contentsOf: self.safeDistillURL, encoding: .utf8)
        let distillOriginal = try String(contentsOf: self.distillURL, encoding: .utf8)

        guard !safeOriginal.contains(self.safeBeginMarker) else {
            throw SafeDistillInstallerError.alreadyInstalled(path: self.safeDistillURL.path)
        }
        guard !distillOriginal.contains(self.distillBeginMarker) else {
            throw SafeDistillInstallerError.alreadyInstalled(path: self.distillURL.path)
        }

        let patchedSafe = try self.makePatchedSafeDistillScript(from: safeOriginal)
        let patchedDistill = try self.makePatchedDistillScript(from: distillOriginal)

        let manifest = try FileBackupManager.createBackup(files: [
            (self.safeDistillURL, "bin/safe-distill"),
            (self.distillURL, "bin/distill"),
            (self.skillURL, "skills/distill-default/SKILL.md"),
            (self.agentsURL, "config/AGENTS.md"),
        ])

        do {
            try patchedSafe.write(to: self.safeDistillURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: self.safeDistillURL.path)
            try patchedDistill.write(to: self.distillURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: self.distillURL.path)
        } catch {
            // Best-effort rollback so install is not left partially applied.
            for file in manifest.files {
                try? FileManager.default.removeItemIfExists(atPath: file.originalPath)
                try? FileManager.default.copyItem(atPath: file.backupPath, toPath: file.originalPath)
                if let mode = Int(file.mode.replacingOccurrences(of: "0o", with: ""), radix: 8) {
                    try? FileManager.default.setAttributes([.posixPermissions: mode], ofItemAtPath: file.originalPath)
                }
            }
            throw error
        }

        return InstallerResult(
            message: "Installed TokenSaver hooks into distill and safe-distill.",
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
            message: "Restored distill integrations from backup \(manifest.backupTimestamp).",
            backupManifest: manifest)
    }

    public static func safeDistillHookInstalled() -> Bool {
        ((try? String(contentsOf: self.safeDistillURL, encoding: .utf8)) ?? "").contains(self.safeBeginMarker)
    }

    public static func distillHookInstalled() -> Bool {
        ((try? String(contentsOf: self.distillURL, encoding: .utf8)) ?? "").contains(self.distillBeginMarker)
    }

    private static func makePatchedSafeDistillScript(from original: String) throws -> String {
        let startAnchor = "def main() -> int:\n"
        let readAnchor = "    log_path, excerpt, _ = read_stdin_to_log()\n"
        let helperAnchor = "\nif __name__ == \"__main__\":\n"
        let lockBusyReturnAnchor = "        return 2\n\n    try:\n"
        let dryRunAnchor = "            return 0 if status == \"ok\" else 2\n"
        let invocationFailureAnchor = """
            return 3
        except subprocess.TimeoutExpired:
"""
        let timeoutFailureAnchor = """
            return 3

        if result.returncode != 0:
"""
        let nonZeroFailureAnchor = """
            return 3

        sys.stdout.write(result.stdout)
"""
        let successAnchor = "        sys.stdout.write(result.stdout)\n        maybe_stop_model(pre_existing_models)\n        cleanup_log(log_path, keep=False)\n        return 0\n"

        guard original.contains(startAnchor),
              original.contains(readAnchor),
              original.contains(helperAnchor),
              original.contains(lockBusyReturnAnchor),
              original.contains(dryRunAnchor),
              original.contains(invocationFailureAnchor),
              original.contains(timeoutFailureAnchor),
              original.contains(nonZeroFailureAnchor),
              original.contains(successAnchor)
        else {
            throw SafeDistillInstallerError.unsupportedFileShape(path: self.safeDistillURL.path)
        }

        let helper = """

\(self.safeBeginMarker)
def estimate_tokens_from_bytes(byte_count: int) -> int:
    return max(0, int(round(byte_count / 4)))


def write_tokensaver_event(
    *,
    source: str,
    status: str,
    log_path: str,
    excerpt: str,
    summary_output: str,
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

        raw_input_bytes = os.path.getsize(log_path) if os.path.exists(log_path) else len(excerpt.encode("utf-8"))
        small_model_input_bytes = len(excerpt.encode("utf-8"))
        summary_output_bytes = len((summary_output or "").encode("utf-8"))
        raw_input_tokens = estimate_tokens_from_bytes(raw_input_bytes)
        small_model_input_tokens = estimate_tokens_from_bytes(small_model_input_bytes)
        summary_output_tokens = estimate_tokens_from_bytes(summary_output_bytes)
        big_model_tokens_saved = max(0, raw_input_tokens - summary_output_tokens) if status == "ok" else 0
        small_model_input_reduction = max(0, raw_input_tokens - small_model_input_tokens)
        event = {
            "schema_version": 2,
            "timestamp": now.isoformat(),
            "tool": "safe-distill",
            "provider": "codex",
            "source": source,
            "status": status,
            "model": SAFE_MODEL,
            "raw_input_bytes": raw_input_bytes,
            "small_model_input_bytes": small_model_input_bytes,
            "summary_output_bytes": summary_output_bytes,
            "raw_lines": total_lines,
            "estimated_raw_input_tokens": raw_input_tokens,
            "estimated_small_model_input_tokens": small_model_input_tokens,
            "estimated_summary_output_tokens": summary_output_tokens,
            "estimated_big_model_tokens_saved": big_model_tokens_saved,
            "estimated_small_model_input_reduction": small_model_input_reduction,
            "duration_ms": max(0, duration_ms),
            "guard_blocked": guard_blocked,
            "blocker_category": blocker or "none",
        }
        with event_path.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(event, separators=(",", ":")) + "\\n")
    except Exception:
        return
\(self.safeEndMarker)
"""

        var patched = original.replacingOccurrences(of: startAnchor, with: """
\(startAnchor)    started_at = time.time()

""")
        patched = patched.replacingOccurrences(of: readAnchor, with: "    log_path, excerpt, total_lines = read_stdin_to_log()\n")
        patched = patched.replacingOccurrences(of: helperAnchor, with: "\(helper)\(helperAnchor)")
        patched = patched.replacingOccurrences(
            of: lockBusyReturnAnchor,
            with: """
        write_tokensaver_event(
            source="safe-distill",
            status="blocked",
            log_path=log_path,
            excerpt=excerpt,
            summary_output="",
            total_lines=total_lines,
            duration_ms=int((time.time() - started_at) * 1000),
            blocker=f"another safe-distill run is still active after {WAIT_TIMEOUT_SECONDS}s",
            guard_blocked=True,
        )
        return 2

    try:

""")
        patched = patched.replacingOccurrences(
            of: dryRunAnchor,
            with: """
            write_tokensaver_event(
                source="safe-distill",
                status="dry_run" if args.dry_run else status,
                log_path=log_path,
                excerpt=excerpt,
                summary_output="",
                total_lines=total_lines,
                duration_ms=int((time.time() - started_at) * 1000),
                blocker=blocker,
                guard_blocked=status != "ok",
            )
            return 0 if status == "ok" else 2

""")
        patched = patched.replacingOccurrences(
            of: invocationFailureAnchor,
            with: """
            write_tokensaver_event(
                source="safe-distill",
                status="blocked",
                log_path=log_path,
                excerpt=excerpt,
                summary_output="",
                total_lines=total_lines,
                duration_ms=int((time.time() - started_at) * 1000),
                blocker=f"distill invocation failed: {exc}",
                guard_blocked=True,
            )
            return 3
        except subprocess.TimeoutExpired:
""")
        patched = patched.replacingOccurrences(
            of: timeoutFailureAnchor,
            with: """
            write_tokensaver_event(
                source="safe-distill",
                status="blocked",
                log_path=log_path,
                excerpt=excerpt,
                summary_output="",
                total_lines=total_lines,
                duration_ms=int((time.time() - started_at) * 1000),
                blocker=f"distill timed out after {DISTILL_TIMEOUT_MS}ms",
                guard_blocked=True,
            )
            return 3

        if result.returncode != 0:
""")
        patched = patched.replacingOccurrences(
            of: nonZeroFailureAnchor,
            with: """
            write_tokensaver_event(
                source="safe-distill",
                status="blocked",
                log_path=log_path,
                excerpt=excerpt,
                summary_output=(result.stderr or result.stdout or ""),
                total_lines=total_lines,
                duration_ms=int((time.time() - started_at) * 1000),
                blocker=f"distill exited with code {result.returncode}",
                guard_blocked=True,
            )
            return 3

        sys.stdout.write(result.stdout)
""")
        patched = patched.replacingOccurrences(
            of: successAnchor,
            with: """
        write_tokensaver_event(
            source="safe-distill",
            status="ok",
            log_path=log_path,
            excerpt=excerpt,
            summary_output=result.stdout,
            total_lines=total_lines,
            duration_ms=int((time.time() - started_at) * 1000),
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

    private static func makePatchedDistillScript(from original: String) throws -> String {
        let helperAnchor = "const binPath = resolveBinaryPath();\n"
        let spawnAnchor = "const child = spawn(binPath, process.argv.slice(2), {\n  stdio: [\"inherit\", \"pipe\", \"pipe\"],\n"
        let startProgressAnchor = "\nstartProgress();\n"
        let stdoutAnchor = """
child.stdout.on("data", (chunk) => {
  stopProgress();
  process.stdout.write(chunk);
});
"""
        let errorAnchor = """
child.on("error", (error) => {
  stopProgress();
  console.error(`[distill] Failed to launch native binary: ${error.message}`);
  process.exit(1);
});
"""
        let exitBlock = """
child.on("exit", (code, signal) => {
  flushChildStderr(true);
  stopProgress();

  if (signal) {
    process.removeAllListeners(signal);
    process.kill(process.pid, signal);
    return;
  }

  process.exit(code ?? 1);
});
"""
        let exitAnchor = "child.on(\"exit\", (code, signal) => {\n"

        guard original.contains(helperAnchor),
              original.contains(spawnAnchor),
              original.contains(startProgressAnchor),
              original.contains(stdoutAnchor),
              original.contains(errorAnchor),
              original.contains(exitBlock),
              original.contains(exitAnchor)
        else {
            throw SafeDistillInstallerError.unsupportedFileShape(path: self.distillURL.path)
        }

        let helper = """
\(self.distillBeginMarker)
const fs = require(\"node:fs\");
const os = require(\"node:os\");

function estimateTokensFromBytes(byteCount) {
  return Math.max(0, Math.round(byteCount / 4));
}

function resolveModelArg(argv) {
  const modelIndex = argv.indexOf(\"--model\");
  if (modelIndex >= 0 && argv[modelIndex + 1]) {
    return argv[modelIndex + 1];
  }
  return \"qwen3.5:2b\";
}

function writeTokenSaverEvent(event) {
  try {
    const now = new Date();
    const year = String(now.getUTCFullYear());
    const month = String(now.getUTCMonth() + 1).padStart(2, \"0\");
    const day = String(now.getUTCDate()).padStart(2, \"0\");
    const root = path.join(os.homedir(), \".codex\", \"tokensaver\", \"events\", year, month);
    fs.mkdirSync(root, { recursive: true });
    const eventPath = path.join(root, `${day}.jsonl`);
    fs.appendFileSync(eventPath, `${JSON.stringify(event)}\\n`, \"utf8\");
  } catch (_) {}
}

const tokenSaverStartAt = Date.now();
let tokenSaverRawInputBytes = 0;
let tokenSaverSummaryOutputBytes = 0;
let tokenSaverRawLines = 0;
const tokenSaverModel = resolveModelArg(process.argv.slice(2));
\(self.distillEndMarker)
"""

        var patched = original.replacingOccurrences(of: helperAnchor, with: "\(helperAnchor)\(helper)\n")
        patched = patched.replacingOccurrences(
            of: spawnAnchor,
            with: """
const child = spawn(binPath, process.argv.slice(2), {
  stdio: ["pipe", "pipe", "pipe"],
""")
        patched = patched.replacingOccurrences(
            of: startProgressAnchor,
            with: """

process.stdin.on("data", (chunk) => {
  tokenSaverRawInputBytes += chunk.length;
  for (const byte of chunk) {
    if (byte === 10) {
      tokenSaverRawLines += 1;
    }
  }
  child.stdin.write(chunk);
});
process.stdin.on("end", () => {
  child.stdin.end();
});
process.stdin.on("error", () => {
  child.stdin.end();
});
if (process.stdin.isTTY) {
  process.stdin.resume();
}
\(startProgressAnchor)
""")
        patched = patched.replacingOccurrences(
            of: stdoutAnchor,
            with: """
child.stdout.on("data", (chunk) => {
  stopProgress();
  tokenSaverSummaryOutputBytes += chunk.length;
  process.stdout.write(chunk);
});
""")
        patched = patched.replacingOccurrences(
            of: errorAnchor,
            with: """
child.on("error", (error) => {
  stopProgress();
  writeTokenSaverEvent({
    schema_version: 2,
    timestamp: new Date().toISOString(),
    tool: "distill",
    provider: "codex",
    source: "distill",
    status: "failed",
    model: tokenSaverModel,
    raw_input_bytes: tokenSaverRawInputBytes,
    small_model_input_bytes: tokenSaverRawInputBytes,
    summary_output_bytes: tokenSaverSummaryOutputBytes,
    raw_lines: tokenSaverRawLines,
    estimated_raw_input_tokens: estimateTokensFromBytes(tokenSaverRawInputBytes),
    estimated_small_model_input_tokens: estimateTokensFromBytes(tokenSaverRawInputBytes),
    estimated_summary_output_tokens: estimateTokensFromBytes(tokenSaverSummaryOutputBytes),
    estimated_big_model_tokens_saved: 0,
    estimated_small_model_input_reduction: 0,
    duration_ms: Date.now() - tokenSaverStartAt,
    guard_blocked: false,
    blocker_category: `launch:${error.message}`
  });
  console.error(`[distill] Failed to launch native binary: ${error.message}`);
  process.exit(1);
});
""")
        patched = patched.replacingOccurrences(
            of: exitBlock,
            with: """
child.on("exit", (code, signal) => {
  const durationMS = Date.now() - tokenSaverStartAt;
  const rawInputTokens = estimateTokensFromBytes(tokenSaverRawInputBytes);
  const summaryOutputTokens = estimateTokensFromBytes(tokenSaverSummaryOutputBytes);
  const bigModelTokensSaved = code === 0 ? Math.max(0, rawInputTokens - summaryOutputTokens) : 0;
  writeTokenSaverEvent({
    schema_version: 2,
    timestamp: new Date().toISOString(),
    tool: "distill",
    provider: "codex",
    source: "distill",
    status: code === 0 ? "ok" : "failed",
    model: tokenSaverModel,
    raw_input_bytes: tokenSaverRawInputBytes,
    small_model_input_bytes: tokenSaverRawInputBytes,
    summary_output_bytes: tokenSaverSummaryOutputBytes,
    raw_lines: tokenSaverRawLines,
    estimated_raw_input_tokens: rawInputTokens,
    estimated_small_model_input_tokens: rawInputTokens,
    estimated_summary_output_tokens: summaryOutputTokens,
    estimated_big_model_tokens_saved: bigModelTokensSaved,
    estimated_small_model_input_reduction: 0,
    duration_ms: durationMS,
    guard_blocked: false,
    blocker_category: code === 0 ? "none" : signal ? `signal:${signal}` : `exit:${code ?? 1}`
  });
  flushChildStderr(true);
  stopProgress();

  if (signal) {
    process.removeAllListeners(signal);
    process.kill(process.pid, signal);
    return;
  }

  process.exit(code ?? 1);
});
""")
        return patched
    }

    static func makePatchedScriptForTesting(_ original: String) throws -> String {
        try self.makePatchedSafeDistillScript(from: original)
    }

    static func makePatchedDistillScriptForTesting(_ original: String) throws -> String {
        try self.makePatchedDistillScript(from: original)
    }
}

private extension FileManager {
    func removeItemIfExists(atPath path: String) throws {
        if self.fileExists(atPath: path) {
            try self.removeItem(atPath: path)
        }
    }
}
