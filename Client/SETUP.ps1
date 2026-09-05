$ErrorActionPreference = "Continue"
$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$minecraftDir = Join-Path $baseDir ".minecraft"
$librariesDir = Join-Path $minecraftDir "libraries"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "     MITE 1.6.4 - Setup / Verify" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $librariesDir)) {
    New-Item -ItemType Directory -Path $librariesDir -Force | Out-Null
}

function Download-File {
    param([string]$Url, [string]$OutputPath)
    $dir = Split-Path $OutputPath -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($Url, $OutputPath)
        return $true
    } catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

$libraries = @(
    @{Name="jopt-simple"; Path="net\sf\jopt-simple\jopt-simple\4.5\jopt-simple-4.5.jar"; Url="https://repo1.maven.org/maven2/net/sf/jopt-simple/jopt-simple/4.5/jopt-simple-4.5.jar"},
    @{Name="codecjorbis"; Path="com\paulscode\codecjorbis\20101023\codecjorbis-20101023.jar"; Url="https://libraries.minecraft.net/com/paulscode/codecjorbis/20101023/codecjorbis-20101023.jar"},
    @{Name="codecwav"; Path="com\paulscode\codecwav\20101023\codecwav-20101023.jar"; Url="https://libraries.minecraft.net/com/paulscode/codecwav/20101023/codecwav-20101023.jar"},
    @{Name="libraryjavasound"; Path="com\paulscode\libraryjavasound\20101123\libraryjavasound-20101123.jar"; Url="https://libraries.minecraft.net/com/paulscode/libraryjavasound/20101123/libraryjavasound-20101123.jar"},
    @{Name="librarylwjglopenal"; Path="com\paulscode\librarylwjglopenal\20100824\librarylwjglopenal-20100824.jar"; Url="https://libraries.minecraft.net/com/paulscode/librarylwjglopenal/20100824/librarylwjglopenal-20100824.jar"},
    @{Name="soundsystem"; Path="com\paulscode\soundsystem\20120107\soundsystem-20120107.jar"; Url="https://libraries.minecraft.net/com/paulscode/soundsystem/20120107/soundsystem-20120107.jar"},
    @{Name="argo"; Path="argo\argo\2.25_fixed\argo-2.25_fixed.jar"; Url="https://libraries.minecraft.net/argo/argo/2.25_fixed/argo-2.25_fixed.jar"},
    @{Name="bcprov"; Path="org\bouncycastle\bcprov-jdk15on\1.47\bcprov-jdk15on-1.47.jar"; Url="https://repo1.maven.org/maven2/org/bouncycastle/bcprov-jdk15on/1.47/bcprov-jdk15on-1.47.jar"},
    @{Name="guava"; Path="com\google\guava\guava\14.0\guava-14.0.jar"; Url="https://repo1.maven.org/maven2/com/google/guava/guava/14.0/guava-14.0.jar"},
    @{Name="commons-lang3"; Path="org\apache\commons\commons-lang3\3.1\commons-lang3-3.1.jar"; Url="https://repo1.maven.org/maven2/org/apache/commons/commons-lang3/3.1/commons-lang3-3.1.jar"},
    @{Name="commons-io"; Path="commons-io\commons-io\2.4\commons-io-2.4.jar"; Url="https://repo1.maven.org/maven2/commons-io/commons-io/2.4/commons-io-2.4.jar"},
    @{Name="jinput"; Path="net\java\jinput\jinput\2.0.5\jinput-2.0.5.jar"; Url="https://repo1.maven.org/maven2/net/java/jinput/jinput/2.0.5/jinput-2.0.5.jar"},
    @{Name="jutils"; Path="net\java\jutils\jutils\1.0.0\jutils-1.0.0.jar"; Url="https://repo1.maven.org/maven2/net/java/jutils/jutils/1.0.0/jutils-1.0.0.jar"},
    @{Name="gson"; Path="com\google\code\gson\gson\2.2.2\gson-2.2.2.jar"; Url="https://repo1.maven.org/maven2/com/google/code/gson/gson/2.2.2/gson-2.2.2.jar"},
    @{Name="lwjgl"; Path="org\lwjgl\lwjgl\lwjgl\2.9.0\lwjgl-2.9.0.jar"; Url="https://repo1.maven.org/maven2/org/lwjgl/lwjgl/lwjgl/2.9.0/lwjgl-2.9.0.jar"},
    @{Name="lwjgl_util"; Path="org\lwjgl\lwjgl\lwjgl_util\2.9.0\lwjgl_util-2.9.0.jar"; Url="https://repo1.maven.org/maven2/org/lwjgl/lwjgl/lwjgl_util/2.9.0/lwjgl_util-2.9.0.jar"}
)

$natives = @(
    @{Name="lwjgl-natives"; Path="org\lwjgl\lwjgl\lwjgl-platform\2.9.0\natives-windows\lwjgl-platform-2.9.0-natives-windows.jar"; Url="https://libraries.minecraft.net/org/lwjgl/lwjgl/lwjgl-platform/2.9.0/lwjgl-platform-2.9.0-natives-windows.jar"},
    @{Name="jinput-natives"; Path="net\java\jinput\jinput-platform\2.0.5\natives-windows\jinput-platform-2.0.5-natives-windows.jar"; Url="https://libraries.minecraft.net/net/java/jinput/jinput-platform/2.0.5/jinput-platform-2.0.5-natives-windows.jar"}
)

Write-Host "Checking libraries..." -ForegroundColor Yellow
$ok = 0; $fail = 0

foreach ($lib in $libraries) {
    $out = Join-Path $librariesDir $lib.Path
    if (Test-Path $out) {
        Write-Host "  [OK] $($lib.Name)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "  [..] downloading $($lib.Name)..." -ForegroundColor Gray
        if (Download-File $lib.Url $out) {
            Write-Host "  [OK] $($lib.Name) downloaded" -ForegroundColor Green
            $ok++
        } else {
            Write-Host "  [!!] $($lib.Name) failed" -ForegroundColor Red
            $fail++
        }
    }
}

Write-Host ""
Write-Host "Checking natives jars..." -ForegroundColor Yellow
foreach ($n in $natives) {
    $out = Join-Path $librariesDir $n.Path
    if (Test-Path $out) {
        Write-Host "  [OK] $($n.Name)" -ForegroundColor Green
        $ok++
    } else {
        Write-Host "  [..] downloading $($n.Name)..." -ForegroundColor Gray
        if (Download-File $n.Url $out) {
            Write-Host "  [OK] $($n.Name) downloaded" -ForegroundColor Green
            $ok++
            $extractDir = Split-Path $out -Parent
            try {
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                [System.IO.Compression.ZipFile]::ExtractToDirectory($out, $extractDir)
            } catch {}
        } else {
            Write-Host "  [!!] $($n.Name) failed" -ForegroundColor Red
            $fail++
        }
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Result: OK=$ok  Fail=$fail" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
if ($fail -eq 0) {
    Write-Host "Everything is ready. Run PLAY.bat" -ForegroundColor Green
} else {
    Write-Host "Some files missing. Check internet or run again." -ForegroundColor Yellow
}
Write-Host ""
Read-Host "Press Enter to exit"
