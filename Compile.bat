@echo off
color 0B
echo ========================================================
echo       Anti-Web-App ^| Native C# Compiler
echo ========================================================
echo.
echo [ INFO ] Compiling Template.cs into Template.exe natively...
echo.

"C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /target:winexe /out:Template.exe /win32icon:icon.ico Template.cs

echo.
echo [ SUCCESS ] Your native executable has been securely built!
echo             You can now rename Template.exe and pin it.
echo.
pause
