import SwiftUI

public struct SkillEditorView: View {
    public let skill: Skill
    public let onSave: ([String: String], String) -> Void

    @State private var currentSkillId: String = ""
    @State private var editName: String = ""
    @State private var editDescription: String = ""
    @State private var editOrigin: String = ""
    @State private var rawBody: String = ""
    @State private var showSavedNotification = false

    public init(skill: Skill, onSave: @escaping ([String: String], String) -> Void) {
        self.skill = skill
        self.onSave = onSave
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Metadata bar
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Skill Name")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        TextField("Name", text: $editName)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Origin")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        TextField("Origin", text: $editOrigin)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(" ")
                            .font(.caption2)
                        Button {
                            performSave()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: showSavedNotification ? "checkmark.circle.fill" : "square.and.arrow.down")
                                Text(showSavedNotification ? "Saved!" : "Save Changes")
                            }
                            .frame(minWidth: 110)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(showSavedNotification ? .green : .accentColor)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Description (Used for Agent Auto-Invocation Detection)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("Description", text: $editDescription)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding(14)
            .background(Theme.sidebarBackground)

            Divider()

            // Markdown Body Text Editor
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("SKILL.md Markdown Body")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(rawBody.components(separatedBy: .newlines).count) lines")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))

                Divider()

                MacTextView(text: $rawBody)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if currentSkillId != skill.id {
                loadSkillData()
            }
        }
        .onChange(of: skill.id) { _, newId in
            if currentSkillId != newId {
                loadSkillData()
            }
        }
    }

    private func loadSkillData() {
        currentSkillId = skill.id
        editName = skill.name
        editDescription = skill.description
        editOrigin = skill.origin ?? ""
        rawBody = skill.markdownBody
    }

    private func performSave() {
        var fm = skill.frontmatter
        fm["name"] = editName
        fm["description"] = editDescription
        if !editOrigin.isEmpty {
            fm["origin"] = editOrigin
        }
        onSave(fm, rawBody)

        withAnimation {
            showSavedNotification = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSavedNotification = false
            }
        }
    }
}
