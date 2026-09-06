import SwiftUI

public struct SkillFilesView: View {
    public let skill: Skill
    @State private var selectedFile: SkillFileItem?
    @State private var fileContent: String = ""

    public init(skill: Skill) {
        self.skill = skill
    }

    public var body: some View {
        HSplitView {
            // Left: File list
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Package Files (\(skill.files.count))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button {
                        ShellLauncher.revealInFinder(url: skill.directoryURL)
                    } label: {
                        Image(systemName: "folder")
                    }
                    .buttonStyle(.plain)
                    .help("Reveal Folder in Finder")
                }
                .padding(10)
                .background(Theme.sidebarBackground)

                Divider()

                List(selection: $selectedFile) {
                    ForEach(skill.files) { file in
                        HStack(spacing: 6) {
                            Image(systemName: file.isDirectory ? "folder" : iconForFile(file.name))
                                .foregroundColor(file.isDirectory ? .blue : .secondary)
                            Text(file.relativePath)
                                .font(.system(size: 12, design: .monospaced))
                            Spacer()
                            if !file.isDirectory {
                                Text(formatBytes(file.sizeInBytes))
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tag(file)
                        .contextMenu {
                            Button("Reveal in Finder") {
                                ShellLauncher.revealInFinder(url: file.url)
                            }
                            Button("Open in Default App") {
                                NSWorkspace.shared.open(file.url)
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
            .frame(minWidth: 220, idealWidth: 260)

            // Right: File preview
            VStack(alignment: .leading, spacing: 0) {
                if let file = selectedFile {
                    HStack {
                        Text(file.relativePath)
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .padding(10)
                    .background(Theme.sidebarBackground)

                    Divider()

                    ScrollView {
                        Text(fileContent)
                            .font(.system(.body, design: .monospaced))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                } else {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "doc.text")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Select a file to preview")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onChange(of: selectedFile) { _, newFile in
            if let f = newFile, !f.isDirectory {
                fileContent = (try? String(contentsOf: f.url, encoding: .utf8)) ?? "(Binary or unreadable file)"
            } else {
                fileContent = ""
            }
        }
        .onAppear {
            if let first = skill.files.first(where: { !$0.isDirectory }) {
                selectedFile = first
            }
        }
    }

    private func iconForFile(_ name: String) -> String {
        if name.hasSuffix(".md") { return "doc.richtext" }
        if name.hasSuffix(".py") || name.hasSuffix(".js") || name.hasSuffix(".sh") || name.hasSuffix(".swift") { return "curlybraces" }
        if name.hasSuffix(".json") || name.hasSuffix(".yaml") || name.hasSuffix(".yml") || name.hasSuffix(".toml") { return "gearshape" }
        return "doc.text"
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
