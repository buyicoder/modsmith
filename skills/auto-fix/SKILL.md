---
name: auto-fix
description: Use when a Minecraft mod fails to compile, has build errors, or the user wants to automatically fix gradle compilation issues. Triggers on: "fix build errors", "compilation failed", "auto-fix my mod", "why won't my mod compile", or dispatched by mc-mod-master during closed-loop build.
---

# Auto-Fix — Compilation Error Repair

## Overview

Parses Gradle build output, maps errors to known fixes, applies corrections automatically, and rebuilds. Forms the "FIX" phase of the ModSmith closed-loop pipeline.

## Error Pattern Database

Each entry maps a Gradle error pattern to an automatic fix:

### Package Not Found
```
Pattern: "程序包net.minecraft.XXX不存在" or "package net.minecraft.XXX does not exist"
Root Cause: Wrong mappings (Yarn vs Mojang types)
Fix: Check build.gradle mappings field, correct import to use the right package
Auto: Replace imports based on mapping detection
```

### Symbol Not Found
```
Pattern: "找不到符号" or "cannot find symbol"
Root Cause: Wrong method name, missing import, or API change
Fix: Check fabric-mc-mod-development mappings table
Auto: Substitute correct method name from mapping reference
```

### Item.Factory Not Found
```
Pattern: "Item.Factory" + "找不到符号"
Fix: Replace Item.Factory with Function<Item.Settings, Item>
     (Yarn mappings don't have Item.Factory inner class)
```

### TypedActionResult → ActionResult
```
Pattern: "找不到符号 TypedActionResult"
Fix: Replace TypedActionResult<ItemStack> with ActionResult
     Replace TypedActionResult.success() with ActionResult.SUCCESS
     (TypedActionResult removed in 1.21 Yarn)
```

### isClient Private
```
Pattern: "isClient 在 World 中是 private 访问控制"
Fix: Replace world.isClient with world.isClient()
     (Yarn uses method, not field)
```

### SwordItem Removed (1.21)
```
Pattern: "找不到符号 SwordItem" / "SwordItem无法转换为Item"
Root Cause: SwordItem class removed in MC 1.21
Fix: Extend Item instead, apply .sword() on Item.Settings
     Constructor takes (Settings) not (ToolMaterial, float, float, Settings)
```

### postHit Return Type (1.21)
```
Pattern: "返回类型boolean与void不兼容" / "方法不会覆盖或实现超类型的方法"
Root Cause: Item.postHit() returns void in 1.21, only old SwordItem returned boolean
Fix: public void postHit(...) { ... } — no return value
```

### getWorld → getEntityWorld (Yarn)
```
Pattern: "找不到符号: 方法 getWorld()" on Entity/LivingEntity
Fix: Use getEntityWorld() instead (Yarn 1.21+)
     Or: getWorld() → getEntityWorld()
```

### BlockItem Translation Key
```
Pattern: Block has no translation in game
Root Cause: BlockItems use "item.modid.name" key, not "block.modid.name"
Fix: Add BOTH keys in lang file:
     "item.modid.thunder_ore": "Translation",
     "block.modid.thunder_ore": "Translation"
     (the blockstate/tooltip uses block., the held item uses item.)
```

### GearFactory Palette Overwrite
```
Pattern: Textures changed to wrong color after running forge.ps1
Root Cause: forge.ps1 writes to project by default (overwrites all textures)
Fix: forge.ps1 v1.2+ uses LIBRARY ONLY by default
     Use -Apply flag to explicitly write to project
     Check: forge.ps1 -PaletteName ruby -Apply

### Recipe JSON Parse Error
```
Pattern: "Couldn't parse data file" + "recipe"
Fix: Recipe key values in 1.21.2+ use plain strings, not objects
     Replace {"item": "modid:ruby"} with "modid:ruby"
```

### EquipmentAsset Namespace
```
Pattern: EquipmentAssetKeys.register("name") → armor not rendering
Fix: Use RegistryKey.of(EquipmentAssetKeys.REGISTRY_KEY, Identifier.of(MOD_ID, "name"))
     instead of EquipmentAssetKeys.register()
```

### Missing Texture Layer
```
Pattern: Armor worn but no 3D model visible
Fix: Ensure both textures exist:
     textures/entity/equipment/humanoid/<name>.png
     textures/entity/equipment/humanoid_leggings/<name>.png
```

### Mixin Target Not Found
```
Pattern: "InvalidInjectionException: could not find any targets"
Fix: The method name in @Inject changed in this MC version.
     Check the source jar for the correct Yarn/Mojang method name.
```

## Fix Pipeline

```
1. Parse error output → extract file, line, error type
2. Look up error in pattern database
3. If exact match → apply fix automatically
4. If partial match → suggest fix with confidence level
5. If no match → report for manual fix
6. Apply all fixes → rebuild → repeat until SUCCESS
```

## Auto-Fix Flow

```
BUILD FAILED
    │
    ├── Package errors → fix imports (mapping aware)
    ├── Method not found → substitute from mapping table
    ├── Recipe parse errors → fix JSON format
    ├── Mixin errors → suggest method name check
    └── Unknown errors → report to user
    │
    ▼
BUILD SUCCESSFUL ← confirmed fixed
```

## Known Fix Counters

| Error | Fix Attempts | Confidence |
|-------|-------------|------------|
| Package not found | 1 (remap imports) | 95% |
| Item.Factory | 1 (Function<Item.Settings,Item>) | 100% |
| TypedActionResult | 1 (ActionResult) | 100% |
| isClient private | 1 (isClient()) | 100% |
| Recipe JSON | 1 (string format) | 90% |
| EquipmentAsset namespace | 1 (RegistryKey.of) | 100% |
| Missing texture layer | 1 (create file) | 85% |
| Mixin method target | 2 (guess + verify) | 60% |
