import Cocoa
import UniformTypeIdentifiers

final class ShareViewController: NSViewController {
    private var didHandle = false
    private var staged: [(temp: URL, name: String)] = []
    private let statusLabel = NSTextField(labelWithString: "Preparing clip…")

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 90))
        statusLabel.alignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
        ])
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        guard !didHandle, let context = extensionContext else { return }
        didHandle = true
        collectFiles(context: context) { [weak self] files in
            guard let self else { return }
            if files.isEmpty {
                context.completeRequest(returningItems: nil)
                return
            }
            self.staged = files
            self.statusLabel.stringValue = "Choose a folder to save \(files.count) file\(files.count == 1 ? "" : "s")…"
            self.chooseDestination(context: context)
        }
    }

    // MARK: - Collect shared items into temp files we own

    private func collectFiles(context: NSExtensionContext, done: @escaping ([(temp: URL, name: String)]) -> Void) {
        let providers = context.inputItems
            .compactMap { ($0 as? NSExtensionItem)?.attachments }
            .flatMap { $0 }

        guard !providers.isEmpty else {
            done([])
            return
        }

        let group = DispatchGroup()
        var results: [(temp: URL, name: String)] = []
        let lock = NSLock()

        for provider in providers {
            // Prefer an audiovisual type; fall back to whatever the sender offers.
            let typeID = provider.registeredTypeIdentifiers.first(where: {
                UTType($0)?.conforms(to: .audiovisualContent) ?? false
            }) ?? provider.registeredTypeIdentifiers.first ?? UTType.data.identifier

            group.enter()
            provider.loadFileRepresentation(forTypeIdentifier: typeID) { url, _ in
                defer { group.leave() }
                guard let url else { return }

                let fileExt = url.pathExtension.isEmpty
                    ? (UTType(typeID)?.preferredFilenameExtension ?? "mp4")
                    : url.pathExtension
                var name = provider.suggestedName ?? url.deletingPathExtension().lastPathComponent
                if (name as NSString).pathExtension.isEmpty {
                    name += "." + fileExt
                }

                let temp = FileManager.default.temporaryDirectory
                    .appendingPathComponent("clipsaver-\(UUID().uuidString)-" + name)
                do {
                    try FileManager.default.copyItem(at: url, to: temp)
                    lock.lock()
                    results.append((temp, name))
                    lock.unlock()
                } catch {
                    // Skip items we can't stage.
                }
            }
        }

        group.notify(queue: .main) { done(results) }
    }

    // MARK: - Folder picker + copy

    private func chooseDestination(context: NSExtensionContext) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.title = "Save Clip to Folder"
        panel.message = "Choose a folder to save the clip to"
        panel.prompt = "Save Here"
        if let last = UserDefaults.standard.url(forKey: "lastFolder") {
            panel.directoryURL = last
        }

        let finish: (NSApplication.ModalResponse) -> Void = { [weak self] response in
            defer { self?.cleanup() }
            if response == .OK, let dir = panel.url {
                UserDefaults.standard.set(dir, forKey: "lastFolder")
                self?.saveStagedFiles(to: dir)
                context.completeRequest(returningItems: nil)
            } else {
                context.cancelRequest(withError: NSError(domain: NSCocoaErrorDomain,
                                                         code: NSUserCancelledError))
            }
        }

        if let window = view.window {
            panel.beginSheetModal(for: window, completionHandler: finish)
        } else {
            NSApp?.activate(ignoringOtherApps: true)
            finish(panel.runModal())
        }
    }

    private func saveStagedFiles(to dir: URL) {
        let fm = FileManager.default
        for item in staged {
            var dest = dir.appendingPathComponent(item.name)
            var counter = 2
            while fm.fileExists(atPath: dest.path) {
                let base = dest.deletingPathExtension().lastPathComponent
                    .replacingOccurrences(of: #" \(\d+\)$"#, with: "", options: .regularExpression)
                dest = dir.appendingPathComponent("\(base) (\(counter)).\(dest.pathExtension)")
                counter += 1
            }
            try? fm.copyItem(at: item.temp, to: dest)
        }
    }

    private func cleanup() {
        for item in staged {
            try? FileManager.default.removeItem(at: item.temp)
        }
        staged.removeAll()
    }
}
