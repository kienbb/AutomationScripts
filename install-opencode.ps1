# OpenCode CLI Installer for Windows
# Usage:
#   irm https://raw.githubusercontent.com/kienbb/AutomationScripts/main/install-opencode.ps1 | iex
#   powershell -c "irm https://raw.githubusercontent.com/kienbb/AutomationScripts/main/install-opencode.ps1 | iex"
#   powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/kienbb/AutomationScripts/main/install-opencode.ps1 | iex"
#
# Parameters (optional):
#   -Tag "latest"          # npm tag: latest, beta, etc.
#   -SkipNodeCheck         # Skip Node.js version check
#   -ForceNodeInstall      # Auto-install/upgrade Node.js via nvm-windows or winget
#   -DryRun                # Show what would be done without doing it

param(
    [string]$Tag = "latest",
    [switch]$SkipNodeCheck,
    [switch]$ForceNodeInstall,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ─── Colors ────────────────────────────────────────────────────────────
function Write-Success { param([string]$Message) Write-Host "  [OK] $Message" -ForegroundColor Green }
function Write-Info    { param([string]$Message) Write-Host "  [INFO] $Message" -ForegroundColor Cyan }
function Write-Warn    { param([string]$Message) Write-Host "  [WARN] $Message" -ForegroundColor Yellow }
function Write-Error2  { param([string]$Message) Write-Host "  [ERROR] $Message" -ForegroundColor Red }

# ─── Header ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║            OpenCode CLI Installer for Windows                 ║" -ForegroundColor Cyan
Write-Host "  ║     https://github.com/anomalyco/opencode                     ║" -ForegroundColor Cyan
Write-Host "  ╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Warn "DRY RUN MODE - No changes will be made"
    Write-Host ""
}

# ─── Prerequisites Check ───────────────────────────────────────────────
Write-Info "Checking prerequisites..."
Write-Host ""

# 1. PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Error2 "PowerShell 5.0 or higher is required. You have $($PSVersionTable.PSVersion)"
    Write-Host ""
    Write-Host "  Please upgrade PowerShell: https://docs.microsoft.com/powershell/scripting/install/installing-powershell-on-windows"
    exit 1
}
Write-Success "PowerShell $($PSVersionTable.PSVersion)"

# 2. Windows version (Windows 10+ recommended)
$osInfo = Get-CimInstance Win32_OperatingSystem
if ($osInfo.Version -lt "10.0") {
    Write-Warn "Windows 10 or higher is recommended. Detected: $($osInfo.Caption) $($osInfo.Version)"
} else {
    Write-Success "$($osInfo.Caption) $($osInfo.Version)"
}

# 3. Check for admin (not required but helpful for global install)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Success "Running as Administrator"
} else {
    Write-Warn "Not running as Administrator (global npm install may fail if npm prefix requires admin)"
}

# ─── Node.js Check & Install ───────────────────────────────────────────
Write-Host ""
Write-Info "Checking Node.js..."

$nodeInstalled = $false
$nodeVersion = $null
$nodeMajor = 0
$nodeMinor = 0

try {
    $nodeVersion = (node -v 2>$null)
    if ($nodeVersion) {
        $versionMatch = [regex]::Match($nodeVersion, '^v(?<major>\d+)\.(?<minor>\d+)')
        if ($versionMatch.Success) {
            $nodeMajor = [int]$versionMatch.Groups["major"].Value
            $nodeMinor = [int]$versionMatch.Groups["minor"].Value
            $nodeInstalled = $true
        }
    }
} catch {
    $nodeInstalled = $false
}

$minNodeMajor = 18
$nodeOk = $nodeInstalled -and ($nodeMajor -ge $minNodeMajor)

if ($nodeOk) {
    Write-Success "Node.js $nodeVersion (>= v$minNodeMajor)"
} elseif ($nodeInstalled) {
    Write-Warn "Node.js $nodeVersion found, but v$minNodeMajor+ required"
} else {
    Write-Warn "Node.js not found"
}

# Auto-install Node.js if needed and ForceNodeInstall is set
if ((-not $nodeOk) -and $ForceNodeInstall -and -not $DryRun) {
    Write-Host ""
    Write-Info "Attempting to install Node.js..."

    # Try winget first (Windows 10 20H2+)
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
        Write-Info "Installing Node.js LTS via winget..."
        try {
            winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
            # Refresh PATH
            $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
            $nodeVersion = (node -v 2>$null)
            Write-Success "Node.js installed: $nodeVersion"
            $nodeOk = $true
        } catch {
            Write-Warn "winget install failed: $_"
        }
    }

    # Fallback: nvm-windows
    if (-not $nodeOk) {
        $nvm = Get-Command nvm -ErrorAction SilentlyContinue
        if ($nvm) {
            Write-Info "Installing Node.js LTS via nvm-windows..."
            try {
                nvm install lts
                nvm use lts
                $nodeVersion = (node -v 2>$null)
                Write-Success "Node.js installed: $nodeVersion"
                $nodeOk = $true
            } catch {
                Write-Warn "nvm install failed: $_"
            }
        }
    }

    if (-not $nodeOk) {
        Write-Error2 "Failed to auto-install Node.js. Please install manually from https://nodejs.org"
        exit 1
    }
} elseif ((-not $nodeOk) -and -not $SkipNodeCheck) {
    Write-Host ""
    Write-Error2 "Node.js v$minNodeMajor+ is required but not found."
    Write-Host ""
    Write-Host "  Install options:" -ForegroundColor Yellow
    Write-Host "    1. Download from https://nodejs.org (LTS recommended)"
    Write-Host "    2. Run this script with -ForceNodeInstall to auto-install"
    Write-Host "    3. Run this script with -SkipNodeCheck to skip this check"
    Write-Host "    4. Use a Node version manager:" -ForegroundColor Yellow
    Write-Host "       - nvm-windows: https://github.com/coreybutler/nvm-windows"
    Write-Host "       - fnm: https://github.com/Schniz/fnm"
    Write-Host ""
    exit 1
}

# ─── npm Check ─────────────────────────────────────────────────────────
Write-Host ""
Write-Info "Checking npm..."

try {
    $npmVersion = (npm -v 2>$null)
    if ($npmVersion) {
        Write-Success "npm v$npmVersion"
    } else {
        Write-Warn "npm not found (should be bundled with Node.js)"
    }
} catch {
    Write-Warn "npm check failed: $_"
}

# ─── Git Check ─────────────────────────────────────────────────────────
Write-Host ""
Write-Info "Checking Git..."

try {
    $gitVersion = (git --version 2>$null)
    if ($gitVersion) {
        Write-Success "$gitVersion"
    } else {
        Write-Warn "Git not found (recommended for opencode)"
    }
} catch {
    Write-Warn "Git not found (recommended for opencode)"
}

# ─── Install OpenCode ──────────────────────────────────────────────────
Write-Host ""
Write-Host "  ───────────────────────────────────────────────────────────────" -ForegroundColor Cyan
Write-Info "Installing OpenCode CLI..."
Write-Host ""

if ($DryRun) {
    Write-Info "Would run: npm install -g opencode-ai@$Tag"
    Write-Host ""
} else {
    try {
        # Check if already installed
        $existingVersion = $null
        try {
            $existingVersion = (opencode --version 2>$null)
        } catch {}

        if ($existingVersion) {
            Write-Warn "OpenCode v$existingVersion is already installed"
            Write-Info "Upgrading to latest @$Tag..."
        }

        # Install/upgrade
        npm install -g opencode-ai@$Tag

        # Verify installation
        $newVersion = (opencode --version 2>$null)
        if ($newVersion) {
            Write-Host ""
            Write-Success "OpenCode v$newVersion installed successfully!"
        } else {
            Write-Warn "Installation completed but version check failed"
        }
    } catch {
        Write-Error2 "Installation failed: $_"
        Write-Host ""
        Write-Host "  Troubleshooting:" -ForegroundColor Yellow
        Write-Host "    - If permission denied, try running as Administrator"
        Write-Host "    - Or configure npm to use a user directory:"
        Write-Host "      npm config set prefix `$env:USERPROFILE\npm-global"
        Write-Host "      Then add `$env:USERPROFILE\npm-global to your PATH"
        exit 1
    }
}

# ─── Post-install ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║              Installation Complete!                           ║" -ForegroundColor Green
Write-Host "  ╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

if (-not $DryRun) {
    Write-Host "  Next steps:" -ForegroundColor Cyan
    Write-Host "    1. Run 'opencode' to start the CLI"
    Write-Host "    2. Configure your API keys on first run"
    Write-Host "    3. Visit https://opencode.ai/docs for documentation"
    Write-Host ""
    Write-Host "  Recommended terminal emulators:" -ForegroundColor Cyan
    Write-Host "    - Windows Terminal (built-in on Win 11, install on Win 10)"
    Write-Host "    - WezTerm: https://wezfurlong.org/wezterm"
    Write-Host "    - Alacritty: https://alacritty.org"
    Write-Host ""
}

Write-Host "  For issues, visit: https://github.com/anomalyco/opencode/issues" -ForegroundColor DarkGray
Write-Host ""
