# ModFactory Entity Pipeline Tools Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the current skill-guided custom entity workflow into a tool-backed pipeline that exports Blockbench assets, records an entity asset contract, validates model/texture/code alignment, and produces repeatable QA evidence.

**Architecture:** Add small PowerShell tools under `scripts/` and reusable helpers under `scripts/lib/`. Keep skills as orchestration documentation, but move fragile checks into executable validators. The first version targets Fabric/Yarn entity assets and Blockbench `.bbmodel` files, with no external dependencies beyond PowerShell and Gradle.

**Tech Stack:** PowerShell 5+/7, JSON, PNG byte inspection via .NET `System.Drawing`, Fabric project file conventions, existing ModFactory skills.

---

## File Structure

Create:

- `scripts/lib/ModFactory.Path.ps1`: shared path, JSON, and UTF-8 helpers.
- `scripts/lib/EntityContract.ps1`: read/write/validate entity contract objects.
- `scripts/export-bbmodel-assets.ps1`: export embedded textures and metadata from `.bbmodel`.
- `scripts/validate-entity-assets.ps1`: validate contract, texture dimensions, renderer/model/resource closure.
- `scripts/qa-runclient-check.ps1`: summarize `runClient` logs against startup/registration/resource criteria.
- `tests/fixtures/entity/dark_iron_golem.bbmodel.json`: minimal `.bbmodel` fixture with embedded 1x1 PNG.
- `tests/fixtures/entity/entity.contract.json`: expected contract fixture.
- `docs/entity-pipeline.md`: user-facing entity pipeline docs.
- `skills/entity-design-expert/asset-contract-reference.md`: skill reference for contract fields.

Modify:

- `scripts/integrity-check.ps1`: call the entity validator when contracts exist.
- `skills/entity-design-expert/SKILL.md`: link to the contract reference and scripts.
- `skills/mc-mod-master/SKILL.md`: mention tool-backed pipeline gates.
- `README.md`: update ModFactory architecture to include asset contract and validator tools.

## Contract Shape

Every generated entity should eventually produce:

```json
{
  "schemaVersion": 1,
  "entityId": "modid:dark_iron_golem",
  "displayName": "Dark Iron Golem",
  "reference": {
    "source": "minecraft:iron_golem",
    "bbmodelPath": "models/iron_golem_official.bbmodel"
  },
  "texture": {
    "path": "src/main/resources/assets/modid/textures/entity/dark_iron_golem.png",
    "width": 128,
    "height": 128,
    "source": "embedded-bbmodel"
  },
  "model": {
    "javaPath": "src/client/java/com/example/client/model/DarkIronGolemEntityModel.java",
    "textureWidth": 128,
    "textureHeight": 128,
    "parts": ["head", "body", "right_arm", "left_arm", "right_leg", "left_leg"]
  },
  "renderer": {
    "javaPath": "src/client/java/com/example/client/renderer/DarkIronGolemEntityRenderer.java",
    "textureIdentifier": "modid:textures/entity/dark_iron_golem.png"
  },
  "runtime": {
    "entityTypeField": "DARK_IRON_GOLEM",
    "dimensions": { "width": 1.4, "height": 2.9 },
    "spawnEgg": "modid:dark_iron_golem_spawn_egg",
    "bossBar": true
  },
  "animations": ["idle", "walk", "attack_slam", "hurt", "death_collapse"]
}
```

## Task 1: Add Shared PowerShell Helpers

**Files:**
- Create: `scripts/lib/ModFactory.Path.ps1`

- [ ] **Step 1: Add helper module**

Create `scripts/lib/ModFactory.Path.ps1`:

```powershell
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
```

- [ ] **Step 2: Run syntax check**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command ". .\scripts\lib\ModFactory.Path.ps1; 'OK'"
```

Expected:

```text
OK
```

- [ ] **Step 3: Commit**

```bash
git add scripts/lib/ModFactory.Path.ps1
git commit -m "Add ModFactory PowerShell path helpers"
```

## Task 2: Add Entity Contract Module

**Files:**
- Create: `scripts/lib/EntityContract.ps1`
- Create: `tests/fixtures/entity/entity.contract.json`

- [ ] **Step 1: Add fixture contract**

Create `tests/fixtures/entity/entity.contract.json`:

```json
{
  "schemaVersion": 1,
  "entityId": "modid:dark_iron_golem",
  "displayName": "Dark Iron Golem",
  "reference": {
    "source": "minecraft:iron_golem",
    "bbmodelPath": "models/iron_golem_official.bbmodel"
  },
  "texture": {
    "path": "src/main/resources/assets/modid/textures/entity/dark_iron_golem.png",
    "width": 128,
    "height": 128,
    "source": "embedded-bbmodel"
  },
  "model": {
    "javaPath": "src/client/java/com/example/client/model/DarkIronGolemEntityModel.java",
    "textureWidth": 128,
    "textureHeight": 128,
    "parts": ["head", "body", "right_arm", "left_arm", "right_leg", "left_leg"]
  },
  "renderer": {
    "javaPath": "src/client/java/com/example/client/renderer/DarkIronGolemEntityRenderer.java",
    "textureIdentifier": "modid:textures/entity/dark_iron_golem.png"
  },
  "runtime": {
    "entityTypeField": "DARK_IRON_GOLEM",
    "dimensions": { "width": 1.4, "height": 2.9 },
    "spawnEgg": "modid:dark_iron_golem_spawn_egg",
    "bossBar": true
  },
  "animations": ["idle", "walk", "attack_slam", "hurt", "death_collapse"]
}
```

- [ ] **Step 2: Add contract module**

Create `scripts/lib/EntityContract.ps1`:

```powershell
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
    return $errors
}
```

- [ ] **Step 3: Verify fixture contract**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command ". .\scripts\lib\EntityContract.ps1; `$c=Read-EntityContract tests\fixtures\entity\entity.contract.json; `$e=Test-EntityContractShape `$c; if(`$e.Count){`$e; exit 1}else{'OK'}"
```

Expected:

```text
OK
```

- [ ] **Step 4: Commit**

```bash
git add scripts/lib/EntityContract.ps1 tests/fixtures/entity/entity.contract.json
git commit -m "Add entity asset contract helpers"
```

## Task 3: Add Blockbench Asset Exporter

**Files:**
- Create: `scripts/export-bbmodel-assets.ps1`
- Create: `tests/fixtures/entity/dark_iron_golem.bbmodel.json`

- [ ] **Step 1: Add minimal `.bbmodel` fixture**

Create `tests/fixtures/entity/dark_iron_golem.bbmodel.json`:

```json
{
  "meta": { "format_version": "5.0", "model_format": "bedrock" },
  "name": "dark_iron_golem",
  "resolution": { "width": 128, "height": 128 },
  "textures": [
    {
      "name": "dark_iron_golem",
      "id": "0",
      "width": 1,
      "height": 1,
      "source": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGOSHzRgAAAAABJRU5ErkJggg=="
    }
  ],
  "elements": [
    { "name": "head", "type": "cube", "from": [-4, 33, -7.5], "to": [4, 43, 0.5], "uv_offset": [0, 0] },
    { "name": "body", "type": "cube", "from": [-9, 21, -6], "to": [9, 33, 5], "uv_offset": [0, 40] }
  ],
  "animations": [
    { "name": "idle", "length": 2.0, "loop": true },
    { "name": "walk", "length": 1.2, "loop": true }
  ]
}
```

- [ ] **Step 2: Add exporter script**

Create `scripts/export-bbmodel-assets.ps1`:

```powershell
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
```

- [ ] **Step 3: Test exporter with fixture**

Run:

```powershell
New-Item -ItemType Directory -Force .tmp\entity-export | Out-Null
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\export-bbmodel-assets.ps1 -BbmodelPath tests\fixtures\entity\dark_iron_golem.bbmodel.json -ProjectDir .tmp\entity-export -EntityName dark_iron_golem -ModId modid
```

Expected:

```text
EXPORTED texture=src/main/resources/assets/modid/textures/entity/dark_iron_golem.png contract=models/dark_iron_golem.contract.json parts=2 animations=2
```

- [ ] **Step 4: Verify output files exist**

Run:

```powershell
Test-Path .tmp\entity-export\src\main\resources\assets\modid\textures\entity\dark_iron_golem.png
Test-Path .tmp\entity-export\models\dark_iron_golem.contract.json
```

Expected:

```text
True
True
```

- [ ] **Step 5: Commit**

```bash
git add scripts/export-bbmodel-assets.ps1 tests/fixtures/entity/dark_iron_golem.bbmodel.json
git commit -m "Add Blockbench asset exporter"
```

## Task 4: Add Entity Asset Validator

**Files:**
- Create: `scripts/validate-entity-assets.ps1`

- [ ] **Step 1: Add validator script**

Create `scripts/validate-entity-assets.ps1`:

```powershell
param(
    [Parameter(Mandatory=$true)][string]$ProjectDir,
    [Parameter(Mandatory=$true)][string]$ContractPath
)

Set-StrictMode -Version Latest
. "$PSScriptRoot\lib\EntityContract.ps1"

$errors = @()
$warnings = @()
$contract = Read-EntityContract -Path $ContractPath
$errors += Test-EntityContractShape -Contract $contract

function Add-FileCheck {
    param([string]$Label, [string]$RelativePath)
    if (-not $RelativePath) {
        $script:warnings += "SKIP $Label: no path in contract"
        return
    }
    $full = Resolve-ModFactoryPath -ProjectDir $ProjectDir -RelativePath $RelativePath
    if (-not (Test-Path $full)) {
        $script:errors += "MISSING $Label: $RelativePath"
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
```

- [ ] **Step 2: Test validator against exported fixture**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\validate-entity-assets.ps1 -ProjectDir .tmp\entity-export -ContractPath .tmp\entity-export\models\dark_iron_golem.contract.json
```

Expected for the fixture:

```text
=== ENTITY ASSET VALIDATION ===
WARNINGS:
  SKIP model: no path in contract
  SKIP renderer: no path in contract
PASS
```

- [ ] **Step 3: Commit**

```bash
git add scripts/validate-entity-assets.ps1
git commit -m "Add entity asset validator"
```

## Task 5: Integrate Entity Validator into Integrity Check

**Files:**
- Modify: `scripts/integrity-check.ps1`
- Modify: `skills/integrity-checker/SKILL.md`

- [ ] **Step 1: Add contract scan to `scripts/integrity-check.ps1`**

Add this near the end, before final score output:

```powershell
function Check-EntityContracts {
    $contracts = Get-ChildItem -Path $ProjectDir -Recurse -Filter "*.contract.json" -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch "\\build\\" }
    foreach ($contract in $contracts) {
        $validator = Join-Path $PSScriptRoot "validate-entity-assets.ps1"
        if (Test-Path $validator) {
            & powershell -NoProfile -ExecutionPolicy Bypass -File $validator -ProjectDir $ProjectDir -ContractPath $contract.FullName
            if ($LASTEXITCODE -eq 0) {
                $script:passes += "entity-contract: $($contract.Name)"
            } else {
                $script:errors += "ENTITY_CONTRACT_FAILED: $($contract.FullName)"
            }
        }
    }
}

Check-EntityContracts
```

- [ ] **Step 2: Update skill docs**

In `skills/integrity-checker/SKILL.md`, add a rule after Rule 12:

```markdown
### Rule 13: Entity Asset Contract
```
REGISTERED complex entity SHOULD have:
  models/<name>.contract.json
  texture dimensions matching contract.texture
  model TexturedModelData size matching contract.model
  renderer texture path matching contract.renderer
```
```

- [ ] **Step 3: Run integrity checker on fixture temp project**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\integrity-check.ps1 -ProjectDir .tmp\entity-export
```

Expected:

```text
entity-contract: dark_iron_golem.contract.json
```

The command may also report missing normal mod files in the temp fixture; that is acceptable as long as the entity contract check runs.

- [ ] **Step 4: Commit**

```bash
git add scripts/integrity-check.ps1 skills/integrity-checker/SKILL.md
git commit -m "Integrate entity contracts into integrity checks"
```

## Task 6: Add `runClient` QA Log Summarizer

**Files:**
- Create: `scripts/qa-runclient-check.ps1`

- [ ] **Step 1: Add log checker**

Create `scripts/qa-runclient-check.ps1`:

```powershell
param([Parameter(Mandatory=$true)][string]$LogPath)

Set-StrictMode -Version Latest
$text = [System.IO.File]::ReadAllText($LogPath)
$checks = @(
    @{ name = "minecraft-loaded"; pattern = "Loading Minecraft"; required = $true },
    @{ name = "mod-loaded"; pattern = "modid"; required = $true },
    @{ name = "resource-reload"; pattern = "Reloading ResourceManager"; required = $true },
    @{ name = "entered-world"; pattern = "logged in with entity id|joined the game|加入了游戏"; required = $false },
    @{ name = "no-exception"; pattern = "Exception|ERROR|BUILD FAILED"; required = $true; inverse = $true }
)

$failed = @()
foreach ($check in $checks) {
    $matched = $text -match $check.pattern
    if ($check.inverse) { $matched = -not $matched }
    if ($check.required -and -not $matched) {
        $failed += $check.name
    }
    Write-Host "$($check.name): $matched"
}

if ($failed.Count) {
    Write-Host "FAILURES: $($failed -join ', ')"
    exit 1
}

Write-Host "PASS"
```

- [ ] **Step 2: Test on a real terminal log**

Run after a `runClient` session:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\qa-runclient-check.ps1 -LogPath C:\Users\Lenovo\.cursor\projects\d-MC\terminals\<terminal-id>.txt
```

Expected:

```text
minecraft-loaded: True
mod-loaded: True
resource-reload: True
no-exception: True
PASS
```

- [ ] **Step 3: Commit**

```bash
git add scripts/qa-runclient-check.ps1
git commit -m "Add runClient QA log checker"
```

## Task 7: Document Asset Contract for Skills

**Files:**
- Create: `skills/entity-design-expert/asset-contract-reference.md`
- Modify: `skills/entity-design-expert/SKILL.md`

- [ ] **Step 1: Add reference document**

Create `skills/entity-design-expert/asset-contract-reference.md`:

```markdown
# Entity Asset Contract Reference

The entity asset contract is the source of truth between Blockbench assets and Fabric runtime code.

## Required Fields

- `schemaVersion`: currently `1`.
- `entityId`: full namespaced id, e.g. `modid:dark_iron_golem`.
- `reference.source`: vanilla or user reference.
- `texture.path`: Fabric resource path to PNG.
- `texture.width` and `texture.height`: actual PNG dimensions.
- `model.javaPath`: client model Java file.
- `model.textureWidth` and `model.textureHeight`: values passed to `TexturedModelData.of`.
- `model.parts`: expected model part names.
- `renderer.javaPath`: renderer file.
- `renderer.textureIdentifier`: identifier returned by renderer.
- `runtime.entityTypeField`: registry field name.
- `runtime.dimensions`: `EntityType.Builder.dimensions(width, height)`.
- `runtime.spawnEgg`: spawn egg id.
- `animations`: stable clip names generated in Blockbench.

## Invariant

The PNG dimensions, Java model texture dimensions, and Blockbench resolution must match.
```

- [ ] **Step 2: Link reference from skill**

In `skills/entity-design-expert/SKILL.md`, add under "Core Rule":

```markdown
For the complete contract schema, see `asset-contract-reference.md`.
```

- [ ] **Step 3: Commit**

```bash
git add skills/entity-design-expert/SKILL.md skills/entity-design-expert/asset-contract-reference.md
git commit -m "Document entity asset contracts"
```

## Task 8: Update README and Pipeline Documentation

**Files:**
- Create: `docs/entity-pipeline.md`
- Modify: `README.md`

- [ ] **Step 1: Add user-facing pipeline docs**

Create `docs/entity-pipeline.md`:

```markdown
# ModFactory Entity Pipeline

The entity pipeline turns a mob idea into verified Fabric files.

## Flow

1. Design blueprint with `entity-design-expert`.
2. Export official or Blockbench reference assets.
3. Write `models/<entity>.contract.json`.
4. Retheme texture without changing UV dimensions.
5. Adapt Java model and renderer.
6. Generate entity code, spawn egg, loot, lang, and resources.
7. Run `scripts/integrity-check.ps1`.
8. Run `gradlew build`.
9. Run `gradlew runClient`.
10. Verify the entity in-game.

## Commands

```powershell
powershell -File scripts\export-bbmodel-assets.ps1 -BbmodelPath models\iron_golem_official.bbmodel -ProjectDir . -EntityName dark_iron_golem -ModId modid
powershell -File scripts\validate-entity-assets.ps1 -ProjectDir . -ContractPath models\dark_iron_golem.contract.json
powershell -File scripts\integrity-check.ps1 -ProjectDir .
```
```

- [ ] **Step 2: Update README**

Add this section to `README.md` after Architecture:

```markdown
## Entity Pipeline

ModFactory can run a closed-loop entity pipeline:

```text
idea -> blueprint -> Blockbench assets -> asset contract -> Fabric code -> integrity check -> build -> runClient QA
```

See `docs/entity-pipeline.md`.
```

- [ ] **Step 3: Commit**

```bash
git add README.md docs/entity-pipeline.md
git commit -m "Document the entity pipeline"
```

## Task 9: Final Verification and Push

**Files:**
- No new files unless previous tasks reveal documentation gaps.

- [ ] **Step 1: Run script syntax checks**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command ". .\scripts\lib\ModFactory.Path.ps1; . .\scripts\lib\EntityContract.ps1; 'OK'"
```

Expected:

```text
OK
```

- [ ] **Step 2: Run exporter and validator smoke test**

Run:

```powershell
Remove-Item -Recurse -Force .tmp\entity-export -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force .tmp\entity-export | Out-Null
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\export-bbmodel-assets.ps1 -BbmodelPath tests\fixtures\entity\dark_iron_golem.bbmodel.json -ProjectDir .tmp\entity-export -EntityName dark_iron_golem -ModId modid
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\validate-entity-assets.ps1 -ProjectDir .tmp\entity-export -ContractPath .tmp\entity-export\models\dark_iron_golem.contract.json
```

Expected:

```text
EXPORTED ...
PASS
```

- [ ] **Step 3: Check stale branding and mojibake**

Run:

```bash
rg "[Mm]od[Ss]mith" .
```

Expected: no results, except intentional historical notes if added later. Also scan manually for mojibake if a Windows shell rewrites UTF-8 files during implementation.

- [ ] **Step 4: Review git diff**

Run:

```bash
git status --short
git log --oneline -10
```

Expected: working tree clean except planned commits.

- [ ] **Step 5: Push**

Run:

```bash
git push origin main
```

Expected:

```text
main -> main
```

## Scope Not Included in This Plan

- Automatic Java model generation from arbitrary Blockbench geometry.
- Visual screenshot comparison.
- Browser-based QA.
- GitHub Actions integration.
- Full CLI command router like `modfactory entity import`.

Those should be separate plans after the asset contract/export/validator foundation is stable.

## Self-Review

- Spec coverage: The plan covers asset contracts, `.bbmodel` export, themed texture safety, model/texture validation, `runClient` QA, skill docs, and README docs.
- Placeholder scan: No task uses "TBD" or "implement later"; each task has concrete files and commands.
- Type consistency: The contract fields used by exporter and validator match the schema shown at the top.
- Risk: PowerShell JSON and image handling are Windows-friendly, but `System.Drawing` may need replacement later for non-Windows CI.
