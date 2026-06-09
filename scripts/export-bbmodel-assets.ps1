param(
    [Parameter(Mandatory=$true)][string]$BbmodelPath,
    [Parameter(Mandatory=$true)][string]$ProjectDir,
    [Parameter(Mandatory=$true)][string]$EntityName,
    [string]$ModId = "modid"
)

Set-StrictMode -Version Latest
. "$PSScriptRoot\lib\ModFactory.Path.ps1"

$bb = Read-Utf8Json -Path $BbmodelPath
$texture = $bb.textures | Where-Object { $_.source } | Select-Object -First 1
if (-not $texture) {
    throw "No embedded texture found in $BbmodelPath"
}

$source = [string]$texture.source
if ($source.Contains(",")) {
    $source = $source.Substring($source.IndexOf(",") + 1)
}

$textureRel = "src/main/resources/assets/$ModId/textures/entity/$EntityName.png"
$texturePath = Resolve-ModFactoryPath -ProjectDir $ProjectDir -RelativePath $textureRel
Ensure-ParentDirectory -Path $texturePath
[System.IO.File]::WriteAllBytes($texturePath, [Convert]::FromBase64String($source))

$parts = @($bb.elements | Where-Object { $_.type -eq "cube" } | ForEach-Object { $_.name } | Select-Object -Unique)
$animations = @()
if ($bb.PSObject.Properties["animations"]) {
    $animations = @($bb.animations | ForEach-Object { $_.name })
}

$contract = [ordered]@{
    schemaVersion = 1
    entityId = "$ModId`:$EntityName"
    displayName = ($EntityName -replace "_", " ")
    reference = [ordered]@{
        source = ""
        bbmodelPath = $BbmodelPath
    }
    texture = [ordered]@{
        path = $textureRel
        width = [int]$bb.resolution.width
        height = [int]$bb.resolution.height
        source = "embedded-bbmodel"
    }
    model = [ordered]@{
        javaPath = ""
        textureWidth = [int]$bb.resolution.width
        textureHeight = [int]$bb.resolution.height
        parts = $parts
    }
    renderer = [ordered]@{
        javaPath = ""
        textureIdentifier = "$ModId`:textures/entity/$EntityName.png"
    }
    runtime = [ordered]@{
        entityTypeField = ($EntityName.ToUpper())
        dimensions = [ordered]@{ width = 0.6; height = 1.8 }
        spawnEgg = "$ModId`:${EntityName}_spawn_egg"
        bossBar = $false
    }
    animations = $animations
}

$contractRel = "models/$EntityName.contract.json"
$contractPath = Resolve-ModFactoryPath -ProjectDir $ProjectDir -RelativePath $contractRel
Ensure-ParentDirectory -Path $contractPath
Write-Utf8Json -Path $contractPath -Value $contract

Write-Host "EXPORTED texture=$textureRel contract=$contractRel parts=$($parts.Count) animations=$($animations.Count)"
