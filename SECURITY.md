# Security policy

Skiller reads and edits local agent configuration. Treat the files it opens as potentially sensitive: do not commit API keys, access tokens, or private prompts to this repository.

Skiller is a local macOS application with no network service or authentication boundary. Keep the app and its configuration directories on trusted user accounts. MCP environment values are redacted in the discovery UI, but the source configuration files remain on disk and should be protected with normal filesystem permissions.

## Reporting a vulnerability

Use GitHub's private vulnerability reporting for this repository when it is enabled. Do not disclose exploit details or sensitive configuration in a public issue. Include the affected version or commit, reproduction steps, impact, and a minimal safe proof of concept.
