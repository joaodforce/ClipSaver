import SwiftUI

@main
struct ClipSaverApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: 480, height: 320)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 480, height: 320)
    }
}

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("ClipSaver", systemImage: "folder.badge.arrow.down")
                .font(.title2).bold()

            Text("Adds a “Save Clip to Folder” action to the macOS share sheet, so you can export Home.app camera clips to any folder you pick.")
                .foregroundStyle(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("How to use it")
                    .font(.headline)
                Text("1. In Home.app, right-click a camera clip (or open it) and choose Share…")
                Text("2. Pick “ClipSaver” (or “Save Clip to Folder”) in the share sheet")
                Text("3. Choose a folder — the clip is copied there")
                Text("If it doesn't appear: open the share sheet → Edit Extensions… and enable it, or enable it in System Settings → General → Login Items & Extensions → Sharing.")
                    .foregroundStyle(.secondary)
            }
            .font(.callout)

            Spacer()

            HStack {
                Button("Open Extensions Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
                        NSWorkspace.shared.open(url)
                    }
                }
                Spacer()
                Text("com.jed.clipsaver")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(20)
    }
}
