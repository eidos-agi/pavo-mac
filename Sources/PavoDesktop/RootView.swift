import SwiftUI

struct RootView: View {
    @EnvironmentObject private var desk: Desk

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
        } content: {
            MessageListView()
                .navigationSplitViewColumnWidth(min: 260, ideal: 320, max: 420)
        } detail: {
            InspectorView()
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
