//CREATED  BY: nanthi13 ON 24/07/2026


import SwiftUI

/// A compact metric card showing a primary value and a supporting title.
/// Intended for small summary KPIs (e.g., total focus time, longest session, average length).
struct FocusSummaryCard: View {
    let title: String
    let valueText: String
    let systemImage: String?
    let tint: Color?

    init(title: String, valueText: String, systemImage: String? = nil, tint: Color? = nil) {
        self.title = title
        self.valueText = valueText
        self.systemImage = systemImage
        self.tint = tint
    }

    /// Convenience initializer for minute-based values (formats as "xh ym" or "ym").
    init(title: String, minutes: Int, systemImage: String? = nil, tint: Color? = nil) {
        self.title = title
        self.valueText = FocusSummaryCard.formatMinutes(minutes)
        self.systemImage = systemImage
        self.tint = tint
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold)) // smaller icon
                    .foregroundStyle((tint ?? .accentColor).opacity(0.95))
                    .frame(width: 24, height: 24) // smaller frame
                    .background(
                        Circle()
                            .fill((tint ?? .accentColor).opacity(0.15))
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(valueText)
                    .font(.headline) // smaller than title3 weight
                    .foregroundStyle(tint ?? .accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(title)
                    .font(.caption2) // smaller subtitle
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)   // reduced vertical padding
        .padding(.horizontal, 10) // reduced horizontal padding
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12)) // slightly tighter corner radius
        .frame(minWidth: 0) // allow tighter layout in HStacks/Grids
    }

    // MARK: - Formatting

    /// Formats minutes into "xh ym" or "ym". For 0, returns "0m".
    private static func formatMinutes(_ minutes: Int) -> String {
        let m = max(0, minutes)
        let hours = m / 60
        let mins = m % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        HStack(spacing: 10) {
            FocusSummaryCard(title: "Focus Hrs", minutes: 305, systemImage: "clock", tint: .blue)
            FocusSummaryCard(title: "Longest", minutes: 95, systemImage: "timer", tint: .green)
            FocusSummaryCard(title: "Avg", minutes: 42, systemImage: "chart.bar", tint: .orange)
        }
        FocusSummaryCard(title: "Sessions", valueText: "12", systemImage: "list.bullet", tint: .purple)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
