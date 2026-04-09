<# :
@echo off
color 0B
powershell -ExecutionPolicy Bypass -NoProfile -Command "$env:LAUNCH_DIR='%~dp0'; iex ((Get-Content '%~f0' -Raw -Encoding UTF8))"
echo.
echo Exited with code: %errorlevel%
pause
exit /b
#>

# --- Anti-Web-App Interactive Wizard Orchestrator ---
$ErrorActionPreference = 'Stop'
$LineW = 58

# == TUI Drawing Helpers ==========================================

function Draw-Line ([string]$Char="-", [string]$Color="DarkGray") {
    Write-Host ("  " + ($Char * $LineW)) -ForegroundColor $Color
}

function Draw-Blank { Write-Host "" }

function Draw-Banner {
    Clear-Host
    $Host.UI.RawUI.WindowTitle = "ANTI // Native Web-App Compiler"
    Draw-Blank

    $art = @(
        "     _    _   _ _____ ___",
        "    / \  | \ | |_   _|_ _|",
        "   / _ \ |  \| | | |  | |",
        "  / ___ \| |\  | | |  | |",
        " /_/   \_\_| \_| |_| |___|"
    )
    $colors = @("Cyan","Cyan","Cyan","DarkCyan","DarkCyan")
    for ($i = 0; $i -lt $art.Count; $i++) {
        Write-Host "  $($art[$i])" -ForegroundColor $colors[$i]
    }

    Draw-Blank
    Draw-Line "="  "DarkGray"
    $label = "NATIVE WEB-APP COMPILER"
    $pad = [math]::Floor(($LineW - $label.Length) / 2)
    Write-Host ("  " + (" " * $pad)) -NoNewline
    Write-Host $label -ForegroundColor White
    Draw-Line "="  "DarkGray"
    Draw-Blank
}

function Draw-Step ([int]$Num, [string]$Title) {
    Draw-Blank
    Write-Host "  " -NoNewline
    Write-Host " $Num " -NoNewline -ForegroundColor Black -BackgroundColor Cyan
    Write-Host "  $Title" -ForegroundColor White
    Draw-Line "-" "DarkGray"
}

function Draw-Info ([string]$Text) {
    Write-Host "       $Text" -ForegroundColor DarkGray
}

function Draw-Prompt ([string]$Label) {
    Draw-Blank
    Write-Host "    > " -NoNewline -ForegroundColor Cyan
    Write-Host "$Label " -NoNewline -ForegroundColor Gray
}

function Draw-Check ([string]$Text) {
    Write-Host "    " -NoNewline
    Write-Host "[OK]" -NoNewline -ForegroundColor Green
    Write-Host " $Text" -ForegroundColor Gray
}

function Draw-Result ([string]$Type, [string]$Message) {
    Draw-Blank
    Draw-Line "=" "DarkGray"
    if ($Type -eq "success") {
        Write-Host "  " -NoNewline
        Write-Host "  DONE  " -NoNewline -ForegroundColor Black -BackgroundColor Green
        Write-Host "  $Message" -ForegroundColor White
    } else {
        Write-Host "  " -NoNewline
        Write-Host "  FAIL  " -NoNewline -ForegroundColor White -BackgroundColor Red
        Write-Host "  $Message" -ForegroundColor White
    }
    Draw-Line "=" "DarkGray"
    Draw-Blank
}

# == Main =========================================================

try {

$ScriptDir = $env:LAUNCH_DIR.TrimEnd('\')

Draw-Banner

# -- Step 1: URL --------------------------------------------------

Draw-Step 1 "Target URL"
Draw-Info "Enter the full URL of the web app to compile."
Draw-Prompt "URL:"
$Url = Read-Host

if ([string]::IsNullOrWhiteSpace($Url)) {
    Draw-Result "fail" "URL cannot be empty."
    Start-Sleep 3; Exit
}
Draw-Check $Url

# -- Step 2: App Name --------------------------------------------

Draw-Step 2 "App Identity"
Draw-Info "Choose a name for the compiled executable."
Draw-Prompt "Name:"
$AppName = Read-Host
if ([string]::IsNullOrWhiteSpace($AppName)) { $AppName = "Anti-Web-App" }
Draw-Check "$AppName.exe"

# -- Step 3: Window Sizing ---------------------------------------

Draw-Step 3 "Window Sizing"
Draw-Info "A preview window will open. Resize it to your"
Draw-Info "preferred dimensions, then come back and press ENTER."

$DesiredWidth  = 1200
$DesiredHeight = 800
$ProfileDir    = "$env:LOCALAPPDATA\AntiWebApp_Profile_$([guid]::NewGuid().ToString().Substring(0,8))"

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

Draw-Blank
Draw-Prompt "Press ENTER when sizing is done"
Read-Host | Out-Null

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

            try { $proc.Kill() } catch { }
            $found = $true

            Draw-Check "${cleanW}px x ${cleanH}px locked"

            # -- Step 4: Icon -----------------------------------------

            Draw-Step 4 "Icon Extraction"
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
                Draw-Check "Multi-res ICO forged (6 layers)"
                $hasIcon = $true
            } catch {
                Draw-Info "Icon fetch failed -- using default OS icon."
            }

            # -- Step 5: Compile --------------------------------------

            Draw-Step 5 "Compilation"
            Draw-Info "Patching Template.cs and invoking csc.exe..."

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
                Draw-Check "Template.cs patched"
            } else {
                Draw-Result "fail" "Template.cs not found in script directory."
                throw "Missing Template.cs at: $csPath"
            }

            $csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
            $OutFile = Join-Path $ScriptDir "$AppName.exe"

            if (Test-Path $OutFile) { Remove-Item $OutFile -Force -ErrorAction SilentlyContinue }

            if ($hasIcon -and (Test-Path $icoPath)) {
                & $csc /target:winexe /out:$OutFile /win32icon:$icoPath $csPath | Out-Null
            } else {
                & $csc /target:winexe /out:$OutFile $csPath | Out-Null
            }

            if (Test-Path $icoPath) { Remove-Item $icoPath -Force -ErrorAction SilentlyContinue }

            if (Test-Path $OutFile) {
                Draw-Check "Compiled $AppName.exe"
                Draw-Result "success" "$AppName.exe is ready."
            } else {
                Draw-Result "fail" "csc.exe compilation failed."
            }

            break
        }
    }
}

if (-not $found) {
    Draw-Result "fail" "Could not detect Edge window. Don't close it before pressing ENTER."
}

} catch {
    Draw-Blank
    Draw-Result "fail" "$_"
    Draw-Blank
    Write-Host "    Trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
    Draw-Blank
}

Write-Host "  Press any key to exit..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")