---
name: texture-generator
description: Use when the user needs Minecraft item textures, block textures, armor model textures, or equipment icons. Triggers on: "generate texture", "create icon", "make armor look like", "need a texture for", or when dispatched by mc-mod-master for visual asset generation.
---

# Texture Generator

## Overview

Generates Minecraft-style pixel art textures for items, blocks, and armor using the GearFactory engine. Supports 20 color palettes and multiple shape templates. Outputs standard 16x16 item icons and 64x32 armor equipment textures.

## GearFactory Engine

Located at `forge_engine/` in the mod project. If not present, clone from https://github.com/buyicoder/GearFactory.

### Quick Generate
```powershell
cd forge_engine
.\forge.ps1 -PaletteName ruby -Shape vanilla
```

### Parameters
| Param | Values | Default |
|------|--------|---------|
| `-PaletteName` | ruby, sapphire, emerald, amethyst, topaz, obsidian, silver, rose_gold, coral, amber, jade, crimson, ocean, forest, inferno, frost, shadow, celestial, thunder, onyx | ruby |
| `-Shape` | vanilla, copper, aura, better_weapons, amethyst, fresh | vanilla |
| `-ItemName` | sword, pickaxe, axe, shovel, hoe, helmet, chestplate, leggings, boots, all | all |

### Palette Selection Guide
Match palette to user's description:
- "ruby/red/blood/fire" → ruby, crimson, inferno
- "ice/frost/water/ocean" → frost, ocean, sapphire
- "nature/forest/poison" → forest, emerald, jade
- "holy/lightning" → celestial, thunder
- "dark/shadow/void" → shadow, obsidian, onyx
- "royal/magic/purple" → amethyst
- "gold/luxury" → topaz, amber
- "metal/steel" → silver, obsidian

## Texture Generation Workflow

### Step 1: Determine Style
Extract from user description:
- Color theme → map to palette
- Shape style → map to Shape source
- "legendary/epic/glowing" → aura or better_weapons
- "simple/classic" → vanilla

### Step 2: Run Engine
```powershell
cd forge_engine
.\forge.ps1 -PaletteName <chosen> -Shape <chosen>
```

### Step 3: Verify Output
Check files exist:
```
output/<palette>/item/ruby_sword.png
output/<palette>/item/ruby_helmet.png
...
output/<palette>/equipment/humanoid/ruby.png
output/<palette>/equipment/humanoid_leggings/ruby.png
```

### Step 4: Copy to Project
Engine auto-copies to `src/main/resources/assets/modid/textures/`.

## Manual Texture Generation (No Engine)
If GearFactory engine is not available, create textures programmatically using PowerShell's System.Drawing. Each texture must be:
- Items: 16x16 PNG, transparent background
- Armor equipment: 64x32 PNG (humanoid and humanoid_leggings)
- Blocks: 16x16 PNG

Use 3-4 shades of the material color for depth (outline → shadow → base → light → highlight).
