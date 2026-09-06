import SwiftUI
import AppKit

struct PackageFilesView: View {
    let files: [SkillFileItem]
    let directoryURL: URL?
    @State private var selectedFileID: String?
    @State private var fileContent = ""
    @State private var previewMessage: String?

    private var selectedFile: SkillFileItem? { files.first { $0.id == selectedFileID } }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("File", selection: $selectedFileID) {
                    Text("Choose a file").tag(nil as String?)
                    ForEach(files.filter { !$0.isDirectory }) { file in
                        Text(file.relativePath).tag(file.id as String?)
                    }
                }
                .labelsHidden().frame(maxWidth: .infinity)
                if let url = selectedFile?.url ?? directoryURL {
                    Button { ShellLauncher.revealInFinder(url: url) } label: {
                        Image(systemName: "folder")
                    }
                    .help("Reveal in Finder")
                }
            }
            .padding(.horizontal, Theme.pageInset).padding(.vertical, 16)
            Divider()
            if let file = selectedFile {
                if let previewMessage {
                    EmptyLibraryView(icon: "doc", title: file.name, message: previewMessage)
                } else if file.name.lowercased().hasSuffix(".md") {
                    MarkdownDocumentView(content: fileContent)
                } else {
                    MacTextView(text: .constant(fileContent), isEditable: false)
                }
            } else {
                EmptyLibraryView(icon: "folder", title: "Explore this package",
                                 message: "Choose a file to preview its contents.")
            }
        }
        .onAppear { selectedFileID = files.first { !$0.isDirectory }?.id }
        .task(id: selectedFile?.url) {
            guard let file = selectedFile else { return }
            fileContent = ""
            previewMessage = nil
            do {
                let values = try file.url.resourceValues(forKeys: [.fileSizeKey])
                guard (values.fileSize ?? 0) <= 1_000_000 else {
                    previewMessage = "This file is too large to preview. Reveal it in Finder to open it."
                    return
                }
                let content = try String(contentsOf: file.url, encoding: .utf8)
                guard !content.contains("\u{0000}") else {
                    previewMessage = "A preview isn’t available for this file. Open it from Finder."
                    return
                }
                fileContent = content
            } catch {
                previewMessage = "This file couldn’t be read as text. Reveal it in Finder to inspect it."
            }
        }
    }
}
