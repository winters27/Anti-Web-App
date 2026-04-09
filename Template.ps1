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

# ===== SETUP WIZARD AUTO-EXTRACTOR =====
$uriHost = ([uri]$Url).Host

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " [ WAITING ] Web App Launched!" -ForegroundColor Green
Write-Host " Go ahead and navigate your hardware dashboard."
Write-Host " Drag the window edges until all whitespace is gone and it fits perfectly."
Write-Host ""
Write-Host " When you are 100% finished sizing, press ENTER here..." -ForegroundColor Yellow
Read-Host

$cs = @"
using System;
using System.Runtime.InteropServices;
public static class W32 {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out RECT lpRect);
}
"@
Add-Type -TypeDefinition $cs -ErrorAction SilentlyContinue

$found = $false
foreach ($proc in Get-Process msedge -ErrorAction SilentlyContinue) {
    if ($proc.MainWindowTitle) {
        $rect = New-Object W32+RECT
        [W32]::GetWindowRect($proc.MainWindowHandle, [ref]$rect) | Out-Null
        $w = $rect.Right - $rect.Left
        $h = $rect.Bottom - $rect.Top
        
        # Super simple check: exclude tiny background invisible handles
        if ($w -gt 100 -and $h -gt 100) {
            # Apply Native Rounding/Padding to snap to clean digits (e.g., 1268 -> 1270)
            $cleanW = [math]::Round($w / 10) * 10
            $cleanH = [math]::Round($h / 10) * 10
            
            Write-Host ""
            Write-Host " [ SUCCESS ] Extracted Dimensions: $($w)x$($h)" -ForegroundColor Green
            Write-Host " [ PADDING applied ] Snapping to: $($cleanW)x$($cleanH)" -ForegroundColor Yellow
            
            # Auto-patch Template.cs
            $csPath = Join-Path $PSScriptRoot "Template.cs"
            if (Test-Path $csPath) {
                $content = Get-Content $csPath
                $content = $content -replace "int desiredWidth = \d+;", "int desiredWidth = $cleanW;"
                $content = $content -replace "int desiredHeight = \d+;", "int desiredHeight = $cleanH;"
                $content | Set-Content $csPath
                Write-Host " [ ROOT ] Template.cs automatically updated." -ForegroundColor Cyan
            }
            $found = $true
            break
        }
    }
}

if (-not $found) {
    Write-Host " [ ERROR ] Could not detect the active Edge window handle. Please ensure the app is still open when pressing Enter." -ForegroundColor Red
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
