Set-StrictMode -Version Latest

function Resolve-ModFactoryPath {
    param(
        [Parameter(Mandatory=$true)][string]$ProjectDir,
        [Parameter(Mandatory=$true)][string]$RelativePath
    )
    return [System.IO.Path]::GetFullPath((Join-Path $ProjectDir $RelativePath))
}

function Read-Utf8Json {
    param([Parameter(Mandatory=$true)][string]$Path)
    $text = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    return $text | ConvertFrom-Json
}

function Write-Utf8Json {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)]$Value
    )
    $json = $Value | ConvertTo-Json -Depth 20
    $utf8 = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $json + [Environment]::NewLine, $utf8)
}

function Ensure-ParentDirectory {
    param([Parameter(Mandatory=$true)][string]$Path)
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent | Out-Null
    }
}
