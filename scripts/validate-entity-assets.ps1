param(
    [Parameter(Mandatory=$true)][string]$ProjectDir,
    [Parameter(Mandatory=$true)][string]$ContractPath
)

Set-StrictMode -Version Latest
. "$PSScriptRoot\lib\EntityContract.ps1"

$errors = @()
$warnings = @()
$contract = Read-EntityContract -Path $ContractPath
$errors += @(Test-EntityContractShape -Contract $contract)

function Add-FileCheck {
    param([string]$Label, [string]$RelativePath)
    if (-not $RelativePath) {
        $script:warnings += "SKIP ${Label}: no path in contract"
        return
    }
    $full = Resolve-ModFactoryPath -ProjectDir $ProjectDir -RelativePath $RelativePath
    if (-not (Test-Path $full)) {
        $script:errors += "MISSING ${Label}: $RelativePath"
    }
}

Add-FileCheck "texture" $contract.texture.path
Add-FileCheck "model" $contract.model.javaPath
Add-FileCheck "renderer" $contract.renderer.javaPath

$texturePath = Resolve-ModFactoryPath -ProjectDir $ProjectDir -RelativePath $contract.texture.path
if (Test-Path $texturePath) {
    Add-Type -AssemblyName System.Drawing
    $img = [System.Drawing.Image]::FromFile($texturePath)
    try {
        if ($img.Width -ne [int]$contract.texture.width -or $img.Height -ne [int]$contract.texture.height) {
            $errors += "Texture dimensions mismatch: actual=$($img.Width)x$($img.Height) contract=$($contract.texture.width)x$($contract.texture.height)"
        }
    } finally {
        $img.Dispose()
    }
}

if ($contract.model.javaPath) {
    $modelPath = Resolve-ModFactoryPath -ProjectDir $ProjectDir -RelativePath $contract.model.javaPath
    if (Test-Path $modelPath) {
        $modelText = [System.IO.File]::ReadAllText($modelPath)
        $expected = "TexturedModelData.of(data, $($contract.model.textureWidth), $($contract.model.textureHeight))"
        if (-not $modelText.Contains($expected)) {
            $errors += "Model does not declare expected texture size: $expected"
        }
        foreach ($part in $contract.model.parts) {
            if (-not $modelText.Contains("`"$part`"")) {
                $warnings += "Model contract part not found in Java model: $part"
            }
        }
    }
}

Write-Host "=== ENTITY ASSET VALIDATION ==="
Write-Host "Contract: $ContractPath"
if ($warnings.Count) {
    Write-Host "WARNINGS:"
    $warnings | ForEach-Object { Write-Host "  $_" }
}
if ($errors.Count) {
    Write-Host "FAILURES:"
    $errors | ForEach-Object { Write-Host "  $_" }
    exit 1
}

Write-Host "PASS"
