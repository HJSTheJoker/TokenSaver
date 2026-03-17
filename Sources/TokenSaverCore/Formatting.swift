import Foundation

public enum TokenSaverFormatting {
    public static func compactInt(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    public static func percent(_ value: Double) -> String {
        String(format: "%.0f%%", value * 100)
    }

    public static func ratio(_ value: Double) -> String {
        String(format: "%.0f%%", value * 100)
    }

    public static func relativeDate(_ date: Date?) -> String {
        guard let date else { return "Never" }
        return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
    }
}
