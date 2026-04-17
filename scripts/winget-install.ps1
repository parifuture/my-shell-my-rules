# ~/code/my-shell-my-rules/scripts/winget-install.ps1
# Install Windows GUI apps via winget — mirrors brew casks from macOS Brewfiles
# Usage (from PowerShell): .\scripts\winget-install.ps1
#
# Run this on the Windows side, NOT inside WSL.

$ErrorActionPreference = "Stop"

Write-Host "`n==> Installing Windows GUI apps via winget...`n" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
#  GUI Apps (replaces macOS casks)
# ---------------------------------------------------------------------------

$apps = @(
    # Password manager
    "AgileBits.1Password"

    # Browsers
    "Google.Chrome"
    "ZenBrowserTeam.ZenBrowser"

    # Communication
    "SlackTechnologies.Slack"
    "Discord.Discord"

    # Development
    "Microsoft.VisualStudioCode"
    "Figma.Figma"
    "Postman.Postman"

    # Notes
    "Obsidian.Obsidian"

    # VPN
    "Tailscale.Tailscale"

    # Terminal
    "wez.wezterm"

    # Utilities — Windows equivalents of macOS-only tools
    "Microsoft.PowerToys"           # replaces Raycast (app launcher, clipboard, etc.)
    "ShareX.ShareX"                 # replaces CleanShot (screenshots, recording, OCR)
)

foreach ($app in $apps) {
    Write-Host "Installing $app..." -ForegroundColor Yellow
    winget install --id $app --accept-source-agreements --accept-package-agreements --silent 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK" -ForegroundColor Green
    } else {
        Write-Host "  Already installed or failed — check manually" -ForegroundColor DarkYellow
    }
}

# ---------------------------------------------------------------------------
#  Fonts (must be on Windows for WezTerm to render them)
# ---------------------------------------------------------------------------

Write-Host "`n==> Installing fonts..." -ForegroundColor Cyan

$fonts = @(
    # Nerd Font — icon fallback for eza, starship, fzf-tab
    "Nerd Fonts - Meslo"
    "Nerd Fonts - Symbols Only"
)

foreach ($font in $fonts) {
    Write-Host "Searching for '$font'..." -ForegroundColor Yellow
    winget search $font 2>$null | Out-Null
}

Write-Host @"

==> Font install notes:
  Nerd Fonts can be installed via winget if available, or download from:
    https://www.nerdfonts.com/font-downloads

  Install these on Windows (not WSL):
    - MesloLGM Nerd Font
    - Symbols Nerd Font Mono
    - MonoLisa Variable (paid — https://www.monolisa.dev)

  After installing, right-click the .ttf/.otf files > "Install for all users"

"@ -ForegroundColor DarkCyan

# ---------------------------------------------------------------------------
#  VS Code extensions
# ---------------------------------------------------------------------------

Write-Host "==> Installing VS Code extensions..." -ForegroundColor Cyan

$extensions = @(
    "dbaeumer.vscode-eslint"
    "github.copilot-chat"
    "pomdtr.excalidraw-editor"
    "unional.vscode-sort-package-json"
)

if (Get-Command code -ErrorAction SilentlyContinue) {
    foreach ($ext in $extensions) {
        Write-Host "  Installing $ext..."
        code --install-extension $ext --force 2>$null
    }
} else {
    Write-Host "  VS Code CLI not found — install extensions manually or restart terminal after VS Code install" -ForegroundColor DarkYellow
}

# ---------------------------------------------------------------------------
#  Done
# ---------------------------------------------------------------------------

Write-Host "`n==> Windows setup complete.`n" -ForegroundColor Green
Write-Host "Reminders:"
Write-Host "  - Run scripts/wsl-install.sh inside WSL for CLI tools"
Write-Host "  - MonoLisa Variable must be purchased separately (monolisa.dev)"
Write-Host "  - WezTerm config is at: $env:USERPROFILE\.config\wezterm\wezterm.lua"
Write-Host ""
