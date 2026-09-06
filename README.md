# Skiller ⚡

> **A native, high-performance macOS command center for discovering, managing, inspecting, and triggering AI Agent skills, tools, rules, commands, and MCP servers across Claude Code, OpenAI Codex, and Google Antigravity.**

---

[![macOS](https://img.shields.io/badge/macOS-14.0%2B%20Sonoma%20%7C%20Sequoia-black?style=flat-square&logo=apple)](https://apple.com)
[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI%20%2B%20Observation-007AFF?style=flat-square&logo=swift)](https://developer.apple.com/xcode/swiftui/)
[![Claude Code](https://img.shields.io/badge/Claude-Code%20Skills-D97706?style=flat-square&logo=anthropic)](https://anthropic.com)
[![Codex](https://img.shields.io/badge/OpenAI-Codex%20CLI-10A37F?style=flat-square&logo=openai)](https://openai.com)
[![Antigravity](https://img.shields.io/badge/Google-Antigravity%20%2F%20Gemini-8E75FF?style=flat-square&logo=google)](https://deepmind.google)
[![Architecture](https://img.shields.io/badge/Arch-Universal%20(Apple%20Silicon%20%2F%20Intel)-6B7280?style=flat-square)](#architecture)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

---

## 🏷️ Repository Tags & Topics

`skills-manager` • `ai-agents` • `claude-code` • `openai-codex` • `antigravity` • `gemini-cli` • `mcp-servers` • `model-context-protocol` • `swiftui` • `macos-app` • `agentic-workflows` • `developer-tools` • `prompt-engineering` • `tool-use` • `fsevents` • `native-macos`

---

## 📖 Overview

As agentic coding assistants evolve, developers accumulate dozens of custom skills, prompt templates, behavioral rules, subagent definitions, and Model Context Protocol (MCP) servers spread across different configuration paths (`~/.claude`, `~/.codex`, `~/.gemini/config`, and project-level `.agents` workspaces).

**Skiller** provides a single, unified, native macOS GUI and menu bar companion to:
1. **Discover & Aggregate**: Instantly scan global and workspace-level configurations across all major agent ecosystems.
2. **Toggle & Organize**: Enable or disable skills and tools non-destructively without modifying your source code or breaking configurations.
3. **Analyze Trigger Heuristics**: Automatically classify auto-invoked skills vs. manual/slash commands and generate one-click copyable invocation prompts.
4. **Inspect & Edit**: Full YAML frontmatter validation, Markdown editor with live preview, and multi-file asset explorer.
5. **Quick Access Menu Bar**: Always-available status bar item for rapid search, quick enablement toggles, and instant prompt copying.

```mermaid
graph TD
    A[Skiller Core] --> B[Global Claude Code ~/.claude]
    A --> C[Global OpenAI Codex ~/.codex]
    A --> D[Google Antigravity ~/.gemini]
    A --> E[Workspace Custom Roots .agents / .claude / .codex]
    
    B --> F[Skills]
    B --> G[Commands]
    B --> H[Agents]
    B --> I[Rules]
    
    C --> F
    C --> J[MCP Servers]
    
    D --> F
    D --> K[Hooks & Plugins]
    D --> J
    
    E --> F
    E --> G
    E --> I
    E --> J
```

---

## ✨ Key Features

### 🌐 Unified Multi-Assistant Discovery
Seamlessly aggregates agent components across your entire developer environment:
- **Claude Code**: `~/.claude/skills`, `~/.claude/commands`, `~/.claude/agents`, `~/.claude/rules`
- **OpenAI Codex**: `~/.codex/skills`, `~/.codex/mcp_config.json`, `~/.codex/rules`
- **Google Antigravity / Gemini**: `~/.gemini/config/skills`, built-in IDE extensions, `hooks.json`, and `plugins/`
- **Project Workspaces**: Custom workspace directories scanning `.agents/`, `.claude/`, and `.codex/` with persistent workspace bookmarking.

### 🧩 Complete Component Spectrum
Supports all dimensions of modern agent configurations:
| Kind | Description | Icon |
| :--- | :--- | :---: |
| **Skills** | Reusable toolsets, workflows, and multi-step agent actions with YAML metadata | ⚡ |
| **Agents** | Specialized autonomous subagent personas and sub-task executors | 👤 |
| **Commands** | Slash commands, shell integrations, and one-liner triggers | 💻 |
| **Rules** | System prompt guidelines, styling conventions, and behavioral guardrails | 📜 |
| **MCP Servers** | Model Context Protocol servers configured via JSON definitions | 🌐 |
| **Hooks & Plugins**| Lifecycle hooks (`pre_command`, `post_tool`) and bundled extensions | 🧩 |

### ⚡ Non-Destructive Instant Enable / Disable
Easily deactivate unused skills to save context window tokens or prevent prompt collisions. Toggling moves directories atomically to/from a `*-disabled` peer directory (e.g. `skills-disabled/`) or toggles configuration flags, preserving all metadata and history.

### 🧠 Intelligent Trigger Inspector & Likelihood Scoring
- **Automated Trigger Classification**: Analyzes skill descriptions, imperative keywords, and frontmatter to classify skills into `Automatic`, `Manual / Command`, `Contextual`, or `Conditional`.
- **Auto-Likelihood Score**: Dynamic confidence meter (0%–100%) indicating how aggressively an LLM will automatically pull the tool.
- **Trigger Criteria Inspector**: Extracts keyword criteria and conditions matching user prompts.
- **Copyable Invocation Prompts**: Generates optimal, LLM-tuned prompt templates ready to paste into your chat or terminal.

### 📝 Rich Editor & Live Markdown Preview
- Built-in Markdown reader with syntax highlighting.
- Live editor for `SKILL.md`, rules, and configurations with undo/redo support.
- File explorer pane to inspect bundled scripts (`scripts/`), templates (`resources/`), and reference documents (`references/`).

### 🪟 Menu Bar Companion App
A lightweight status bar interface accessible anywhere on macOS:
- Quick fuzzy search across all active skills.
- One-click toggling without leaving your code editor or terminal.
- Instant prompt generator copy-to-clipboard.

### 🔄 Live File System Synchronization
Powered by macOS `FSEvents` (`FileWatcherService`) to automatically detect external edits, Git branch switches, and CLI installations in real time without manual reloads.

---

## 🛠️ Architecture & Tech Stack

Skiller is built from the ground up using modern Swift and native Apple frameworks:

- **Language**: Swift 6.0 (Strict Concurrency & Sendable compliance)
- **UI Framework**: SwiftUI with the `@Observable` macro pattern (macOS 14+ Sonoma & Sequoia)
- **Filesystem Engine**: Custom `FSEvents` file watcher service with async debouncing
- **State Management**: Unidirectional reactive `AppState`
- **Parsing**: Custom resilient YAML frontmatter parser and Markdown tokenizer

### Project Structure

```
Skiller/
├── Package.swift                    # Swift Package Manager manifest (macOS v14+)
├── Scripts/
│   └── build_app.sh                 # Release build and .app bundle packager
├── Sources/
│   └── SkillsManagerApp/
│       ├── App/
│       │   ├── SkillsManagerApp.swift   # Main app entrypoint & MenuBarExtra
│       │   └── AppState.swift           # Central observable application state
│       ├── Models/
│       │   ├── ComponentKind.swift      # Enum: Skill, Agent, Command, Rule, MCP, Hook
│       │   ├── SkillSource.swift        # Discovery source definitions & paths
│       │   ├── StackItem.swift          # Core unified component model
│       │   ├── Skill.swift              # Skill metadata & file hierarchy model
│       │   ├── FrontmatterParser.swift  # Resilient YAML frontmatter parser
│       │   └── SkillTriggerAnalysis.swift # Trigger heuristics & score calculator
│       ├── Services/
│       │   ├── StackDiscoveryService.swift # Multi-ecosystem folder discovery
│       │   ├── StackManagerService.swift   # Toggle enable/disable & file operations
│       │   └── FileWatcherService.swift    # Low-level FSEvents directory watcher
│       ├── Utilities/
│       │   ├── ShellLauncher.swift      # Clipboard & macOS Finder integration
│       │   └── Theme.swift              # Consistent typography & color palette
│       └── Views/
│           ├── MainView.swift           # Three-column NavigationSplitView layout
│           ├── Sidebar/                 # Sources & Category filtering
│           ├── SkillList/               # Search, sorting, and item cards
│           ├── SkillDetail/             # Inspector, editor, files, and trigger preview
│           ├── MenuBar/                 # MenuBarPopoverView quick-access
│           └── Components/              # Custom reusable Mac controls & badges
└── Tests/
    └── SkillsManagerAppTests/       # Unit tests for discovery, parsing, and triggers
```

---

## 🚀 Getting Started

### Prerequisites
- **macOS 14.0 (Sonoma)** or **macOS 15.0+ (Sequoia)**
- **Xcode 16.0+** or **Swift 6.0+ Toolchain**

### 1. Build and Run Directly with Swift CLI

```bash
# Clone the repository
git clone https://github.com/Rasalp1/Skiller.git
cd Skiller

# Run in development mode
swift run SkillsManagerApp
```

### 2. Build Release `.app` Bundle

Skiller includes a build script to package a standalone native `.app` bundle:

```bash
# Make the build script executable and run
chmod +x Scripts/build_app.sh
./Scripts/build_app.sh

# Open the compiled application
open dist/SkillsManager.app
```

You can drag `dist/SkillsManager.app` directly into your `/Applications` directory.

---

## ⌨️ Keyboard Shortcuts & Usage

| Shortcut / Action | Function |
| :--- | :--- |
| `⌘ + R` | Refresh and re-scan all skill sources |
| `⌘ + F` | Focus the global search field |
| `Space` | Toggle enable / disable status of selected item |
| `⌘ + C` (on Trigger View) | Copy generated trigger prompt to clipboard |
| `⌘ + Click (on File Path)` | Reveal skill directory in macOS Finder |

---

## 🤝 Supported Directory Schemas

Skiller automatically recognizes and structures files following standard AI agent skill conventions:

```
~/.claude/skills/my-awesome-skill/
├── SKILL.md                 # Required: Main instructions & YAML frontmatter
├── scripts/                 # Optional: Executable helpers (Python, Bash, JS)
│   └── run.py
├── references/              # Optional: Documentation & knowledge files
│   └── cheatsheet.md
└── resources/               # Optional: Assets and templates
```

```
~/.gemini/config/
├── skills/                  # Active Antigravity skills
├── rules/                   # Active rules & prompt instructions
├── mcp_config.json          # MCP server definitions
└── hooks.json               # Agent lifecycle hooks
```

---

## 🧪 Testing

Run the automated test suite covering YAML parsing, trigger classification, and discovery logic:

```bash
swift test
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">
  <sub>Crafted for agentic engineers building the future of software development.</sub>
</div>
