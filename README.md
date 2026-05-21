# AutomationScripts

A collection of automation scripts for Windows, macOS, and Linux. Streamline your development environment setup with one-liner installations.

## Scripts

### OpenCode CLI Installer (`install-opencode.ps1`)

One-liner PowerShell installer for [OpenCode](https://github.com/anomalyco/opencode) - the open-source AI coding agent.

**Prerequisites:**
- Windows 10/11
- PowerShell 5.0+
- Node.js 18+ (auto-install option available)

**Quick Install:**

```powershell
# Default install (requires Node.js 18+ pre-installed)
irm https://raw.githubusercontent.com/kienbb/AutomationScripts/main/install-opencode.ps1 | iex

# With auto Node.js installation
irm https://raw.githubusercontent.com/kienbb/AutomationScripts/main/install-opencode.ps1 | iex -ForceNodeInstall

# Using powershell -c (alternative syntax)
powershell -c "irm https://raw.githubusercontent.com/kienbb/AutomationScripts/main/install-opencode.ps1 | iex"

# Bypass execution policy if needed
powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/kienbb/AutomationScripts/main/install-opencode.ps1 | iex"
```

**Parameters:**

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-Tag` | npm tag to install (latest, beta, etc.) | `latest` |
| `-SkipNodeCheck` | Skip Node.js version validation | `$false` |
| `-ForceNodeInstall` | Auto-install Node.js via winget/nvm | `$false` |
| `-DryRun` | Show what would be done without installing | `$false` |

**Examples:**

```powershell
# Install beta version
irm .../install-opencode.ps1 | iex -Tag beta

# Auto-install Node.js if missing
irm .../install-opencode.ps1 | iex -ForceNodeInstall

# Preview without installing
irm .../install-opencode.ps1 | iex -DryRun
```

**What it does:**
1. Checks PowerShell version (requires 5.0+)
2. Checks Windows version (recommends Win 10+)
3. Verifies Node.js 18+ is installed
4. Optionally auto-installs Node.js via winget or nvm-windows
5. Checks npm and Git availability
6. Installs `opencode-ai` globally via npm
7. Verifies installation

## Repository Structure

```
AutomationScripts/
├── install-opencode.ps1    # OpenCode CLI installer
├── README.md               # This file
└── .github/
    └── workflows/          # CI/CD workflows (coming soon)
```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-script`
3. Commit your changes: `git commit -am 'Add new script'`
4. Push to the branch: `git push origin feature/my-script`
5. Open a Pull Request

## License

MIT License - feel free to use and modify for your own automation needs.

## Disclaimer

These scripts modify your system (install software, update PATH, etc.). Always review scripts before running them, especially when using `irm ... | iex`. Use at your own risk.

## Related

- [OpenCode](https://github.com/anomalyco/opencode) - The open-source coding agent
- [OpenCode Docs](https://opencode.ai/docs) - Official documentation
