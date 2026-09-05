$ErrorActionPreference = "Continue"
$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$packRoot = Split-Path -Parent $baseDir
$minecraftDir = Join-Path $baseDir ".minecraft"
$versionsDir = Join-Path $minecraftDir "versions"
$librariesDir = Join-Path $minecraftDir "libraries"

$jreCandidates = @(
    (Join-Path $baseDir "jre8"),
    (Join-Path $packRoot "jre8")
)

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "     MITE 1.6.4 - Launcher" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

function Test-JavaExe {
    param([string]$exe)
    if (-not $exe -or -not (Test-Path $exe)) { return $false }
    try {
        $out = & $exe -version 2>&1 | Out-String
        return ($out -match "version")
    } catch { return $false }
}

function Download-PortableJre8 {
    param([string]$TargetDir)
    Write-Host ""
    Write-Host "  Downloading portable Java 8 into:" -ForegroundColor Yellow
    Write-Host "  $TargetDir" -ForegroundColor White
    Write-Host "  (~40 MB, one time)" -ForegroundColor Gray
    Write-Host ""

    $apiUrl = "https://api.adoptium.net/v3/binary/latest/8/ga/windows/x64/jre/hotspot/normal/eclipse?project=jdk"
    $zipPath = Join-Path $env:TEMP "OpenJDK8U-jre_x64_windows.zip"
    $extractTemp = Join-Path $env:TEMP "mite_jre8_extract"

    try {
        if (Test-Path $zipPath) { Remove-Item $zipPath -Force -ErrorAction SilentlyContinue }
        if (Test-Path $extractTemp) { Remove-Item $extractTemp -Recurse -Force -ErrorAction SilentlyContinue }

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "MITE-Launcher")
        Write-Host "  Connecting to Adoptium..." -ForegroundColor Gray
        $wc.DownloadFile($apiUrl, $zipPath)

        if (-not (Test-Path $zipPath) -or ((Get-Item $zipPath).Length -lt 1MB)) {
            throw "Download failed or file too small"
        }
        $sizeMb = [math]::Round((Get-Item $zipPath).Length / 1MB, 1)
        Write-Host "  Downloaded: $sizeMb MB" -ForegroundColor Green

        Write-Host "  Extracting..." -ForegroundColor Gray
        New-Item -ItemType Directory -Path $extractTemp -Force | Out-Null
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $extractTemp)

        $inner = Get-ChildItem $extractTemp -Directory | Select-Object -First 1
        if (-not $inner) { throw "Unexpected archive structure" }

        if (Test-Path $TargetDir) {
            Remove-Item $TargetDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        $parent = Split-Path $TargetDir -Parent
        if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Move-Item $inner.FullName $TargetDir -Force

        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
        Remove-Item $extractTemp -Recurse -Force -ErrorAction SilentlyContinue

        $javaExe = Join-Path $TargetDir "bin\java.exe"
        if (-not (Test-Path $javaExe)) { throw "java.exe not found after extract" }

        Write-Host "  Portable Java 8 ready" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  Download failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

Write-Host "[1] Java: using pack jre8 only" -ForegroundColor Yellow

$javaPath = $null
$usedJreDir = $null

foreach ($dir in $jreCandidates) {
    $exe = Join-Path $dir "bin\java.exe"
    if (Test-JavaExe $exe) {
        $javaPath = $exe
        $usedJreDir = $dir
        Write-Host "  Found: $javaPath" -ForegroundColor Green
        break
    }
}

if (-not $javaPath) {
    $downloadTarget = Join-Path $packRoot "jre8"
    Write-Host "  jre8 not found in pack - downloading..." -ForegroundColor Yellow
    if (Download-PortableJre8 -TargetDir $downloadTarget) {
        $exe = Join-Path $downloadTarget "bin\java.exe"
        if (Test-JavaExe $exe) {
            $javaPath = $exe
            $usedJreDir = $downloadTarget
            Write-Host "  Using: $javaPath" -ForegroundColor Green
        }
    }
}

if (-not $javaPath) {
    Write-Host ""
    Write-Host "  FATAL: Could not get portable Java 8." -ForegroundColor Red
    Write-Host "  Check internet connection and try again." -ForegroundColor Yellow
    Write-Host "  Manual: https://adoptium.net/temurin/releases/?version=8" -ForegroundColor Yellow
    Write-Host "  Put extracted JRE into folder: $packRoot\jre8" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

try {
    $verLine = & $javaPath -version 2>&1 | Select-Object -First 1
    Write-Host "  Version: $verLine" -ForegroundColor Gray
} catch {}

Write-Host "[2] Looking for natives..." -ForegroundColor Yellow
$nativesDir = Join-Path $minecraftDir "natives"
if (-not (Test-Path $nativesDir)) {
    New-Item -ItemType Directory -Path $nativesDir -Force | Out-Null
}
foreach ($src in @(
    (Join-Path $librariesDir "org\lwjgl\lwjgl\lwjgl-platform\2.9.0\natives-windows"),
    (Join-Path $librariesDir "net\java\jinput\jinput-platform\2.0.5\natives-windows")
)) {
    if (Test-Path $src) {
        Get-ChildItem $src -Filter "*.dll" -ErrorAction SilentlyContinue | ForEach-Object {
            $dest = Join-Path $nativesDir $_.Name
            if (-not (Test-Path $dest)) { Copy-Item $_.FullName $dest -Force }
        }
    }
}
$dllCount = @(Get-ChildItem $nativesDir -Filter "*.dll" -ErrorAction SilentlyContinue).Count
if ($dllCount -eq 0) {
    Write-Host "  No natives (DLL) found!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "  Natives ready ($dllCount DLL)" -ForegroundColor Green

Write-Host "[3] Checking MITE jar..." -ForegroundColor Yellow
$miteJar = Join-Path $versionsDir "1.6.4-MITE\1.6.4-MITE.jar"
if (-not (Test-Path $miteJar)) {
    Write-Host "  Missing: $miteJar" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "  OK" -ForegroundColor Green

Write-Host "[4] Building classpath..." -ForegroundColor Yellow

function Get-RelPath($full, $base) {
    $f = [System.IO.Path]::GetFullPath($full)
    $b = [System.IO.Path]::GetFullPath($base).TrimEnd([char]'\', [char]'/')
    if ($f.StartsWith($b, [StringComparison]::OrdinalIgnoreCase)) {
        return $f.Substring($b.Length).TrimStart([char]'\', [char]'/')
    }
    return $f
}

$cpList = New-Object System.Collections.Generic.List[string]
$cpList.Add((Get-RelPath $miteJar $minecraftDir))
Get-ChildItem $librariesDir -Recurse -Filter "*.jar" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch "natives" } |
    ForEach-Object { $cpList.Add((Get-RelPath $_.FullName $minecraftDir)) }
$cpStr = ($cpList -join ";")
Write-Host "  JARs: $($cpList.Count)" -ForegroundColor Green

$defaultName = "Player"
Write-Host ""
$username = Read-Host "Enter player name (or Enter for '$defaultName')"
if ([string]::IsNullOrWhiteSpace($username)) { $username = $defaultName }
$username = ($username.Trim() -replace '[^\w\-]', '_')
if ($username.Length -gt 16) { $username = $username.Substring(0, 16) }

$uuid = [guid]::NewGuid().ToString("N")
$version = "1.6.4-MITE"
$assetsDir = Join-Path $minecraftDir "assets"
$mainClass = "net.minecraft.client.main.Main"

if (-not (Test-Path $assetsDir)) {
    New-Item -ItemType Directory -Path $assetsDir -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $assetsDir "indexes") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $assetsDir "objects") -Force | Out-Null
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  LAUNCHING MITE 1.6.4" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Player : $username" -ForegroundColor White
Write-Host "  Java   : $javaPath" -ForegroundColor White
Write-Host "  (pack jre8 - system Java is ignored)" -ForegroundColor Gray
Write-Host ""

$javaAbs = [System.IO.Path]::GetFullPath($javaPath)
$nativesAbs = [System.IO.Path]::GetFullPath($nativesDir)
$minecraftAbs = [System.IO.Path]::GetFullPath($minecraftDir)
$assetsAbs = [System.IO.Path]::GetFullPath($assetsDir)

$launchBat = Join-Path $baseDir "_launch_temp.bat"

$batLines = @(
    "@echo off",
    "cd /d `"$minecraftAbs`"",
    "`"$javaAbs`" -Xmx1G -Xms512M `"-Djava.library.path=$nativesAbs`" -cp `"$cpStr`" $mainClass --username $username --version $version --gameDir `"$minecraftAbs`" --assetsDir `"$assetsAbs`" --accessToken 0 --uuid $uuid --userProperties {}",
    "set ERR=%ERRORLEVEL%",
    "if %ERR% NEQ 0 (",
    "  echo.",
    "  echo Game exited with code %ERR%",
    "  pause",
    ")",
    "exit /b %ERR%"
)
$batContent = ($batLines -join "`r`n") + "`r`n"
[System.IO.File]::WriteAllText($launchBat, $batContent, (New-Object System.Text.UTF8Encoding $false))

Write-Host "Starting game with pack jre8..." -ForegroundColor Green
$p = Start-Process -FilePath $launchBat -WorkingDirectory $baseDir -Wait -PassThru
if ($p.ExitCode -ne 0) {
    Write-Host "Exit code: $($p.ExitCode)" -ForegroundColor Red
    Write-Host ""
    Write-Host "If lwjgl.dll / dependent libraries error:" -ForegroundColor Yellow
    Write-Host "  Install VC++ Redistributable x64:" -ForegroundColor Yellow
    Write-Host "  https://aka.ms/vs/17/release/vc_redist.x64.exe" -ForegroundColor White
} else {
    Write-Host "Game closed." -ForegroundColor Green
}

Remove-Item $launchBat -Force -ErrorAction SilentlyContinue

Write-Host ""
Read-Host "Press Enter to close this window"
