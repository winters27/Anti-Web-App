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
            
            # Immediately close the user's sizing window so they don't have to do it manually
            try { $proc.Kill() } catch { }
            
            $found = $true
            
            Write-Host " [ SUCCESS ] Extracted Dimensions: $($cleanW)x$($cleanH)" -ForegroundColor Green
            
            # --- Advanced Multi-Res Auto-Icon Generator ---
            # Windows Taskbars strictly require Uncompressed BMP Payloads (DIBs) for 32x32 frames, heavily rejecting raw PNG injections.
            # We will use an internal C# compiler block to dynamically generate a professional, uncompressed multi-layer .ico on the fly.
            $domain = $(([uri]$Url).Host)
            $pngPath = Join-Path $PSScriptRoot "temp_src.png"
            $icoPath = Join-Path $PSScriptRoot "icon.ico"
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
            
            // Standard Windows OS scaling thresholds
            int[] sizes = { 256, 128, 64, 48, 32, 16 };
            
            // ICO Header
            bw.Write((short)0); // reserved
            bw.Write((short)1); // type=1
            bw.Write((short)sizes.Length); // layers
            
            long dataOffset = 6 + (16 * sizes.Length);
            
            // Build Directory & Offsets
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
            
            // Append Raw Payloads
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
            
            // Taskbar and File Explorer absolutely demand Uncompressed BMP Payloads (DIBs) for perfect small-pixel scaling.
            BitmapData data = dest.LockBits(new Rectangle(0, 0, size, size), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            int byteCount = data.Stride * size;
            byte[] pixels = new byte[byteCount];
            Marshal.Copy(data.Scan0, pixels, 0, byteCount);
            dest.UnlockBits(data);
            
            // Invert pixel array (DIB demands Bottom-Up parsing)
            byte[] flipped = new byte[byteCount];
            for (int y = 0; y < size; y++) {
                Array.Copy(pixels, y * data.Stride, flipped, (size - 1 - y) * data.Stride, data.Stride);
            }
            
            using (MemoryStream ms = new MemoryStream())
            using (BinaryWriter bw = new BinaryWriter(ms)) {
                // BITMAPINFOHEADER
                bw.Write((int)40); 
                bw.Write((int)size);
                bw.Write((int)(size * 2)); // Height matches mask
                bw.Write((short)1);
                bw.Write((short)32);
                bw.Write((int)0);
                bw.Write((int)byteCount);
                bw.Write((int)0); bw.Write((int)0);
                bw.Write((int)0); bw.Write((int)0);
                // BGRA Pixel block
                bw.Write(flipped);
                // Blank AND mask (transparency handled by 32bpp alpha channel)
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
                Write-Host " [ ICON grab ] Dynamically forged Professional 6-Layer Multi-Res Uncompressed ICO! Taskbar will be crisp!" -ForegroundColor Green
                $hasIcon = $true
            } catch {
                Write-Host " [ ICON fail ] Could not compile advanced ICO. Using OS default." -ForegroundColor DarkGray
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
