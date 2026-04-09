# Anti-Web-App Template Launcher
$ErrorActionPreference = 'Stop'

# ===== CONFIGURATION =====
$Url           = 'https://miceapp.arbiterstudio.com/#/project/items'
$DesiredWidth  = 1200
$DesiredHeight = 800
# Isolated profile directory ensures Chromium respects launch arguments and prevents background-process hooking failures.
$ProfileDir    = "$env:LOCALAPPDATA\AntiWebApp_Profile"
# =========================

# Edge path resolution (Because we all have it forced on us anyway)
$edge64  = 'C:\Program Files\Microsoft\Edge\Application\msedge.exe'
$edge32  = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
$EdgeExe = if (Test-Path $edge64) { $edge64 } elseif (Test-Path $edge32) { $edge32 } else { 'msedge.exe' }

Add-Type -AssemblyName System.Windows.Forms
$wa = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$x  = [math]::Round(($wa.Width - $DesiredWidth) / 2) + $wa.Left
$y  = [math]::Round(($wa.Height - $DesiredHeight) / 2) + $wa.Top

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

Start-Process -FilePath $EdgeExe -ArgumentList $ArgsLine

# ===== SETUP WIZARD AUTO-EXTRACTOR =====
$uriHost = ([uri]$Url).Host

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " [ WAITING ] Web App Launched!" -ForegroundColor Green
Write-Host " Go ahead and navigate your hardware dashboard."
Write-Host " Drag the window edges until it fits perfectly."
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
        
        if ($w -gt 100 -and $h -gt 100) {
            $cleanW = [math]::Round($w / 10) * 10
            $cleanH = [math]::Round($h / 10) * 10
            
            Write-Host ""
            Write-Host " [ SUCCESS ] Extracted Dimensions: $($w)x$($h)" -ForegroundColor Green
            Write-Host " [ PADDING applied ] Snapping to: $($cleanW)x$($cleanH)" -ForegroundColor Yellow
            
            # --- Auto-Icon Downloader ---
            $iconUrl = "$(([uri]$Url).Scheme)://$(([uri]$Url).Host)/favicon.ico"
            $iconPath = Join-Path $PSScriptRoot "icon.ico"
            try {
                Invoke-WebRequest -Uri $iconUrl -OutFile $iconPath -UseBasicParsing -ErrorAction Stop
                Write-Host " [ ICON grab ] Automatically downloaded site favicon to icon.ico!" -ForegroundColor Green
            } catch {
                Write-Host " [ ICON fail ] Could not auto-download $iconUrl. You may need to manual supply icon.ico." -ForegroundColor DarkGray
            }
            
            # --- Auto-Patch Template.cs ---
            $csPath = Join-Path $PSScriptRoot "Template.cs"
            if (Test-Path $csPath) {
                $content = Get-Content $csPath
                # Ensure the url dynamically pushes over
                $content = $content -replace 'string url = ".*?";', "string url = `"$Url`";"
                $content = $content -replace 'int desiredWidth = \d+;', "int desiredWidth = $cleanW;"
                $content = $content -replace 'int desiredHeight = \d+;', "int desiredHeight = $cleanH;"
                $content | Set-Content $csPath
                Write-Host " [ AUTO-PATCH ] Template.cs updated with URL and Dimensions." -ForegroundColor Cyan
            }
            $found = $true
            break
        }
    }
}

if (-not $found) {
    Write-Host " [ ERROR ] Could not detect the active window. Ensure it is still open." -ForegroundColor Red
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
