---
name: block-generator
description: Use when the user needs to create custom Minecraft blocks. Triggers on: "add a block", "create a custom block", "make an ore block", or dispatched by mc-mod-master.
---

# Block Generator

## Overview

Generates complete block registration, blockstate JSON, model JSON, BlockItem, and texture references for custom Minecraft blocks.

**REQUIRED CONTEXT:** `mod-analyzer/knowledge/architecture-patterns.md` for package structure decisions.

## Architecture-Aware Generation

| Architecture | Registration location | Block class location | BlockEntity location |
|-------------|----------------------|---------------------|---------------------|
| **flat** | `ExampleMod.java` | Same package | Same package |
| **feature-based** | `common/registry/ModBlocks.java` | `common/block/<Name>Block.java` | `common/block/entity/<Name>BlockEntity.java` |
| **registry-logic-split** | `reg/ModBlocks.java` (pure data) | `common/block/<Name>Block.java` | `common/block/entity/<Name>BlockEntity.java` |
| **content+foundation** | Root `AllBlocks.java` | `content/<module>/block/<Name>Block.java` | `content/<module>/block/entity/<Name>BlockEntity.java` |

**DEFAULT: feature-based (Farmer's Delight pattern).**

## Block Registration Template

```java
// ModBlocks.java
public static final Block RUBY_BLOCK = register("ruby_block", Block::new,
    AbstractBlock.Settings.create()
        .strength(5.0F, 6.0F)  // hardness, blast resistance
        .requiresTool()          // requires correct tool to drop
);

public static Block register(String path,
        Function<AbstractBlock.Settings, Block> factory,
        AbstractBlock.Settings settings) {
    RegistryKey<Block> blockKey = RegistryKey.of(
        RegistryKeys.BLOCK, Identifier.of(MOD_ID, path));
    Block block = Blocks.register(blockKey, factory, settings);
    // Auto-register BlockItem
    RegistryKey<Item> itemKey = RegistryKey.of(
        RegistryKeys.ITEM, Identifier.of(MOD_ID, path));
    Items.register(itemKey,
        s -> new BlockItem(block, s), new Item.Settings());
    return block;
}
```

## Block Settings Guide

| Method | Effect | Example |
|--------|--------|---------|
| `.strength(h, r)` | Hardness + blast resistance | `.strength(3.0F, 6.0F)` |
| `.requiresTool()` | Needs correct tool to drop | Always add for ore blocks |
| `.luminance(n)` | Light level | `.luminance(15)` |
| `.slipperiness(n)` | Ice-like slipperiness | `.slipperiness(0.98F)` |
| `.nonOpaque()` | Transparent rendering | Glass-like blocks |
| `.noCollision()` | Walk-through | Tall grass, torches |
| `.ticksRandomly()` | Random tick updates | Crops |

## Auto-Generated Files Per Block

| File | Path | Required |
|------|------|----------|
| ModBlocks.java entry | `src/main/java/.../ModBlocks.java` | Always |
| Blockstate JSON | `assets/MODID/blockstates/<name>.json` | Always |
| Block model JSON | `assets/MODID/models/block/<name>.json` | Always |
| Item model JSON | `assets/MODID/models/item/<name>.json` | Always |
| Item mapping JSON | `assets/MODID/items/<name>.json` | 1.21.4+ |
| Block texture PNG | `assets/MODID/textures/block/<name>.png` | Always |
| Recipe JSON | `data/MODID/recipe/<name>.json` | Optional |
| Loot table JSON | `data/MODID/loot_table/blocks/<name>.json` | Optional |

## Blockstate Template
```json
{
  "variants": {
    "": { "model": "MODID:block/<name>" }
  }
}
```

## Block Model Template (full cube)
```json
{
  "parent": "minecraft:block/cube_all",
  "textures": {
    "all": "MODID:block/<name>"
  }
}
```
