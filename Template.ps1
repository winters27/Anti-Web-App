# Anti-Web-App Template Launcher
$ErrorActionPreference = 'Stop'

# ===== CONFIGURATION =====
$Url           = 'https://ENTER_YOUR_APP_URL_HERE.com'
$DesiredWidth  = 1200
$DesiredHeight = 800
# Isolated profile directory ensures Chromium respects launch arguments and prevents background-process hooking failures.
$ProfileDir    = "$env:LOCALAPPDATA\AntiWebApp_Profile"
# =========================

# Edge path resolution (Because we all have it forced on us anyway, might as well use it as a headless engine)
$edge64  = 'C:\Program Files\Microsoft\Edge\Application\msedge.exe'
$edge32  = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
$EdgeExe = if (Test-Path $edge64) { $edge64 } elseif (Test-Path $edge32) { $edge32 } else { 'msedge.exe' }

# Calculate exact Center Coordinates natively
Add-Type -AssemblyName System.Windows.Forms
$wa = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$x  = [math]::Round(($wa.Width - $DesiredWidth) / 2) + $wa.Left
$y  = [math]::Round(($wa.Height - $DesiredHeight) / 2) + $wa.Top

# Build isolated launch arguments with aggressive optimization flags to strip the browser to its absolute barebones WebHID/Engine rendering layers
$ArgsLine = @(
    "--app=`"$Url`"",
    "--window-size=$DesiredWidth,$DesiredHeight",
    "--window-position=$x,$y",
    "--user-data-dir=`"$ProfileDir`"",
    "--disable-extensions",
    "--disable-plugins",
    "--disable-background-networking",
    "--disable-sync",
    "--disable-translate",
    "--disable-default-apps",
    "--disable-component-extensions-with-background-pages",
    "--no-default-browser-check",
    "--no-first-run",
    "--disable-client-side-phishing-detection",
    "--disable-features=IsolateOrigins,site-per-process"
) -join ' '

# Launch the Application
Start-Process -FilePath $EdgeExe -ArgumentList $ArgsLine
