# Anti-Web-App Interactive Wizard Orchestrator
$ErrorActionPreference = 'Stop'
Clear-Host

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "      Anti-Web-App | Native Desktop Wrapper Setup" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
$Url = Read-Host " [?] Please paste your hardware Web App URL (e.g. https://dashboard.your-device.com) "

if ([string]::IsNullOrWhiteSpace($Url)) {
    Write-Host " [ ERROR ] URL cannot be empty. Exiting..." -ForegroundColor Red
    Start-Sleep 3
    Exit
}

$AppName = Read-Host " [?] What do you want to name the executable? (e.g. DashboardApp) "
if ([string]::IsNullOrWhiteSpace($AppName)) {
    $AppName = "Anti-Web-App"
}

Write-Host ""
$DesiredWidth  = 1200
$DesiredHeight = 800
$ProfileDir    = "$env:LOCALAPPDATA\AntiWebApp_Profile_$([guid]::NewGuid().ToString().Substring(0,8))"

# Edge path resolution 
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

Write-Host " [ WAITING ] Web App Launched!" -ForegroundColor Green
Write-Host " Go ahead and drag the window edges until all whitespace is gone."
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
            $found = $true
            
            Write-Host " [ SUCCESS ] Extracted Dimensions: $($cleanW)x$($cleanH)" -ForegroundColor Green
            
            # --- Auto-Icon High-Res Injector ---
            $domain = $(([uri]$Url).Host)
            $png128Path = Join-Path $PSScriptRoot "temp_128.png"
            $png32Path  = Join-Path $PSScriptRoot "temp_32.png"
            $icoPath    = Join-Path $PSScriptRoot "icon.ico"
            $hasIcon    = $false
            
            try {
                Invoke-WebRequest -Uri "https://www.google.com/s2/favicons?domain=$domain&sz=128" -OutFile $png128Path -UseBasicParsing -ErrorAction Stop
                Invoke-WebRequest -Uri "https://www.google.com/s2/favicons?domain=$domain&sz=32" -OutFile $png32Path -UseBasicParsing -ErrorAction Stop
                
                # Natively construct a true "Multi-Size" ICO Header block (2 Images: 128px and 32px)
                # This explicitly forces Windows to use the sharp pre-scaled 32px version for Taskbars, curing the aliasing blur
                [byte[]] $b128 = [System.IO.File]::ReadAllBytes($png128Path)
                [byte[]] $b32  = [System.IO.File]::ReadAllBytes($png32Path)
                
                $fs = [System.IO.File]::Create($icoPath)
                $bw = New-Object System.IO.BinaryWriter($fs)
                $bw.Write([int16]0); $bw.Write([int16]1); $bw.Write([int16]2) # 2 Images Format
                
                # Directory Entry 1 (128x128)
                $bw.Write([byte]128); $bw.Write([byte]128); $bw.Write([byte]0); $bw.Write([byte]0)
                $bw.Write([int16]1);  $bw.Write([int16]32)
                $bw.Write([int32]$b128.Length)
                $bw.Write([int32]38)  # Offset starts after the two 16-byte Directory Headers + 6-byte Intro Header (38)
                
                # Directory Entry 2 (32x32)
                $bw.Write([byte]32);  $bw.Write([byte]32);  $bw.Write([byte]0); $bw.Write([byte]0)
                $bw.Write([int16]1);  $bw.Write([int16]32)
                $bw.Write([int32]$b32.Length)
                $bw.Write([int32](38 + $b128.Length)) # Offset starts exactly after the 128px PNG payload finishes
                
                # Write massive PNG Payloads consecutively
                $bw.Write($b128)
                $bw.Write($b32)
                $bw.Close()
                
                Remove-Item $png128Path -Force
                Remove-Item $png32Path -Force
                Write-Host " [ ICON grab ] Ripped crisp multi-layered ICO (128px & 32px) to fix Taskbar aliasing!" -ForegroundColor Green
                $hasIcon = $true
            } catch {
                Write-Host " [ ICON fail ] Could not rip high-res icon. Using OS default." -ForegroundColor DarkGray
            }
            
            # --- Auto-Patch Template.cs ---
            $csPath = Join-Path $PSScriptRoot "Template.cs"
            if (Test-Path $csPath) {
                $content = Get-Content $csPath
                $content = $content -replace 'string url = ".*?";', "string url = `"$Url`";"
                $content = $content -replace 'int desiredWidth = \d+;', "int desiredWidth = $cleanW;"
                $content = $content -replace 'int desiredHeight = \d+;', "int desiredHeight = $cleanH;"
                
                $newProfile = "AntiWebApp_Profile_$([guid]::NewGuid().ToString().Substring(0,8))"
                $content = $content -replace 'string profileDir = Path\.Combine\(Environment\.GetFolderPath\(Environment\.SpecialFolder\.LocalApplicationData\), ".*?"\);', "string profileDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), `"$newProfile`");"
                
                $content | Set-Content $csPath
            }
            
            # --- AUTO COMPILER ---
            Write-Host " [ COMPILER ] Building your Native Desktop .exe securely..." -ForegroundColor Cyan
            $csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
            
            $OutFile = "$AppName.exe"
            
            # Safe wipe of previous executable run if naming repeats
            if (Test-Path $OutFile) { Remove-Item $OutFile -Force -ErrorAction SilentlyContinue }

            if ($hasIcon -and (Test-Path $icoPath)) {
                & $csc /target:winexe /out:$OutFile /win32icon:$icoPath $csPath | Out-Null
            } else {
                & $csc /target:winexe /out:$OutFile $csPath | Out-Null
            }

            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Cyan
            Write-Host " [ DONE ] Your native desktop app '$AppName' has compiled successfully!" -ForegroundColor DarkYellow
            Write-Host "          You can now pin '$OutFile' to your desktop." -ForegroundColor White
            Write-Host "============================================================" -ForegroundColor Cyan
            Write-Host ""
            
            break
        }
    }
}

if (-not $found) {
    Write-Host " [ ERROR ] Could not detect window. Make sure you don't close it before hitting Enter." -ForegroundColor Red
}

Write-Host " Press any key to close Setup Wizard..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
