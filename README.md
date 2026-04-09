# Anti-Web-App (The "I Refuse to Open Edge" Wrapper)

A hyper-optimized, native Windows hardware dashboard wrapper.

If you bought a piece of hardware recently (like a WL Mouse, Arbiter keyboard, or Wooting) you might have noticed the new trend: **"No software required! Just use our Web App!"** 

That sounds great, until you realize these Web Apps rely on Google Chrome's WebHID API to talk to your USB devices. If you're a gigachad daily-driving a Firefox fork (like Zen browser) or literally anything else, you fall into a frustrating trap where you are forced to keep a bloated Chromium browser installed *just* to change your mouse DPI.

**This is the solution.**

Since your Windows machine is already infected with `msedge.exe` at an OS level (we can't escape it), this toolkit forcefully rips the Chromium WebHID engine out of the Edge background processes, strips away all the telemetry/extensions/bloat flags, and packages your hardware dashboard into a clean, standalone, silent `.exe`. 

No browser chrome. No Edge syncing. Just the WebHID connection you need, wrapped safely entirely within a native desktop window.

---

## How to Wrap Your Web App

This is a master template. To customize it to fit your exact hardware (be it a keyboard, mouse, or toaster), follow these 4 steps:

### 1. Grab Your Web App URL
Find the official web app link for your hardware (e.g. `https://gm.wlmouse.gg/#/` or `https://miceapp.arbiterstudio.com/#/`).
Open `Template.ps1` in a text editor and replace the `$Url` variable at the top.

### 2. Visually Resize to Perfection
Run your freshly edited `Template.ps1` (Right Click -> Run with PowerShell). It will pop up a window. Physically drag the edges of the window with your mouse until all the white space is gone and the inner dashboard is perfectly framed. 

Leave the window open.

### 3. Extract the Golden Dimensions
While your perfectly sized window is still open, paste this quick command into any normal PowerShell prompt to extract the exact math:

```powershell
$cs = @"
using System;
using System.Runtime.InteropServices;
public static class W32 {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out RECT lpRect);
}
"@
Add-Type -TypeDefinition $cs -ErrorAction SilentlyContinue
Get-Process msedge | Where-Object { $_.MainWindowTitle } | ForEach-Object {
    $rect = New-Object W32+RECT
    [W32]::GetWindowRect($_.MainWindowHandle, [ref]$rect) | Out-Null
    $w = $rect.Right - $rect.Left
    $h = $rect.Bottom - $rect.Top
    "Title: $($_.MainWindowTitle), Width: $w, Height: $h"
}
```
Find the exact `Width` and `Height` returned for your Web App!

### 4. Compile the Native `.exe`

1. Open `Template.cs`.
2. Update the `url`, `desiredWidth`, and `desiredHeight` variables using the exact numbers you extracted.
3. Drop an icon file (like `icon.ico`) into the same folder as `Template.cs`. 
4. Run this magical 1-liner in your terminal to compile your new standalone dashboard natively, securely, and silently. Note: replace `Template.exe` with whatever you want to call it!

```powershell
& "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /target:winexe /out:Template.exe /win32icon:icon.ico Template.cs
```

Done! You now have a blazingly fast, standalone `.exe` you can pin to your taskbar that never requires you to touch Edge again.
