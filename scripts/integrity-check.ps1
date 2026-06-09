# ModSmith Integrity Checker
# Scans project for missing connections between registrations and resources

param([string]$ProjectDir = ".")

$errors = @()
$warnings = @()
$passes = @()

# ============================================================
# Scanning functions
# ============================================================

function Find-JavaFiles($pattern) {
    Get-ChildItem -Path $ProjectDir -Recurse -Filter "*.java" -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch "\\build\\" } |
        Select-String $pattern -List
}

function Find-RegisteredItems {
    $items = @()
    $files = Get-ChildItem -Path $ProjectDir -Recurse -Filter "ModItems.java" -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch "\\build\\" }
    foreach ($f in $files) {
        $content = Get-Content $f.FullName -Raw
        # Extract: public static final Item NAME = register("name", ...
        $matches = [regex]::Matches($content, 'register\("([^"]+)"')
        foreach ($m in $matches) {
            $name = $m.Groups[1].Value
            $line = ($content -split "`n" | Select-String "register.`"$name`"" | Select-Object -First 1).Line
            # Detect type: armor/tool/food/material
            $type = "material"
            if ($line -match "EquipmentType\.") { $type = "armor" }
            elseif ($line -match "\.sword\(|\.pickaxe\(|AxeItem|ShovelItem|HoeItem") { $type = "tool" }
            elseif ($line -match "FoodComponent|\.food\(") { $type = "food" }
            elseif ($line -match "LightningRubyItem|extends Item") { $type = "special" }
            $items += @{ name = $name; type = $type }
        }
    }
    return $items
}

function Find-RegisteredBlocks {
    $blocks = @()
    $files = Get-ChildItem -Path $ProjectDir -Recurse -Filter "ModBlocks.java" -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch "\\build\\" }
    foreach ($f in $files) {
        $content = Get-Content $f.FullName -Raw
        $matches = [regex]::Matches($content, 'register\("([^"]+)"')
        foreach ($m in $matches) {
            $blocks += @{ name = $m.Groups[1].Value }
        }
    }
    return $blocks
}

function Find-MixinClasses {
    $mixins = @()
    $files = Get-ChildItem -Path $ProjectDir -Recurse -Filter "*.java" -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch "\\build\\" }
    foreach ($f in $files) {
        $content = Get-Content $f.FullName -Raw
        if ($content -match "@Mixin") {
            $className = $f.BaseName
            $mixins += @{ name = $className; file = $f.FullName }
        }
    }
    return $mixins
}

function Test-FileExists($relativePath) {
    $fullPath = Join-Path $ProjectDir "src/main/resources/$relativePath"
    return Test-Path $fullPath
}

function Test-AnyFileExists($pattern) {
    $files = Get-ChildItem -Path "$ProjectDir/src/main/resources" -Recurse -Filter "*.json" -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch "\\build\\" }
    # Search in recipe files for item ID
    foreach ($f in $files) {
        $content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -match $pattern) { return $true }
    }
    return $false
}

# ============================================================
# Check Rules
# ============================================================

function Check-Item($item) {
    $id = $item.name
    $type = $item.type
    $prefix = if ($type -eq "armor" -or $type -eq "tool") { "ruby_" } else { "" }

    # Rule 1: Texture
    if (Test-FileExists "assets/modid/textures/item/${id}.png") {
        $script:passes += "texture: $id"
    } else {
        $script:errors += "MISSING: assets/modid/textures/item/${id}.png"
    }

    # Rule 1b: Model
    if (Test-FileExists "assets/modid/models/item/${id}.json") {
        $script:passes += "model: $id"
    } else {
        $script:errors += "MISSING: assets/modid/models/item/${id}.json"
    }

    # Rule 2: Creative tab (check ExampleMod.java)
    $mainMod = Get-ChildItem -Path $ProjectDir -Recurse -Filter "ExampleMod.java" -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch "\\build\\" } | Select-Object -First 1
    if ($mainMod) {
        $content = Get-Content $mainMod.FullName -Raw
        if ($content -match [regex]::Escape("ModItems.$($id.ToUpper())") -or
            $content -match [regex]::Escape("ModBlocks.$($id.ToUpper())")) {
            $script:passes += "tab: $id"
        } else {
            $script:warnings += "NOT_IN_TAB: $id (not added to creative inventory)"
        }
    }

    # Rule 3: Recipe
    if (Test-AnyFileExists "modid:$id") {
        $script:passes += "recipe: $id"
    } else {
        if ($type -ne "special") {
            $script:warnings += "NO_RECIPE: $id (no crafting recipe found)"
        }
    }

    # Rule 4/6: Armor equipment
    if ($type -eq "armor") {
        # Extract armor material name (everything before _helmet/_chestplate/etc.)
        $matName = $id -replace '_(helmet|chestplate|leggings|boots)$', ''
        if (Test-FileExists "assets/modid/equipment/${matName}.json") {
            $script:passes += "equipment_json: $id"
        } else {
            $script:errors += "MISSING: assets/modid/equipment/${matName}.json"
        }
        if (Test-FileExists "assets/modid/textures/entity/equipment/humanoid/${matName}.png") {
            $script:passes += "equipment_humanoid: $id"
        } else {
            $script:errors += "MISSING: textures/entity/equipment/humanoid/${matName}.png"
        }
        if (Test-FileExists "assets/modid/textures/entity/equipment/humanoid_leggings/${matName}.png") {
            $script:passes += "equipment_leggings: $id"
        } else {
            $script:errors += "MISSING: textures/entity/equipment/humanoid_leggings/${matName}.png"
        }
    }

    # Rule 7: Tool tags
    if ($type -eq "tool") {
        $toolTypes = @()
        if ($id -match "sword") { $toolTypes += "swords" }
        if ($id -match "pickaxe") { $toolTypes += "pickaxes" }
        if ($id -match "_axe\b|^axe\b") { $toolTypes += "axes" }
        if ($id -match "shovel") { $toolTypes += "shovels" }
        if ($id -match "hoe") { $toolTypes += "hoes" }

        foreach ($tt in $toolTypes) {
            if (Test-AnyFileExists "modid:${id}") {
                # Check if in the right tag file
                $tagFile = "$ProjectDir/src/main/resources/data/minecraft/tags/item/${tt}.json"
                if (Test-Path $tagFile) {
                    $tagContent = Get-Content $tagFile -Raw
                    if ($tagContent -match [regex]::Escape("modid:${id}")) {
                        $script:passes += "tag_${tt}: $id"
                    } else {
                        $script:errors += "MISSING_TAG: $id not in ${tt}.json"
                    }
                } else {
                    $script:errors += "MISSING_TAG_FILE: data/minecraft/tags/item/${tt}.json"
                }
            }
        }
    }
}

function Check-Block($block) {
    $id = $block.name

    # Block texture
    if (Test-FileExists "assets/modid/textures/block/${id}.png") {
        $script:passes += "block_texture: $id"
    } else {
        $script:errors += "MISSING: assets/modid/textures/block/${id}.png"
    }

    # Block model
    if (Test-FileExists "assets/modid/models/block/${id}.json") {
        $script:passes += "block_model: $id"
    } else {
        $script:errors += "MISSING: assets/modid/models/block/${id}.json"
    }

    # Blockstate
    if (Test-FileExists "assets/modid/blockstates/${id}.json") {
        $script:passes += "blockstate: $id"
    } else {
        $script:errors += "MISSING: assets/modid/blockstates/${id}.json"
    }

    # Item model for block
    if (Test-FileExists "assets/modid/models/item/${id}.json") {
        $script:passes += "block_item_model: $id"
    } else {
        $script:errors += "MISSING: assets/modid/models/item/${id}.json"
    }

    # Recipe for block
    if (Test-AnyFileExists "modid:${id}") {
        $script:passes += "block_recipe: $id"
    } else {
        $script:warnings += "NO_RECIPE: block $id"
    }
}

function Check-Mixins {
    $mixins = Find-MixinClasses
    $configFiles = Get-ChildItem -Path $ProjectDir -Recurse -Filter "*.mixins.json" -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch "\\build\\" }

    foreach ($m in $mixins) {
        $found = $false
        foreach ($cf in $configFiles) {
            $content = Get-Content $cf.FullName -Raw
            if ($content -match [regex]::Escape($m.name)) {
                $found = $true
                $script:passes += "mixin_config: $($m.name)"
                break
            }
        }
        if (-not $found) {
            $script:errors += "MISSING_MIXIN: $($m.name) not in any .mixins.json"
        }
    }

    # Also check: fabric.mod.json references mixin config
    $fabricMod = "$ProjectDir/src/main/resources/fabric.mod.json"
    if (Test-Path $fabricMod) {
        $fmContent = Get-Content $fabricMod -Raw
        foreach ($cf in $configFiles) {
            $configName = $cf.Name
            if ($fmContent -notmatch [regex]::Escape($configName)) {
                $script:errors += "MISSING_FABRIC_MOD_MIXIN: $configName not referenced in fabric.mod.json"
            } else {
                $script:passes += "fabric_mod_mixin: $configName"
            }
        }
    }
}

# ============================================================
# Main
# ============================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " ModSmith Integrity Checker" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$items = Find-RegisteredItems
$blocks = Find-RegisteredBlocks

Write-Host "Found: $($items.Count) items, $($blocks.Count) blocks"
Write-Host ""

# Check items
foreach ($item in $items) {
    Check-Item $item
}

# Check blocks
foreach ($block in $blocks) {
    Check-Block $block
}

# Check mixins
Check-Mixins

# ============================================================
# Report
# ============================================================

Write-Host "--- RESULTS ---" -ForegroundColor Yellow
Write-Host ""

$errorCount = $errors.Count
$warnCount = $warnings.Count
$passCount = $passes.Count
$total = $errorCount + $warnCount + $passCount
$score = if ($total -gt 0) { [int]($passCount * 100 / $total) } else { 100 }

Write-Host "PASSES ($passCount):" -ForegroundColor Green
if ($passCount -gt 20) {
    Write-Host "  (${passCount} checks passed - all good)" -ForegroundColor Green
} else {
    foreach ($p in $passes) { Write-Host "  ✅ $p" -ForegroundColor Green }
}

Write-Host ""
Write-Host "WARNINGS ($warnCount):" -ForegroundColor Yellow
foreach ($w in $warnings) { Write-Host "  ⚠️  $w" -ForegroundColor Yellow }

Write-Host ""
Write-Host "FAILURES ($errorCount):" -ForegroundColor Red
foreach ($e in $errors) { Write-Host "  ❌ $e" -ForegroundColor Red }

Write-Host ""
Write-Host "========================================"
Write-Host " Score: $score% ($passCount/$total)" -ForegroundColor $(if ($score -ge 90) { "Green" } elseif ($score -ge 70) { "Yellow" } else { "Red" })
Write-Host "========================================"

# Return non-zero exit code if there are failures (for CI/CD)
if ($errorCount -gt 0) { exit 1 } else { exit 0 }
