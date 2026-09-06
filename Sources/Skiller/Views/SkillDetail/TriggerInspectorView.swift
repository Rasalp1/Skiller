import SwiftUI

public struct TriggerInspectorView: View {
    public let skill: Skill
    @State private var copiedPrompt = false

    public init(skill: Skill) {
        self.skill = skill
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header Card: Trigger Classification & Score
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: skill.triggerAnalysis.triggerType.icon)
                            .font(.system(size: 20))
                            .foregroundColor(Theme.colorForTrigger(skill.triggerAnalysis.triggerType))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(skill.triggerAnalysis.triggerType.rawValue)
                                .font(.headline)
                            Text(skill.triggerAnalysis.summaryReason)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Auto Confidence Score Meter
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(Int(skill.triggerAnalysis.score * 100))% Auto Likelihood")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.colorForTrigger(skill.triggerAnalysis.triggerType))
                            ProgressView(value: skill.triggerAnalysis.score)
                                .frame(width: 120)
                                .tint(Theme.colorForTrigger(skill.triggerAnalysis.triggerType))
                        }
                    }
                }
                .cardContainer()

                // Suggested Prompt Copy Box
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Invocation Prompt Template", systemImage: "sparkles")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.accentColor)
                        Spacer()
                        Button {
                            ShellLauncher.copyToClipboard(skill.triggerAnalysis.suggestedTriggerPrompt)
                            copiedPrompt = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copiedPrompt = false
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: copiedPrompt ? "checkmark" : "doc.on.clipboard")
                                Text(copiedPrompt ? "Copied!" : "Copy Prompt")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .tint(copiedPrompt ? .green : .accentColor)
                    }

                    Text(skill.triggerAnalysis.suggestedTriggerPrompt)
                        .font(.system(.body, design: .monospaced))
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Theme.subtleBorder, lineWidth: 1)
                        )
                }
                .cardContainer()

                // Detected Trigger Criteria & Match Signals
                VStack(alignment: .leading, spacing: 10) {
                    Label("Detected Trigger Criteria (\(skill.triggerAnalysis.criteria.count))", systemImage: "target")
                        .font(.system(size: 13, weight: .semibold))

                    if skill.triggerAnalysis.criteria.isEmpty {
                        Text("No automatic trigger phrases explicitly detected in SKILL.md. This skill is primarily manual or command-driven.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(skill.triggerAnalysis.criteria) { criterion in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .padding(.top, 2)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(criterion.phrase)
                                            .font(.system(size: 12, weight: .medium))
                                        Text("Source: \(criterion.sourceLocation)")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(8)
                                .background(Color.primary.opacity(0.03))
                                .cornerRadius(6)
                            }
                        }
                    }
                }
                .cardContainer()

                // Manual Slash Commands / Direct Call Patterns
                if !skill.triggerAnalysis.manualSlashCommands.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Direct Slash Command & Manual Invocations", systemImage: "terminal")
                            .font(.system(size: 13, weight: .semibold))

                        HStack(spacing: 8) {
                            ForEach(skill.triggerAnalysis.manualSlashCommands, id: \.self) { cmd in
                                Button {
                                    ShellLauncher.copyToClipboard(cmd)
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(cmd)
                                            .font(.system(.caption, design: .monospaced))
                                        Image(systemName: "doc.on.clipboard")
                                            .font(.system(size: 9))
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.12))
                                    .foregroundColor(.blue)
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .cardContainer()
                }
            }
            .padding(16)
        }
    }
}
