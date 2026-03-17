import Testing
@testable import TokenSaverInstaller

struct SafeDistillInstallerTests {
    @Test
    func patchAddsMarkerBlock() throws {
        let source = """
#!/usr/bin/env python3
def main() -> int:
    excerpt = "x"
    log_path = "/tmp/x"
    blocker = "none"
    status = "ok"
            return 0 if status == "ok" else 2
        sys.stdout.write(result.stdout)
        maybe_stop_model(pre_existing_models)
        cleanup_log(log_path, keep=False)
        return 0

if __name__ == "__main__":
    raise SystemExit(main())
"""
        let patched = try SafeDistillInstaller.makePatchedScriptForTesting(source)
        #expect(patched.contains("TOKENSAVER EVENT EMITTER BEGIN"))
        #expect(patched.contains("write_tokensaver_event("))
    }
}
