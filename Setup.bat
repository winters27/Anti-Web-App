@echo off
color 0B
echo ========================================================
echo       Starting Anti-Web-App Setup Wizard
echo ========================================================
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0Wizard.ps1"
