---
name: integrity-checker
description: Use when generating a complete mod to verify all files are consistent and nothing is missing. Triggers on: "check my mod", "verify completeness", "validate project", "is everything connected", "integrity check", or dispatched by mc-mod-master before the build step.
---

# Integrity Checker — Static Cross-Validation

## Overview

Scans the entire project and cross-validates that every registered item/block/entity/command has all its required companion files. Detects 14 types of "silent failures" that compile fine but break at runtime.

## How It Works

```
1. Parse all Java files → extract registrations
2. Scan all resource directories → list available files
3. Cross-reference:
   - Every registered item has: texture + model + recipe + creative tab
   - Every registered block has: Texture + model + blockstate + BlockItem
   - Every armor item has: Equipment JSON + 2 texture layers
   - Every spawn egg has: custom entity binding + item mapping + model + lang + creative tab
   - Every entity has: renderer + model layer + texture + lang + loot table (or explicit no-drop note)
   - Every tool has: Appropriate tag
   - Every Mixin class has: Entry in mixins.json
   - Every command has: register() call
4. Output: PASS list + FAIL list with fix instructions
5. For runtime-sensitive changes, require `runClient` verification after build
```

## Run

```bash
# Check everything
powershell -File scripts/integrity-check.ps1 -ProjectDir .

# Check specific module
powershell -File scripts/integrity-check.ps1 -ProjectDir . -Module items
```

## Check Rules

### Rule 1: Item → Texture + Model
```
REGISTERED in ModItems.java → MUST have:
  textures/item/<name>.png
  models/item/<name>.json
  items/<name>.json (1.21.4+)
```

### Rule 2: Item → Creative Tab
```
REGISTERED in ModItems.java → MUST appear in:
  ExampleMod.java (ItemGroupEvents)
  OR ModCreativeTabs.java
```

### Rule 3: Item → Recipe
```
REGISTERED in ModItems.java → SHOULD have:
  data/MODID/recipe/ that references this item
  (warning if absent — some items are creative-only)
```

### Rule 4: Block → BlockItem
```
REGISTERED in ModBlocks.java → MUST have:
  Corresponding BlockItem registration
  (in ModBlocks.java or ModItems.java)
```

### Rule 5: Block → Resources
```
REGISTERED in ModBlocks.java → MUST have:
  blockstates/<name>.json
  models/block/<name>.json
  models/item/<name>.json
  textures/block/<name>.png
```

### Rule 6: Armor → Equipment
```
REGISTERED as armor (EquipmentType.HELMET/CHESTPLATE/LEGGINGS/BOOTS) → MUST have:
  equipment/<name>.json
  textures/entity/equipment/humanoid/<name>.png
  textures/entity/equipment/humanoid_leggings/<name>.png
```

### Rule 7: Tool → Tag
```
REGISTERED as tool (sword/pickaxe/axe/shovel/hoe) → MUST have entry in:
  data/minecraft/tags/item/<tool_type>s.json
```

### Rule 8: Mixin → Config
```
CLASS annotated with @Mixin → MUST appear in:
  MODID.mixins.json "mixins" or "client" array
```

### Rule 9: Command → Registration
```
CLASS defines commands → MUST be called in:
  onInitialize() or onInitializeClient()
```

### Rule 10: Language → Key
```
REGISTERED item/block/entity → MUST have keys in:
  lang/en_us.json ("item.MODID.<name>", "block.MODID.<name>")
```

### Rule 11: Entity Runtime Closure
```
REGISTERED EntityType → MUST have:
  client renderer registration
  model layer registration
  textures/entity/<name>.png
  lang/en_us.json key: "entity.MODID.<name>"
  data/MODID/loot_table/entities/<name>.json
```

### Rule 12: Custom Spawn Egg Runtime Closure
```
REGISTERED spawn egg → MUST have:
  custom SpawnEggItem subclass for custom entities (1.21.11)
  assets/MODID/items/<name>_spawn_egg.json
  assets/MODID/models/item/<name>_spawn_egg.json
  lang item.MODID.<name>_spawn_egg
  creative tab entry
```

Never consider spawn eggs verified by `gradlew build` alone. They can compile and still crash in `runClient` during static registration.

### Rule 13: Entity Asset Contract
```
REGISTERED complex entity SHOULD have:
  models/<name>.contract.json
  texture dimensions matching contract.texture
  model TexturedModelData size matching contract.model
  renderer texture path matching contract.renderer
```

## Output Format

```
=== INTEGRITY REPORT ===
Project: fabric-mod-dev
Check time: 2026-06-09 14:00

PASSES (42):
  ✅ ruby_sword: texture + model + recipe + tab + tag
  ✅ ruby_block: texture + model + blockstate + blockitem + recipe
  ...

WARNINGS (3):
  ⚠️ lightning_ruby: no recipe (creative-only item, ok if intentional)
  ⚠️ ruby_apple: no food tag (optional)
  ...

FAILURES (5):
  ❌ ruby_helmet: missing humanoid_leggings texture
     Fix: create textures/entity/equipment/humanoid_leggings/ruby.png
  ❌ ruby_shovel: missing shovels tag
     Fix: add "modid:ruby_shovel" to data/minecraft/tags/item/shovels.json
  ...

Score: 42/50 (84%)
```

## Integration with Closed Loop

```
mc-mod-master generates code
    ↓
integrity-checker scans project      ← runs first
    ├── All PASS → proceed to build
    └── Some FAIL → auto-fix generates missing files
        → integrity-checker re-runs
        → All PASS → proceed to build
            → runtime-sensitive change? runClient gate
```
