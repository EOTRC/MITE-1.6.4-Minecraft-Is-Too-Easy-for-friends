@echo off
chcp 65001 >nul
title MITE 1.6.4 Setup
color 0B

echo ============================================
echo     MITE 1.6.4 - Setup
echo ============================================
echo.
echo Libraries are already included in this pack.
echo You usually do NOT need to run setup.
echo.
echo Press any key to run setup anyway (download missing libs)...
pause >nul

where powershell >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo PowerShell not found!
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0SETUP.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Error occurred
    pause
)
