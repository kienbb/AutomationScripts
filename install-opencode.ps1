# OpenCode CLI Installer for Windows
# Usage:
#   irm https://raw.githubusercontent.com/kienbb/AutomationScripts/main/install-opencode.ps1 | iex
#   powershell -c "irm https://raw.githubusercontent.com/kienbb/AutomationScripts/main/install-opencode.ps1 | iex"
#   powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/kienbb/AutomationScripts/main/install-opencode.ps1 | iex"

param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ─── Helpers ───────────────────────────────────────────────────────────
function Write-Success { param([string]$Message) Write-Host "  [OK] $Message" -ForegroundColor Green }
function Write-Info    { param([string]$Message) Write-Host "  [INFO] $Message" -ForegroundColor Cyan }
function Write-Warn    { param([string]$Message) Write-Host "  [WARN] $Message" -ForegroundColor Yellow }
function Write-Error2  { param([string]$Message) Write-Host "  [ERROR] $Message" -ForegroundColor Red }

function Refresh-Path {
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
}

# ─── Header ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║            OpenCode CLI Installer for Windows                 ║" -ForegroundColor Cyan
Write-Host "  ╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Warn "DRY RUN MODE - No changes will be made"
    Write-Host ""
}

# ─── 1. PowerShell Check ───────────────────────────────────────────────
Write-Info "Checking PowerShell..."
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Error2 "PowerShell 5.0+ required. You have $($PSVersionTable.PSVersion)"
    exit 1
}
Write-Success "PowerShell $($PSVersionTable.PSVersion)"

# ─── 2. Windows Version Check ──────────────────────────────────────────
$osInfo = Get-CimInstance Win32_OperatingSystem
if ($osInfo.Version -lt "10.0") {
    Write-Warn "Windows 10+ recommended. Detected: $($osInfo.Caption) $($osInfo.Version)"
} else {
    Write-Success "$($osInfo.Caption) $($osInfo.Version)"
}

# ─── 3. Node.js Check & Auto-Install ───────────────────────────────────
Write-Host ""
Write-Info "Checking Node.js..."

$nodeInstalled = $false
$nodeMajor = 0
$nodeMinor = 0

try {
    $nodeVersion = (node -v 2>$null)
    if ($nodeVersion) {
        $match = [regex]::Match($nodeVersion, '^v(?<major>\d+)\.(?<minor>\d+)')
        if ($match.Success) {
            $nodeMajor = [int]$match.Groups["major"].Value
            $nodeMinor = [int]$match.Groups["minor"].Value
            $nodeInstalled = $true
        }
    }
} catch { }

$minNodeMajor = 18
$nodeOk = $nodeInstalled -and ($nodeMajor -ge $minNodeMajor)

if ($nodeOk) {
    Write-Success "Node.js $nodeVersion (>= v$minNodeMajor)"
} elseif ($nodeInstalled) {
    Write-Warn "Node.js $nodeVersion found, but v$minNodeMajor+ required. Will upgrade..."
} else {
    Write-Warn "Node.js not found. Will install..."
}

# Auto-install or upgrade Node.js
if ((-not $nodeOk) -and (-not $DryRun)) {
    Write-Host ""
    Write-Info "Installing/Upgrading Node.js LTS..."

    # Try winget first
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
        try {
            Write-Info "Using winget to install Node.js LTS..."
            winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
            Refresh-Path
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
            try {
                Write-Info "Using nvm-windows to install Node.js LTS..."
                nvm install lts
                nvm use lts
                Refresh-Path
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
} elseif ((-not $nodeOk) -and $DryRun) {
    Write-Info "[DRY RUN] Would install/upgrade Node.js LTS"
}

# ─── 4. npm Check ──────────────────────────────────────────────────────
Write-Host ""
Write-Info "Checking npm..."
try {
    $npmVersion = (npm -v 2>$null)
    if ($npmVersion) {
        Write-Success "npm v$npmVersion"
    } else {
        Write-Warn "npm not found"
    }
} catch {
    Write-Warn "npm check failed: $_"
}

# ─── 5. Git Check ──────────────────────────────────────────────────────
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

# ─── 6. Install OpenCode ───────────────────────────────────────────────
Write-Host ""
Write-Host "  ───────────────────────────────────────────────────────────────" -ForegroundColor Cyan
Write-Info "Installing OpenCode CLI (latest)..."
Write-Host ""

if ($DryRun) {
    Write-Info "[DRY RUN] Would run: npm install -g opencode-ai@latest"
    Write-Host ""
} else {
    try {
        # Check existing version
        $existingVersion = $null
        try { $existingVersion = (opencode --version 2>$null) } catch { }

        if ($existingVersion) {
            Write-Warn "OpenCode v$existingVersion already installed"
            Write-Info "Upgrading to latest..."
        }

        # Install latest
        npm install -g opencode-ai@latest

        # Verify
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
        Write-Host "    - Run as Administrator if permission denied"
        Write-Host "    - Or use user directory: npm config set prefix `$env:USERPROFILE\npm-global"
        exit 1
    }
}

# ─── Done ──────────────────────────────────────────────────────────────
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
}

Write-Host "  For issues: https://github.com/anomalyco/opencode/issues" -ForegroundColor DarkGray
Write-Host ""
