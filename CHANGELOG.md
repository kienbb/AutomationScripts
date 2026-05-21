# Changelog

All notable changes to the AutomationScripts repository.

## [1.0.0] - 2025-05-21

### Added
- `install-opencode.ps1` - PowerShell installer for OpenCode CLI
  - Prerequisites check (PowerShell, Windows, Node.js, npm, Git)
  - Auto Node.js installation via winget or nvm-windows
  - Dry-run mode for safe testing
  - Colored output with clear status indicators
  - Support for npm tags (latest, beta, etc.)

## [Unreleased]

### Planned
- macOS install script for OpenCode
- Linux install script for OpenCode
- Additional development environment setup scripts
- GitHub Actions workflows for CI/CD
