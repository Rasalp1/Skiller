import SwiftUI

struct ComponentEditorView: View {
    @Bindable var appState: AppState
    let item: StackItem
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var description: String
    @State private var content: String
    @State private var showingDiscard = false
    @State private var saveError: String?

    init(appState: AppState, item: StackItem) {
        self.appState = appState
        self.item = item
        _name = State(initialValue: item.name)
        _description = State(initialValue: item.description)
        _content = State(initialValue: item.content)
    }

    private var hasChanges: Bool {
        name != item.name || description != item.description || content != item.content
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ComponentIcon(kind: item.kind)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Edit component").font(.system(size: 17, weight: .semibold))
                    Text(item.name).font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Spacer()
                if hasChanges {
                    Text("Unsaved changes").font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
            .padding(24)
            Divider()
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Name").font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                    TextField("Component name", text: $name).textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Description").font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                    TextField("What does this component do?", text: $description, axis: .vertical)
                        .lineLimit(2...4).textFieldStyle(.roundedBorder)
                }
            }
            .padding(.horizontal, 24).padding(.vertical, 20)
            HStack {
                Label("Instructions", systemImage: "text.alignleft")
                Spacer()
                Text("Markdown · \(content.components(separatedBy: .newlines).count) lines")
            }
            .font(.system(size: 11)).foregroundStyle(.secondary)
            .padding(.horizontal, 24).padding(.vertical, 10)
            .background(Theme.secondarySurface)
            Divider()
            MacTextView(text: $content)
            Divider()
            HStack {
                Text("Changes are saved to the original file.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
                Button("Cancel") {
                    if hasChanges { showingDiscard = true } else { dismiss() }
                }
                .keyboardShortcut(.cancelAction)
                Button("Save Changes", action: save)
                    .buttonStyle(.borderedProminent).keyboardShortcut("s", modifiers: .command)
                    .disabled(!hasChanges || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(20)
        }
        .frame(width: 680, height: 680).tint(Theme.accent)
        .interactiveDismissDisabled(hasChanges)
        .alert("Discard your changes?", isPresented: $showingDiscard) {
            Button("Keep Editing", role: .cancel) {}
            Button("Discard Changes", role: .destructive) { dismiss() }
        } message: {
            Text("Your edits to “\(item.name)” haven’t been saved.")
        }
        .alert("Couldn’t save changes", isPresented: Binding(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } }
        )) {
            Button("OK") { saveError = nil }
        } message: { Text(saveError ?? "") }
    }

    private func save() {
        // A file watcher may have refreshed or moved this item while the sheet was open.
        guard let current = appState.items.first(where: { $0.id == item.id }),
              current.content == item.content,
              current.frontmatter == item.frontmatter else {
            saveError = "This component changed outside the editor. Copy your edits before closing, then reopen it to edit the latest version."
            return
        }
        if appState.saveItem(current, name: name, description: description,
                             frontmatter: current.frontmatter, content: content) {
            dismiss()
        } else {
            saveError = appState.errorMessage
            appState.errorMessage = nil
        }
    }
}
