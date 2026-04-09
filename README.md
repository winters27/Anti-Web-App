# Anti-Web-App (The "I Refuse to Open Edge" Wrapper)

A hyper-optimized, native Windows hardware dashboard wrapper.

If you bought a piece of hardware recently (like a WL Mouse, Arbiter keyboard, or Wooting) you might have noticed the new trend: **"No software required! Just use our Web App!"** 

That sounds great, until you realize these Web Apps rely on Google Chrome's WebHID API to talk to your USB devices. If you're a gigachad daily-driving a Firefox fork (like Zen browser) or literally anything else, you fall into a frustrating trap where you are forced to keep a bloated Chromium browser installed *just* to change your mouse DPI.

**This is the solution.**

Since your Windows machine is already infected with `msedge.exe` at an OS level (we can't escape it), this toolkit forcefully rips the Chromium WebHID engine out of the Edge background processes, strips away all the telemetry/extensions/bloat flags, and packages your hardware dashboard into a clean, standalone, silent `.exe`. 

No browser chrome. No Edge syncing. Just the WebHID connection you need, wrapped safely entirely within a native desktop window.

---

## The Setup Wizard (All-In-One Installer)

We have consolidated the entire backend into a single `Setup.bat` wizard. Absolutely no coding or text editing is required.

### 1. Launch the Wizard
Double-click `Setup.bat` in your folder. A terminal will open and prompt you:
`[?] Please paste your hardware Web App URL (e.g. https://dashboard.your-device.com):`

Paste your link and hit `ENTER`.

### 2. Visually Resize
The wizard will launch the dashboard for you. Physically drag the edges of the window with your mouse until all the white space is gone and the inner dashboard is perfectly framed exactly how you want it. 

### 3. Finalize & Compile
Once your sizing is perfect, click back into the black `Setup.bat` terminal and hit `ENTER`. 

The wizard handles everything else automatically:
1. It rips the exact physical footprint of the window you just drew.
2. It fetches the site's official `favicon.ico` from the web.
3. It natively compiles a brand new, silent `Anti-Web-App.exe` executable using Windows' hidden internal C# compiler.

Done! You now have a blazingly fast, standalone `.exe` you can rename to whatever your hardware is (e.g., `DeviceDashboard.exe`) and pin to your taskbar!

