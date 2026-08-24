import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var desk: Desk

    var body: some View {
        List(selection: $desk.mailbox) {
            Section("Mailboxes") {
                Label {
                    HStack {
                        Text("Inbox")
                        Spacer()
                        Text("\(desk.inbox.count)").foregroundStyle(.secondary).monospacedDigit()
                    }
                } icon: {
                    Image(systemName: "tray")
                }
                .tag(Mailbox.inbox)

                Label {
                    HStack {
                        Text("Recent")
                        Spacer()
                        Text("\(desk.recent.count)").foregroundStyle(.secondary).monospacedDigit()
                    }
                } icon: {
                    Image(systemName: "clock")
                }
                .tag(Mailbox.recent)

                Label {
                    HStack {
                        Text("Past")
                        Spacer()
                        Text("\(desk.past.count)").foregroundStyle(.secondary).monospacedDigit()
                    }
                } icon: {
                    Image(systemName: "archivebox")
                }
                .tag(Mailbox.past)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Pavo")
    }
}
