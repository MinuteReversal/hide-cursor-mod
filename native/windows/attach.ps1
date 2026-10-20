param([int]$GameProcessId = 0, [string]$LogPath = "")
$ErrorActionPreference = "Stop"
if ($GameProcessId) {
    $game = Get-Process -Id $GameProcessId
} else {
    $games = @(Get-Process | Where-Object {
        $_.ProcessName -match '^isaac(-ng)?$' -and $_.MainWindowTitle -match 'Isaac'
    })
    if ($games.Count -ne 1) { throw "Start Isaac first; if multiple games are running, pass -GameProcessId." }
    $game = $games[0]
}
if (!$game.Path) { throw "Cannot read game executable path. Run the game and helper as the same user." }
$gameDirectory = Split-Path $game.Path
if (!$LogPath) {
    $pathInfo = Join-Path $gameDirectory 'savedatapath.txt'
    if (Test-Path -LiteralPath $pathInfo) {
        $line = Get-Content -LiteralPath $pathInfo | Where-Object { $_ -match '^Save Data Path:\s*(.+)$' } | Select-Object -First 1
        if ($line -match '^Save Data Path:\s*(.+)$') { $LogPath = Join-Path ($Matches[1].Trim()) 'log.txt' }
    }
}
if (!$LogPath -or !(Test-Path -LiteralPath $LogPath)) {
    throw 'Pass -LogPath with the active game log.txt path (see savedatapath.txt in the game directory).'
}
if (-not ('HideCursorBinary' -as [type])) {
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class HideCursorBinary {
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern bool GetBinaryType(string path, out uint type);
}
'@
}
[uint32]$binaryType = 0
if (![HideCursorBinary]::GetBinaryType($game.Path, [ref]$binaryType)) { throw 'Cannot determine game architecture.' }
if ($binaryType -eq 6) { $architecture = 'x64' }
elseif ($binaryType -eq 0) { $architecture = 'x86' }
else { throw "Unsupported game binary type: $binaryType" }
$helper = Join-Path $PSScriptRoot "build/$architecture/HideCursor.exe"
if (!(Test-Path -LiteralPath $helper)) { throw "Missing helper: $helper. Build it or use the packaged preview." }
& $helper $game.Id $LogPath
exit $LASTEXITCODE
