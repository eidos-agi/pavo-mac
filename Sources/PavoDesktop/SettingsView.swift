import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("Pavo") {
                LabeledContent("CLI", value: "eidos-agi/pavo")
                LabeledContent("Desktop", value: "This app is the inbox")
            }
            Section("Connectors") {
                Text("Plaud, Fireflies, Google Meet, Zoom. Tokens stay in their own stores. This app never holds OAuth.")
                    .foregroundStyle(.secondary)
            }
            Section("Packs") {
                Text("Meeting → OMF. Personal note → OANF. Registry only. Human gate stays closed.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
