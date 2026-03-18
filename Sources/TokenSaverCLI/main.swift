import Foundation
import TokenSaverCore
import TokenSaverInstaller

@main
enum TokenSaverCLI {
    static func main() {
        let args = Array(CommandLine.arguments.dropFirst())
        let command = args.first ?? "summary"

        do {
            switch command {
            case "summary":
                let json = args.contains("--json")
                try self.runSummary(asJSON: json)
            case "doctor":
                self.runDoctor()
            case "install":
                let result = try SafeDistillInstaller.install()
                print(result.message)
                if let manifest = result.backupManifest {
                    print("Backup: \(manifest.backupRoot)")
                }
            case "uninstall":
                let result = try SafeDistillInstaller.uninstall()
                print(result.message)
            case "tail":
                self.runTail(limit: Self.tailLimit(from: args) ?? 20)
            case "-h", "--help", "help":
                self.printHelp()
            default:
                fputs("Unknown command '\(command)'.\n", stderr)
                self.printHelp()
                Foundation.exit(1)
            }
        } catch {
            fputs("\(error.localizedDescription)\n", stderr)
            Foundation.exit(1)
        }
    }

    private static func runSummary(asJSON: Bool) throws {
        let summary = TokenSaverStore.loadSummary()
        if asJSON {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(summary)
            print(String(decoding: data, as: UTF8.self))
            return
        }

        print("TokenSaver")
        print("Today saved: ~\(TokenSaverFormatting.compactInt(summary.todayBigModelTokensSaved)) tokens")
        print("7d saved: ~\(TokenSaverFormatting.compactInt(summary.last7DaysBigModelTokensSaved)) tokens")
        print("30d saved: ~\(TokenSaverFormatting.compactInt(summary.last30DaysBigModelTokensSaved)) tokens")
        print("Runs: \(summary.successfulRuns) ok / \(summary.blockedRuns) blocked / \(summary.failedRuns) failed")
        print("Source split: distill ~\(TokenSaverFormatting.compactInt(summary.distillBreakdown.bigModelTokensSaved)) / safe-distill ~\(TokenSaverFormatting.compactInt(summary.safeDistillBreakdown.bigModelTokensSaved))")
        print("Big-model compression: \(TokenSaverFormatting.ratio(summary.averageBigModelCompressionRatio))")
        print("Small-model reduction: \(TokenSaverFormatting.ratio(summary.averageSmallModelInputReductionRatio))")
        print("Success rate: \(TokenSaverFormatting.percent(summary.successRate))")
        print("Model: \(summary.latestModel ?? "unknown")")
        print("Last updated: \(TokenSaverFormatting.relativeDate(summary.lastUpdated))")
    }

    private static func runDoctor() {
        let root = TokenSaverPaths.eventsRoot()
        let backupRoot = TokenSaverPaths.backupRoot()
        let eventCount = TokenSaverStore.loadEvents(root: root).count
        print("TokenSaver doctor")
        print("Events root: \(root.path)")
        print("Events present: \(eventCount)")
        print("Backups root: \(backupRoot.path)")
        print("Latest backup: \(FileBackupManager.latestManifest()?.backupTimestamp ?? "none")")
        print("distill hook installed: \(SafeDistillInstaller.distillHookInstalled() ? "yes" : "no")")
        print("safe-distill hook installed: \(SafeDistillInstaller.safeDistillHookInstalled() ? "yes" : "no")")
        print("Widget snapshot: \(TokenSaverPaths.widgetSnapshotURL().path)")
    }

    private static func runTail(limit: Int) {
        let events = TokenSaverStore.loadEvents().sorted { $0.timestamp > $1.timestamp }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        for event in events.prefix(limit) {
            guard let data = try? encoder.encode(event) else { continue }
            print(String(decoding: data, as: UTF8.self))
        }
    }

    private static func tailLimit(from args: [String]) -> Int? {
        guard let index = args.firstIndex(of: "--limit"), args.indices.contains(index + 1) else { return nil }
        return Int(args[index + 1])
    }

    private static func printHelp() {
        print(
            """
            TokenSaver CLI

            Commands:
              summary [--json]
              doctor
              install
              uninstall
              tail [--limit N]
            """
        )
    }
}
