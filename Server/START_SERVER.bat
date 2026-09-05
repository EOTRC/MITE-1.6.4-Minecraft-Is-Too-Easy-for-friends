@echo off
setlocal
title MITE 1.6.4 Server
color 0B

echo ============================================
echo     MITE 1.6.4 Server
echo ============================================
echo.

set "JAVA_EXE="

REM Always prefer pack jre8
if exist "%~dp0..\jre8\bin\java.exe" (
    set "JAVA_EXE=%~dp0..\jre8\bin\java.exe"
    echo Using pack jre8
    goto run
)
if exist "%~dp0jre8\bin\java.exe" (
    set "JAVA_EXE=%~dp0jre8\bin\java.exe"
    echo Using local jre8
    goto run
)

echo jre8 not found!
echo Run Client\PLAY.bat once - it will download jre8 automatically.
echo.
pause
exit /b 1

:run
echo Java: %JAVA_EXE%
echo.
echo Starting server on port 25565 ...
echo Type "stop" to shut down.
echo.

cd /d "%~dp0"
"%JAVA_EXE%" -Xmx1G -Xms512M -cp "minecraft_server.1.6.4-MITE.jar" net.minecraft.server.MinecraftServer nogui

echo.
echo Server stopped.
pause
