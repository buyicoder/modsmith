Set-StrictMode -Version Latest
. "$PSScriptRoot\ModFactory.Path.ps1"

function Read-EntityContract {
    param([Parameter(Mandatory=$true)][string]$Path)
    return Read-Utf8Json -Path $Path
}

function Test-EntityContractShape {
    param([Parameter(Mandatory=$true)]$Contract)
    $errors = @()
    foreach ($name in @("schemaVersion","entityId","texture","model","renderer","runtime","animations")) {
        if (-not $Contract.PSObject.Properties[$name]) {
            $errors += "Missing contract field: $name"
        }
    }
    if ($Contract.schemaVersion -ne 1) {
        $errors += "Unsupported schemaVersion: $($Contract.schemaVersion)"
    }
    if ($Contract.entityId -notmatch "^[a-z0-9_.-]+:[a-z0-9_./-]+$") {
        $errors += "Invalid entityId: $($Contract.entityId)"
    }
    if ($Contract.texture.width -le 0 -or $Contract.texture.height -le 0) {
        $errors += "Texture width/height must be positive"
    }
    if ($Contract.model.textureWidth -ne $Contract.texture.width -or
        $Contract.model.textureHeight -ne $Contract.texture.height) {
        $errors += "Model texture size does not match texture dimensions"
    }
    if ($errors.Count -eq 0) {
        return @()
    }
    return $errors
}
