import SwiftUI

struct InspectorView: View {
    @EnvironmentObject private var desk: Desk

    var body: some View {
        if let rec = desk.selected {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(rec.title).font(.largeTitle.weight(.semibold))
                        Text("\(rec.source) · \(clock(rec.duration)) · \(desk.selectedSpans.count) speakers")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        Text(rec.note).foregroundStyle(.secondary)
                    }
                    if desk.packed.contains(rec.id) {
                        Text("Packed. Human gate still closed — identity is proposed.")
                            .foregroundStyle(.secondary)
                    } else {
                        WizardView(rec: rec)
                    }
                }
                .padding(24)
                .frame(maxWidth: 720, alignment: .leading)
            }
        } else {
            ContentUnavailableView("Nothing selected", systemImage: "waveform")
        }
    }
}
