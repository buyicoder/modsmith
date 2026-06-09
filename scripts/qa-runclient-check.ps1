param([Parameter(Mandatory=$true)][string]$LogPath)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-SharedText {
    param([Parameter(Mandatory=$true)][string]$Path)
    $stream = [System.IO.File]::Open(
        $Path,
        [System.IO.FileMode]::Open,
        [System.IO.FileAccess]::Read,
        [System.IO.FileShare]::ReadWrite
    )
    try {
        $reader = [System.IO.StreamReader]::new($stream)
        try {
            return $reader.ReadToEnd()
        } finally {
            $reader.Dispose()
        }
    } finally {
        $stream.Dispose()
    }
}

$text = Read-SharedText -Path $LogPath
$checks = @(
    @{ "name" = "minecraft-loaded"; "pattern" = "Loading Minecraft"; "required" = $true },
    @{ "name" = "mod-loaded"; "pattern" = "modid"; "required" = $true },
    @{ "name" = "resource-reload"; "pattern" = "Reloading ResourceManager"; "required" = $true },
    @{ "name" = "entered-world"; "pattern" = "logged in with entity id|joined the game"; "required" = $false },
    @{ "name" = "no-crash"; "pattern" = "BUILD FAILED|Exception in thread|Caused by:|Crash report|ERROR"; "required" = $true; "inverse" = $true }
)

$failed = @()
foreach ($check in $checks) {
    $name = $check["name"]
    $matched = $text -match $check["pattern"]
    if ($check.ContainsKey("inverse") -and $check.inverse) {
        $matched = -not $matched
    }
    if ($check["required"] -and -not $matched) {
        $failed += $name
    }
    Write-Host "${name}: $matched"
}

if ($failed.Count) {
    Write-Host "FAILURES: $($failed -join ', ')"
    exit 1
}

Write-Host "PASS"
