import Testing
@testable import TokenSaverInstaller

struct SafeDistillInstallerTests {
    @Test
    func patchAddsMarkerBlock() throws {
        let source = """
#!/usr/bin/env python3
def main() -> int:
    log_path, excerpt, _ = read_stdin_to_log()
    lock = FileLock(LOCK_PATH)

    if not lock.acquire(WAIT_TIMEOUT_SECONDS, WAIT_POLL_SECONDS):
        busy_metrics = Metrics(None, None, None, None, [], ["distill lock busy"])
        print_guard_result(
            status="blocked",
            blocker=f"another safe-distill run is still active after {WAIT_TIMEOUT_SECONDS}s",
            next_action="retry later or inspect the saved log in small slices",
            metrics=busy_metrics,
            log_path=log_path,
        )
        return 2

    try:
        decision = wait_for_healthy_state()
        if args.dry_run or decision.state != "ok":
            status = "ok" if args.dry_run and decision.state == "ok" else "blocked"
            blocker = "none" if status == "ok" else decision.blocker
            print_guard_result(
                status=status,
                blocker=blocker,
                next_action="no distill call made" if args.dry_run else decision.next_action,
                metrics=decision.metrics,
                log_path=log_path,
            )
            return 0 if status == "ok" else 2
        pre_existing_models = list(decision.metrics.ollama_models)
        try:
            result = run_distill(excerpt, args.question)
        except (FileNotFoundError, OSError) as exc:
            failure_metrics = collect_metrics()
            print_guard_result(
                status="blocked",
                blocker=f"distill invocation failed: {exc}",
                next_action="install or restore distill, or inspect the saved log in small slices",
                metrics=failure_metrics,
                log_path=log_path,
            )
            return 3
        except subprocess.TimeoutExpired:
            timeout_metrics = collect_metrics()
            print_guard_result(
                status="blocked",
                blocker=f"distill timed out after {DISTILL_TIMEOUT_MS}ms",
                next_action="retry later or inspect the saved log in small slices",
                metrics=timeout_metrics,
                log_path=log_path,
            )
            return 3

        if result.returncode != 0:
            failure_metrics = collect_metrics()
            detail = trim_to_bytes((result.stderr or result.stdout or "").strip(), 512)
            print_guard_result(
                status="blocked",
                blocker=f"distill exited with code {result.returncode}",
                next_action="inspect the saved log in small slices, then retry when the local model path is healthy",
                metrics=failure_metrics,
                log_path=log_path,
                extra=detail or None,
            )
            return 3

        sys.stdout.write(result.stdout)
        maybe_stop_model(pre_existing_models)
        cleanup_log(log_path, keep=False)
        return 0
    finally:
        lock.release()

if __name__ == "__main__":
    raise SystemExit(main())
"""
        let patched = try SafeDistillInstaller.makePatchedScriptForTesting(source)
        #expect(patched.contains("TOKENSAVER SAFE-DISTILL EVENT EMITTER BEGIN"))
        #expect(patched.contains("write_tokensaver_event("))
        #expect(patched.contains("    started_at = time.time()\n    log_path, excerpt, total_lines = read_stdin_to_log()"))
        #expect(patched.contains("        return 2\n\n    try:\n        decision = wait_for_healthy_state()"))
        #expect(patched.contains("status=\"dry_run\" if args.dry_run else status"))
        #expect(patched.contains("            return 0 if status == \"ok\" else 2\n        pre_existing_models = list(decision.metrics.ollama_models)"))
        #expect(patched.contains("blocker=f\"distill invocation failed: {exc}\""))
        #expect(patched.contains("blocker=f\"distill timed out after {DISTILL_TIMEOUT_MS}ms\""))
        #expect(patched.contains("blocker=f\"distill exited with code {result.returncode}\""))
        #expect(patched.contains("        return 0\n    finally:\n        lock.release()"))
    }

    @Test
    func distillPatchAddsMarkerBlock() throws {
        let source = """
#!/usr/bin/env node
const path = require("node:path");

const PROGRESS_PREFIX = "__DISTILL_PROGRESS__:";
const PROGRESS_FRAMES = ["-", "\\\\", "|", "/"];
const PROGRESS_DOT_FRAMES = ["", ".", "..", "...", "..", "."];
const PROGRESS_LABELS = {
  collecting: "distill: waiting",
  summarizing: "distill: summarizing"
};

const binPath = resolveBinaryPath();
const child = spawn(binPath, process.argv.slice(2), {
  stdio: ["inherit", "pipe", "pipe"],
  env: {
    ...process.env,
    DISTILL_PROGRESS_PROTOCOL: "stderr"
  }
});

startProgress();

child.stdout.on("data", (chunk) => {
  stopProgress();
  process.stdout.write(chunk);
});

child.on("error", (error) => {
  stopProgress();
  console.error(`[distill] Failed to launch native binary: ${error.message}`);
  process.exit(1);
});

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
        let patched = try SafeDistillInstaller.makePatchedDistillScriptForTesting(source)
        #expect(patched.contains("TOKENSAVER DISTILL EVENT EMITTER BEGIN"))
        #expect(patched.contains("writeTokenSaverEvent"))
        #expect(patched.contains("stdio: [\"pipe\", \"pipe\", \"pipe\"]"))
        #expect(patched.contains("process.stdin.on(\"data\", (chunk) => {"))
        #expect(patched.contains("blocker_category: `launch:${error.message}`"))
        #expect(patched.contains("blocker_category: code === 0 ? \"none\" : signal ? `signal:${signal}` : `exit:${code ?? 1}`"))
    }
}
