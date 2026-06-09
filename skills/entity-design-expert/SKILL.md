---
name: entity-design-expert
description: Use when creating a polished custom Minecraft mob, boss, pet, or creature that needs official reference assets, Blockbench model work, themed retexturing, animation clips, Fabric code generation, spawn egg, loot, boss bar, or runtime verification.
---

# Entity Design Expert

## Overview

Own the complete entity production loop: concept -> official reference -> model/texture -> animation -> Fabric code/resources -> runtime verification. Use this as the orchestrator for high-quality mobs; delegate implementation details to existing ModFactory skills.

**Required sub-skills:** `entity-designer`, `blockbench-animator`, `entity-generator`, `integrity-checker`, `auto-fix`.

## Core Rule

Do not let model, texture, animation, and code drift apart.

Every entity must have a single source-of-truth asset contract:

```text
reference entity + texture size + UV layout + part names + animation names + entity dimensions
```

If any one changes, re-check all others before running the game.

For the complete contract schema, see `asset-contract-reference.md`.

## Workflow

### 1. Design the Entity Contract

Start with `entity-designer`. The blueprint must include:

- Vanilla reference entity or explicit custom shape.
- Texture size and UV layout, e.g. `64x64`, `128x128`, `128x64`.
- Exact runtime size: `EntityType.Builder.dimensions(width, height)`.
- Model part list: head, body, arms, legs, wings, tail, etc.
- Required clips: idle, walk, attack, hurt, death, special, spawn.
- Runtime features: spawn egg, boss bar, drops, biome spawning, summon method.

### 2. Find Official Reference Assets

Prefer official Minecraft assets when adapting a vanilla-shaped mob.

Search order:

1. Project `models/` and existing `.bbmodel` references.
2. Existing `src/main/resources/assets/<modid>/textures/entity/`.
3. Minecraft/client source or asset cache when available.
4. Blockbench model library or a user-provided `.bbmodel`.

When a `.bbmodel` has embedded textures, export the embedded texture directly instead of regenerating it:

```powershell
$json = Get-Content -Raw model.bbmodel | ConvertFrom-Json
$tex = $json.textures | Where-Object { $_.name -eq "entity_texture" } | Select-Object -First 1
$src = [string]$tex.source
if ($src -match ",") { $src = $src.Substring($src.IndexOf(",") + 1) }
[IO.File]::WriteAllBytes("src/main/resources/assets/modid/textures/entity/name.png",
  [Convert]::FromBase64String($src))
```

### 3. Theme Retexture Without Breaking UV

Never resize a texture to hide UV bugs. Retexture in the same dimensions and same UV layout as the model.

Good transformations:

- Brightness remap to a new palette.
- Hue shift while preserving alpha.
- Add emissive accents inside existing painted regions.
- Preserve transparent pixels and all image dimensions.

Bad transformations:

- `128x128` -> `64x64` to match a simplified model.
- Repainting from scratch without checking UV islands.
- Exporting a texture from one `.bbmodel` while using Java geometry from another.

### 4. Adapt Model Geometry to the Texture

Model geometry must match the texture's UV layout.

For vanilla-shaped entities:

- Use the official part proportions and UV offsets.
- Keep `TexturedModelData.of(data, textureWidth, textureHeight)` equal to the texture.
- Set `EntityType.Builder.dimensions(width, height)` to match the in-game body size.
- In Yarn 1.21.11 use `EntityModel<LivingEntityRenderState>`, `ModelTransform.origin`, and do not override `render()`.

When converting Blockbench coordinates:

- Compare total model height against the intended entity height.
- Verify head/body/limb origins support animation.
- If a model looks tiny, check both Java cuboid heights and entity dimensions.
- If a model has holes, check UV size/layout before changing the texture.

### 5. Generate Animations in Blockbench

Use `blockbench-animator` after the model is open.

Required verification:

- Call `list_outline` and use real part names.
- Create clips with stable names and record them in the blueprint.
- Loop only idle/walk/look clips.
- One-shot attack/hurt/death/spawn clips.
- Verify keyframe counts and clip lengths after writing.

For heavy golems:

- Walk: slow, weighty, opposite legs, small arm swing.
- Idle: minimal breathing and subtle head motion.
- Attack: anticipation -> impact -> recovery.
- Death: heavy collapse, no floaty bounce.

### 6. Generate Game Files

Use `entity-generator` only after the asset contract is stable.

Generate the full closure:

- `EntityType` registration and attributes.
- Entity AI/mechanics class.
- Spawn egg item using custom `ModSpawnEggItem` for custom entities.
- Client renderer and model layer registration.
- Entity model code from the agreed geometry.
- Texture at `textures/entity/<name>.png`.
- Lang keys for entity and spawn egg.
- Loot table or explicit no-drop decision.
- Creative tab entry.
- Optional boss bar, biome spawn rules, summon item, sounds, particles.

### 7. Verify Runtime, Not Just Build

Validation order:

1. `integrity-checker`: static resource closure.
2. `gradlew build`: compile/resources.
3. `gradlew runClient`: actual startup.
4. Spawn the entity in-game.
5. Verify appearance, scale, spawn egg, boss bar, loot, and animations.

If `build` passes but `runClient` fails, treat it as incomplete. Entity rendering and spawn eggs often fail only at runtime.

## ModFactory Dispatch Protocol

For a complex entity request:

```text
entity-design-expert
  -> entity-designer: complete blueprint and asset contract
  -> official asset search/export: reference model and texture source
  -> theme retexture: same dimensions, same UV
  -> model adaptation: Java geometry + texture size + entity dimensions
  -> blockbench-animator: animation clips
  -> entity-generator: Fabric code/resources
  -> integrity-checker: resource closure
  -> auto-fix: compile/runtime errors
  -> runClient: final verification
```

## Common Mistakes

| Symptom | Root Cause | Fix |
|---|---|---|
| Texture looks different from Blockbench | Game texture was regenerated instead of exported from `.bbmodel` | Export embedded Blockbench texture directly |
| Entity has transparent holes | Java model UV size/layout does not match texture | Match `TexturedModelData` size and UV offsets to source texture |
| Entity looks too small | Simplified Java cuboids or small entity dimensions | Match official/reference geometry and `dimensions()` |
| Spawn egg crashes on startup | `SpawnEggItem.forEntity(customType)` returned null | Use custom `ModSpawnEggItem` |
| Build passes but game crashes | Missing renderer/model layer/spawn egg runtime binding | Run `runClient` and fix runtime closure |
| Animations do not affect parts | Assumed bone names | Inspect Blockbench outline and bind real names |

## Acceptance Checklist

- [ ] Blueprint approved and complete.
- [ ] Official/reference asset source recorded.
- [ ] Texture dimensions match model texture size.
- [ ] Java model geometry matches reference proportions.
- [ ] Entity dimensions match intended in-game scale.
- [ ] Animation clip names recorded and verified.
- [ ] Spawn egg works for custom entity.
- [ ] Renderer, model layer, texture, lang, loot, creative tab all exist.
- [ ] `gradlew build` passes.
- [ ] `gradlew runClient` opens and entity is visually verified in-game.
