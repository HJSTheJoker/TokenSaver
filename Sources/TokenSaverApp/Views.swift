import SwiftUI
import TokenSaverCore

struct ContentView: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TokenSaver")
                .font(.headline)
            Text("Today saved: ~\(TokenSaverFormatting.compactInt(self.model.summary.todayBigModelTokensSaved)) tokens")
            Text("30d saved: ~\(TokenSaverFormatting.compactInt(self.model.summary.last30DaysBigModelTokensSaved)) tokens")
            Text("Runs: \(self.model.summary.successfulRuns) ok / \(self.model.summary.blockedRuns) blocked / \(self.model.summary.failedRuns) failed")
            Text("Source split: distill ~\(TokenSaverFormatting.compactInt(self.model.summary.distillBreakdown.bigModelTokensSaved)) | safe-distill ~\(TokenSaverFormatting.compactInt(self.model.summary.safeDistillBreakdown.bigModelTokensSaved))")
            Text("Big-model compression: \(TokenSaverFormatting.ratio(self.model.summary.averageBigModelCompressionRatio))")
            Text("Local input reduction: \(TokenSaverFormatting.ratio(self.model.summary.averageSmallModelInputReductionRatio))")
            Text("Model: \(self.model.summary.latestModel ?? "unknown")")
            Text("Last updated: \(TokenSaverFormatting.relativeDate(self.model.summary.lastUpdated))")
                .foregroundStyle(.secondary)
            Divider()
            HStack {
                Button("Refresh") { self.model.refresh() }
                Button("Open Logs") { self.model.openEventsFolder() }
                Button("Open Backups") { self.model.openBackupsFolder() }
            }
        }
        .padding(14)
        .frame(width: 360, alignment: .leading)
    }
}

struct SettingsView: View {
    @Bindable var model: AppModel

    var body: some View {
        Form {
            Stepper(
                "Refresh every \(Int(self.model.refreshIntervalSeconds))s",
                value: Binding(
                    get: { Int(self.model.refreshIntervalSeconds) },
                    set: { self.model.refreshIntervalSeconds = Double($0) }),
                in: 30 ... 900,
                step: 30)
            Toggle("Show debug details", isOn: $model.showDebugDetails)
            Text("TokenSaver remains additive to both distill and safe-distill. Install the hooks through the CLI when you are ready.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
