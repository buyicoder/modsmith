# Fabric Versions MCP Server
# Queries fabricmc.net for latest version information

param(
    [string]$Action = "latest",
    [string]$McVersion = ""
)

$MetaUrl = "https://meta.fabricmc.net/v2"

function Get-LatestGameVersion {
    $versions = Invoke-RestMethod -Uri "$MetaUrl/versions/game" -ErrorAction Stop
    $stable = $versions | Where-Object { $_.stable } | Select-Object -First 1
    Write-Output @{
        version = $stable.version
        stable = $stable.stable
    } | ConvertTo-Json
}

function Get-LoaderVersion {
    param($mc)
    $loaders = Invoke-RestMethod -Uri "$MetaUrl/versions/loader/$mc" -ErrorAction Stop
    $latest = $loaders | Select-Object -First 1
    Write-Output @{
        mc_version = $mc
        loader_version = $latest.loader.version
    } | ConvertTo-Json
}

function Get-FabricApiVersion {
    param($mc)
    # Get latest fabric-api from Modrinth API
    $url = "https://api.modrinth.com/v2/project/fabric-api/version?loaders=%5B%22fabric%22%5D&game_versions=%5B%22$mc%22%5D"
    $versions = Invoke-RestMethod -Uri $url -ErrorAction Stop
    if ($versions.Count -gt 0) {
        Write-Output @{
            mc_version = $mc
            fabric_api_version = $versions[0].version_number
        } | ConvertTo-Json
    }
}

# Main
switch ($Action) {
    "latest" { Get-LatestGameVersion }
    "loader" { Get-LoaderVersion -mc $McVersion }
    "api" { Get-FabricApiVersion -mc $McVersion }
    "all" {
        $mc = Get-LatestGameVersion
        $loader = Get-LoaderVersion -mc $mc.version
        Write-Output @{
            minecraft = $mc.version
            loader = ($loader | ConvertFrom-Json).loader_version
        } | ConvertTo-Json
    }
}
