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

### 3. The Setup Wizard Extraction
When your window is sized exactly how you want it, simply swap back to the black PowerShell terminal and hit `ENTER`. 

The script will:
1. Instantly read the exact dimensional bounds of your App on the screen.
2. Apply native mathematical rounding (e.g. padding a raw `1268x881` up to a clean `1270x880`).
3. Automatically patch those golden dimensions strictly into your `Template.cs` file.

### 4. Compile the Native `.exe`
With your `Template.cs` completely auto-configured by the setup wizard:
1. Simply double-click **`Compile.bat`**. 
2. It will securely and silently build your brand new `Template.exe` using Windows' internal C# compiler.
3. You can now rename `Template.exe` to whatever your hardware is (e.g. `Akitsu.exe`) and pin it anywhere!

Done! You now have a blazingly fast, standalone `.exe` you can pin to your taskbar that never requires you to touch Edge again.
