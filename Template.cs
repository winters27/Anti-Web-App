using System;
using System.Diagnostics;
using System.Windows.Forms;
using System.IO;
using System.Reflection;

[assembly: AssemblyTitle("Anti-Web-App")]
[assembly: AssemblyDescription("Because launching a full browser just to change your hardware settings is absolutely ridiculous.")]
[assembly: AssemblyCompany("Anti-Web-App Foundation")]
[assembly: AssemblyProduct("Anti-Web-App")]
[assembly: AssemblyCopyright("Copyright C 2026")]

namespace AntiWebApp {
    class Program {
        [STAThread]
        static void Main() {
            // ===== CONFIGURATION =====
            string url = "https://gm.wlmouse.gg/#/project/items";
            int desiredWidth = 1270;
            int desiredHeight = 890;
            string profileDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "AntiWebApp_Profile_132773f8");
            // =========================

            string edge64 = @"C:\Program Files\Microsoft\Edge\Application\msedge.exe";
            string edge32 = @"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe";
            string edgeExe = File.Exists(edge64) ? edge64 : (File.Exists(edge32) ? edge32 : "msedge.exe");

            var wa = Screen.PrimaryScreen.WorkingArea;
            int x = (int)Math.Round((wa.Width - desiredWidth) / 2.0) + wa.Left;
            int y = (int)Math.Round((wa.Height - desiredHeight) / 2.0) + wa.Top;

            string argsLine = "--app=\"" + url + "\" " +
                              "--window-size=" + desiredWidth + "," + desiredHeight + " " +
                              "--window-position=" + x + "," + y + " " +
                              "--user-data-dir=\"" + profileDir + "\" " +
                              "--disable-extensions " +
                              "--disable-plugins " +
                              "--disable-background-networking " +
                              "--disable-sync " +
                              "--disable-translate " +
                              "--disable-default-apps " +
                              "--disable-component-extensions-with-background-pages " +
                              "--no-default-browser-check " +
                              "--no-first-run " +
                              "--disable-client-side-phishing-detection " +
                              "--disable-features=IsolateOrigins,site-per-process";

            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName = edgeExe;
            psi.Arguments = argsLine;
            psi.UseShellExecute = false;
            psi.CreateNoWindow = true;

            try {
                Process.Start(psi);
            } catch (Exception ex) {
                MessageBox.Show("Failed to launch Anti-Web-App.\n\n" + ex.Message, "Launch Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}
