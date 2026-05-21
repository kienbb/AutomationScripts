# AutomationScripts

A collection of automation scripts for Windows, macOS, and Linux.

## Scripts

### OpenCode CLI Installer (`install-opencode.ps1`)

One-liner PowerShell installer for [OpenCode](https://github.com/anomalyco/opencode) - the open-source AI coding agent.

**What it does:**
1. Checks PowerShell version (requires 5.0+)
2. Checks Windows version
3. Checks Node.js (v18+ required) - **auto-installs/upgrade if missing or outdated**
4. Checks npm and Git availability
5. Installs latest `opencode-ai` globally via npm
6. Verifies installation

**Quick Install:**

```powershell
# Default install (auto-installs prerequisites if needed)
irm https://raw.githubusercontent.com/kienbb/AutomationScripts/main/install-opencode.ps1 | iex

# Using powershell -c
powershell -c "irm https://raw.githubusercontent.com/kienbb/AutomationScripts/main/install-opencode.ps1 | iex"

# Bypass execution policy if needed
powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/kienbb/AutomationScripts/main/install-opencode.ps1 | iex"
```

**Parameters:**

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-DryRun` | Show what would be done without installing | `$false` |

**Examples:**

```powershell
# Preview without installing
irm https://raw.githubusercontent.com/kienbb/AutomationScripts/main/install-opencode.ps1 | iex -DryRun
```

## License

MIT License
