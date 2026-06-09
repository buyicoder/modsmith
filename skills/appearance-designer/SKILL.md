---
name: appearance-designer
description: Use when generating equipment textures and need to decide what vanilla shape to use as the base template. Triggers on: "design appearance", "what texture template", "which base shape", "generate texture for new item", or dispatched by mc-mod-master BEFORE texture-generator.
---

# Appearance Designer — Shape-to-Template Decision Engine

## Overview

Determines the correct vanilla template for any item based on its name and description. Prevents nonsensical mappings like "shard → diamond gem" or "ore → stone block".

## Core Rules

```
1. Classify item by name → pick template category
2. If obvious match → generate via GearFactory (recolor)
3. If ambiguous → PRESENT OPTIONS TO USER, wait for confirmation
4. If no match → use texture-ai-generator (new shape)
5. NEVER silently map a non-matching shape
```

## Shape-to-Template Mapping

### Tools (standard shapes)
| Item Name Contains | Template | Notes |
|-------------------|----------|-------|
| `sword`, `blade`, `katana`, `rapier` | `diamond_sword` | All swords share the blade+handle silhouette |
| `pickaxe`, `pick` | `diamond_pickaxe` | |
| `axe`, `hatchet`, `chopper` | `diamond_axe` | |
| `shovel`, `spade`, `scoop` | `diamond_shovel` | |
| `hoe`, `scythe` | `diamond_hoe` | Scythe may need custom shape → ASK |

### Armor
| Item Name Contains | Template |
|-------------------|----------|
| `helmet`, `helm`, `crown`, `cap` | `diamond_helmet` |
| `chestplate`, `chest`, `plate`, `breastplate` | `diamond_chestplate` |
| `leggings`, `legs`, `pants`, `greaves` | `diamond_leggings` |
| `boots`, `boot`, `shoes`, `greaves` | `diamond_boots` |

### Materials (inventory items — the tricky ones!)
| Item Name Contains | Template | Reason |
|-------------------|----------|--------|
| `gem`, `crystal`, `jewel`, `diamond`, `ruby`, `sapphire` | `diamond` (vanilla gem shape) | Polished, faceted appearance |
| `shard`, `fragment`, `splinter`, `piece` | ⚠️ **ASK** → `flint` or `prismarine_shard` | Irregular broken edge shape |
| `ingot`, `bar` | `iron_ingot` or `gold_ingot` | Smooth rectangular bar |
| `dust`, `powder` | `gunpowder` or `glowstone_dust` | Pile of particles |
| `nugget`, `chunk` | `iron_nugget` or `gold_nugget` | Small lump |
| `orb`, `sphere`, `ball`, `pearl` | `ender_pearl` or `slime_ball` | Round object |
| `rod`, `stick`, `staff` | `blaze_rod` or `stick` | Long thin cylinder |
| `plate`, `sheet` | `paper` or `iron_ingot` (rotated?) | Flat rectangle |
| `core`, `heart` | `nether_star` or custom | Special shape |

### Blocks
| Item Name Contains | Template | Reason |
|-------------------|----------|--------|
| `ore` | `diamond_ore` or `emerald_ore` | Stone with colored specks |
| `block` (storage) | `diamond_block` | Solid colored block |
| `bricks` | `stone_bricks` | Brick pattern |
| `log`, `wood` | `oak_log` | Wood grain |
| `planks` | `oak_planks` | Wood planks |
| `lamp`, `light` | `glowstone` or `redstone_lamp` | Light-emitting |
| `glass` | `glass` | Transparent |

### "NO MATCH" Category
If the item name doesn't match any category → **STOP. ASK USER.**
Never silently map to a random template.

## Decision Flow

```
Item: "thunder_shard"
    │
    ▼
Name contains "shard" → Category: Materials/Shard
    │
    ▼
Template candidates: [flint, prismarine_shard, custom AI]
    │
    ▼
⚠️ AMBIGUOUS → ASK USER:
  "Thunder Shard 的纹理形状，你偏好哪个方向？
   A: 燧石形状（尖锐不规则碎块） ← 推荐
   B: 海晶碎片形状（三角形薄片）
   C: 自己描述形状，我用 AI 生成"
    │
    ▼
User selects A → Extract flint.png from vanilla → Recolor to topaz
User selects B → Extract prismarine_shard.png → Recolor to topaz
User selects C → Dispatch texture-ai-generator
```

## Real Examples

```
✅ "thunder_ore" → "ore" → diamond_ore → topaz recolor (AUTO, no ask)
✅ "thunder_sword" → "sword" → diamond_sword → topaz recolor (AUTO, no ask)
⚠️ "thunder_shard" → "shard" → AMBIGUOUS → ASK USER
✅ "ruby_helmet" → "helmet" → diamond_helmet → ruby recolor (AUTO)
✅ "frost_staff" → "staff" → AMBIGUOUS → ASK: "blaze_rod shape or custom?"
⚠️ "shadow_scythe" → "scythe" → AMBIGUOUS → ASK: "diamond_hoe as base or custom?"
```

## Integration with GearFactory

When the template is decided, extract it from vanilla Minecraft if not already in the template library:

```bash
# Extract template from vanilla
unzip -o "$GRADLE_CACHE/minecraft-client-only.jar" \
    "assets/minecraft/textures/item/$TEMPLATE.png"

# Feed to GearFactory
forge.ps1 -Template $TEMPLATE -PaletteName $CHOSEN_PALETTE -OutputName $ITEM_NAME -Apply
```

## Template Library

All extracted vanilla templates are cached in `templates/vanilla-library/` for reuse.
