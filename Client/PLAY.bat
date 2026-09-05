@echo off
title MITE 1.6.4 Launcher
color 0A

echo ============================================
echo     MITE 1.6.4 - Minecraft Is Too Easy
echo ============================================
echo.
echo Starting launcher...
echo.

where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo PowerShell not found!
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0LAUNCHER.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Error while launching.
    pause
)
