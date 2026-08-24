import SwiftUI

struct MessageListView: View {
    @EnvironmentObject private var desk: Desk

    var body: some View {
        List(desk.visible, selection: Binding(
            get: { desk.selectedId },
            set: { if let id = $0 { desk.select(id) } }
        )) { rec in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(rec.title).font(.headline)
                    Spacer()
                    Text(rec.createdAt, format: .dateTime.hour().minute())
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Text(rec.note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text("\(rec.source) · \(clock(rec.duration))")
                    .font(.caption.monospaced())
                    .foregroundStyle(.tertiary)
            }
            .tag(rec.id)
            .padding(.vertical, 4)
        }
        .navigationTitle(desk.mailbox.title)
        .navigationSubtitle("\(desk.visible.count)")
    }
}

func clock(_ t: TimeInterval) -> String {
    let m = Int(t) / 60
    let s = Int(t) % 60
    return String(format: "%d:%02d", m, s)
}
