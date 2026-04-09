<# :
@echo off
color 0B
powershell -ExecutionPolicy Bypass -NoProfile -Command "$env:LAUNCH_DIR='%~dp0'; iex ((Get-Content '%~f0' -Raw))"
exit /b
#>

# --- Anti-Web-App Interactive Wizard Orchestrator ---
$ErrorActionPreference = 'Stop'

function Write-Header {
    Clear-Host
    Write-Host ""
    Write-Host "    ░█████╗░███╗░░██╗████████╗██╗" -ForegroundColor Cyan
    Write-Host "    ██╔══██╗████╗░██║╚══██╔══╝██║" -ForegroundColor Cyan
    Write-Host "    ███████║██╔██╗██║░░░██║░░░██║" -ForegroundColor DarkCyan
    Write-Host "    ██╔══██║██║╚████║░░░██║░░░██║" -ForegroundColor DarkCyan
    Write-Host "    ██║░░██║██║░╚███║░░░██║░░░██║" -ForegroundColor DarkGray
    Write-Host "    ╚═╝░░╚═╝╚═╝░░╚══╝░░░╚═╝░░░╚═╝" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  ╭────────────────────────────────────────────────╮" -ForegroundColor DarkGray
    Write-Host "  │  " -NoNewline -ForegroundColor DarkGray
    Write-Host "       NATIVE WEB-APP HARDWARE COMPILER     " -NoNewline -ForegroundColor White
    Write-Host "  │" -ForegroundColor DarkGray
    Write-Host "  ╰────────────────────────────────────────────────╯" -ForegroundColor DarkGray
    Write-Host ""
}

function Write-Step ($Prefix, $Text, $Color="White", $PrefixColor="Cyan") {
    Write-Host "  [" -NoNewline -ForegroundColor DarkGray
    Write-Host $Prefix -NoNewline -ForegroundColor $PrefixColor
    Write-Host "] " -NoNewline -ForegroundColor DarkGray
    Write-Host $Text -ForegroundColor $Color
}

function Write-Info ($Text) {
    Write-Host "      │ " -NoNewline -ForegroundColor DarkGray
    Write-Host $Text -ForegroundColor DarkGray
}

$ScriptDir = $env:LAUNCH_DIR.TrimEnd('\')

Write-Header
Write-Step "1" "Initial Configuration" "White"
Write-Info "We need the exact URL of your hardware's client interface."
Write-Host "      ╰─▶ " -NoNewline -ForegroundColor DarkGray
$Url = Read-Host "URL "

if ([string]::IsNullOrWhiteSpace($Url)) {
    Write-Host "`n  [!] URL cannot be empty. Exiting..." -ForegroundColor Red
    Start-Sleep 3
    Exit
}

Write-Host ""
Write-Step "2" "Executable Profiling" "White"
Write-Info "What should the compiled standalone desktop app be named?"
Write-Host "      ╰─▶ " -NoNewline -ForegroundColor DarkGray
$AppName = Read-Host "Name (e.g. DashboardApp) "
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

Write-Host ""
Write-Step "3" "Extracting Sizing Constraints" "White"
Write-Info "Launching Edge frame... border it to frame your dashboard perfectly."
Write-Info "When you are 100% finished framing, press ENTER here..."
Write-Host "      ╰─▶ " -NoNewline -ForegroundColor DarkGray
Read-Host "Press ENTER to lock dimensions "
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
            
            # Immediately close the user's sizing window so they don't have to do it manually
            try { $proc.Kill() } catch { }
            
            $found = $true
            
            Write-Host ""
            Write-Step "✦" "Dimensions Captured:" "Green" "Green"
            Write-Info "$($cleanW)px Width x $($cleanH)px Height"
            
            Write-Host ""
            Write-Step "4" "Multi-Res ICO Compiler" "White"
            $domain = $(([uri]$Url).Host)
            $pngPath = Join-Path $ScriptDir "temp_src.png"
            $icoPath = Join-Path $ScriptDir "icon.ico"
            $hasIcon = $false
            
            try {
                Invoke-WebRequest -Uri "https://www.google.com/s2/favicons?domain=$domain&sz=256" -OutFile $pngPath -UseBasicParsing -ErrorAction Stop
                
                $csIcon = @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;

public static class IconMaker {
    public static void CompileMultiIcon(string imagePath, string iconPath) {
        using (Bitmap src = new Bitmap(imagePath))
        using (FileStream fs = new FileStream(iconPath, FileMode.Create))
        using (BinaryWriter bw = new BinaryWriter(fs)) {
            
            int[] sizes = { 256, 128, 64, 48, 32, 16 };
            
            bw.Write((short)0); 
            bw.Write((short)1); 
            bw.Write((short)sizes.Length); 
            
            long dataOffset = 6 + (16 * sizes.Length);
            
            foreach (int size in sizes) {
                bw.Write((byte)(size == 256 ? 0 : size));
                bw.Write((byte)(size == 256 ? 0 : size));
                bw.Write((byte)0); bw.Write((byte)0);
                bw.Write((short)1); bw.Write((short)32);
                
                byte[] bmpData = GetPayload(src, size);
                bw.Write((int)bmpData.Length);
                bw.Write((int)dataOffset);
                dataOffset += bmpData.Length;
            }
            
            foreach (int size in sizes) {
                bw.Write(GetPayload(src, size));
            }
        }
    }

    private static byte[] GetPayload(Bitmap src, int size) {
        using (Bitmap dest = new Bitmap(size, size))
        using (Graphics g = Graphics.FromImage(dest)) {
            g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
            g.DrawImage(src, 0, 0, size, size);
            
            BitmapData data = dest.LockBits(new Rectangle(0, 0, size, size), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            int byteCount = data.Stride * size;
            byte[] pixels = new byte[byteCount];
            Marshal.Copy(data.Scan0, pixels, 0, byteCount);
            dest.UnlockBits(data);
            
            byte[] flipped = new byte[byteCount];
            for (int y = 0; y < size; y++) {
                Array.Copy(pixels, y * data.Stride, flipped, (size - 1 - y) * data.Stride, data.Stride);
            }
            
            using (MemoryStream ms = new MemoryStream())
            using (BinaryWriter bw = new BinaryWriter(ms)) {
                bw.Write((int)40); 
                bw.Write((int)size);
                bw.Write((int)(size * 2)); 
                bw.Write((short)1);
                bw.Write((short)32);
                bw.Write((int)0);
                bw.Write((int)byteCount);
                bw.Write((int)0); bw.Write((int)0);
                bw.Write((int)0); bw.Write((int)0);
                bw.Write(flipped);
                for(int i = 0; i < (size * size) / 8; i++) { bw.Write((byte)0); }
                return ms.ToArray();
            }
        }
    }
}
"@
                Add-Type -TypeDefinition $csIcon -ReferencedAssemblies "System.Drawing" -ErrorAction SilentlyContinue
                [IconMaker]::CompileMultiIcon($pngPath, $icoPath)
                
                Remove-Item $pngPath -Force
                Write-Info "Dynamically forged Uncompressed 6-Layer ICO."
                $hasIcon = $true
            } catch {
                Write-Info "Could not compile custom icon. Using default OS executable icon."
            }
            
            Write-Host ""
            Write-Step "5" "Native Assembly Compilation" "White"
            Write-Info "Injecting metadata and invoking csc.exe..."

            $csPath = Join-Path $ScriptDir "Template.cs"
            if (Test-Path $csPath) {
                $content = Get-Content $csPath
                $content = $content -replace 'string url = ".*?";', "string url = `"$Url`";"
                $content = $content -replace 'int desiredWidth = \d+;', "int desiredWidth = $cleanW;"
                $content = $content -replace 'int desiredHeight = \d+;', "int desiredHeight = $cleanH;"
                
                $content = $content -replace '\[assembly: AssemblyDescription\(".*?"\)\]', "[assembly: AssemblyDescription(`"$AppName`")]"
                $content = $content -replace '\[assembly: AssemblyProduct\(".*?"\)\]', "[assembly: AssemblyProduct(`"$AppName`")]"
                
                $newProfile = "AntiWebApp_Profile_$([guid]::NewGuid().ToString().Substring(0,8))"
                $content = $content -replace 'string profileDir = Path\.Combine\(Environment\.GetFolderPath\(Environment\.SpecialFolder\.LocalApplicationData\), ".*?"\);', "string profileDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), `"$newProfile`");"
                
                $content | Set-Content $csPath
            }
            
            $csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
            $OutFile = "$AppName.exe"
            
            if (Test-Path $OutFile) { Remove-Item $OutFile -Force -ErrorAction SilentlyContinue }

            if ($hasIcon -and (Test-Path $icoPath)) {
                & $csc /target:winexe /out:$OutFile /win32icon:$icoPath $csPath | Out-Null
            } else {
                & $csc /target:winexe /out:$OutFile $csPath | Out-Null
            }

            if (Test-Path $icoPath) { Remove-Item $icoPath -Force -ErrorAction SilentlyContinue }

            Write-Host ""
            Write-Host "  ╭────────────────────────────────────────────────╮" -ForegroundColor DarkGray
            Write-Host "  │" -NoNewline -ForegroundColor DarkGray
            Write-Host " SUCCESS: " -NoNewline -ForegroundColor Green
            Write-Host "'$AppName.exe' has been natively forged. " -NoNewline -ForegroundColor White
            Write-Host "│" -ForegroundColor DarkGray
            Write-Host "  ╰────────────────────────────────────────────────╯" -ForegroundColor DarkGray
            Write-Host ""
            
            break
        }
    }
}

if (-not $found) {
    Write-Host "`n  [!] Could not detect window! Make sure you don't close it before hitting Enter." -ForegroundColor Red
}

Write-Host "`n  Press any key to gracefully close system wrapper..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
