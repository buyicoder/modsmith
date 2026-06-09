---
name: mc-mod-master
description: Use when the user wants to create a complete Minecraft mod, add a new feature to an existing mod, or describes a mod idea in natural language. Triggers on: "make a mod", "create a sword/armor/block/entity", "add a weapon", Minecraft modding requests, or `/mc-mod-master` command. This is the master orchestrator that decomposes complex mod requests into sub-tasks and dispatches them to specialized sub-skills.
---

# ModFactory — Master Skill

## Overview

The single entry point for all MC mod development. Decomposes natural language requests into atomic tasks, dispatches to specialized sub-skills in correct dependency order, and assembles the output into a complete, compilable mod project.

**REQUIRED SUB-SKILLS:** When dispatching, always use the appropriate sub-skill:
- `texture-generator` for textures
- `item-generator` for items/tools/weapons/armor
- `block-generator` for blocks
- `entity-design-expert` for polished custom mobs/bosses with reference assets, model adaptation, textures, animations, and runtime verification
- `entity-generator` for entities
- `blockbench-animator` for Blockbench entity animation clips
- `gameplay-generator` for gameplay systems

**REQUIRED KNOWLEDGE:** `fabric-mc-mod-development` skill for API patterns, mappings, and conventions.

## Workflow

```
User: "Create a legendary frost sword that freezes enemies"
                │
        ┌───────▼────────┐
        │ 1. Parse intent │
        │  - MC version   │
        │  - Item type     │
        │  - Features      │
        │  - Visual style  │
        └───────┬────────┘
                │
        ┌───────▼────────┐
        │ 2. Decompose    │
        │  Task A: texture │ → texture-generator
        │  Task B: item    │ → item-generator
        │  Task C: ability │ → item-generator (special)
        └───────┬────────┘
                │
        ┌───────▼────────┐
        │ 3. Execute      │
        │  Run each sub-  │
        │  skill in order │
        │  (texture FIRST)│
        └───────┬────────┘
                │
        ┌───────▼────────┐
        │ 4. Assemble     │
        │  Merge all files│
        │  into project   │
        │  Check integrity│
        └───────┬────────┘
                │
        ┌───────▼────────┐
        │ 5. Output       │
        │  File list      │
        │  Build command  │
        │  Test guide     │
        └────────────────┘
```

## Task Decomposition Rules

### Execution Order (MUST follow)
1. **Texture FIRST** — items reference textures, so textures must exist first
2. **Registration foundation** — ModItems.java / ModBlocks.java before items that use them
3. **JSON resources** — models, recipes, tags after Java code
4. **Creative inventory** — ItemGroupEvents after all items registered

### Version Detection
Check `gradle.properties` for `minecraft_version`. If not found, ask user.
- 1.21.2+: Use `RegistryKey` + `Items.register()` (NEW API)
- 1.21.1 and below: Use `Registry.register()` (OLD API)

### Mapping Detection
Check `build.gradle` for `mappings` field:
- `net.fabricmc:yarn` → **Yarn mappings** (use `net.minecraft.item.*`, `Identifier.of()`)
- `loom.officialMojangMappings()` → **Mojang mappings** (use `net.minecraft.world.item.*`, `ResourceLocation.fromNamespaceAndPath()`)

### Architecture Pattern Selection (from mod-analyzer knowledge)
Based on the user's request complexity, automatically select the right package structure:

```
Item count estimate:
  <10 items + no complex systems → FLAT (Trinkets pattern)
  10-30 items or 1-2 systems  → FEATURE-BASED (Farmer's Delight pattern)
  30+ items or 3+ systems     → CONTENT+FOUNDATION (Create pattern)

⚠️ DEFAULT: Feature-based (Farmer's Delight). 95% of mods fit here.
```

**FLAT pattern** (Trinkets — <10 items):
```
com/example/
├── ExampleMod.java       ← Registration + init in one class
├── ExampleModClient.java
└── CustomItem.java       ← Custom classes at root level
```

**FEATURE-BASED pattern** (Farmer's Delight — DEFAULT):
```
com/example/
├── ExampleMod.java
├── common/
│   ├── registry/         ← ModItems, ModBlocks, ModCreativeTabs
│   ├── item/             ← Custom item classes
│   ├── block/            ← Custom block classes
│   └── block/entity/     ← Block entity classes (if any)
└── client/
    └── ExampleModClient.java
```

**CONTENT+FOUNDATION pattern** (Create — large mods 100+ classes):
```
com/example/
├── AllBlocks.java        ← Root-level registrations
├── AllItems.java
├── content/              ← Feature modules
│   ├── magic/
│   ├── machines/
│   └── worldgen/
└── foundation/           ← Shared infrastructure
    ├── block/
    ├── item/
    └── networking/
```

**REQUIRED KNOWLEDGE:** See `mod-analyzer/knowledge/architecture-patterns.md` for the full decision tree and examples from Trinkets, Farmer's Delight, and Create.

## Dispatch Templates

When dispatching to sub-skills, ALWAYS pass the selected architecture pattern.

### Simple Item Request
```
"Add a ruby sword"
→ Architecture: auto-detect → flat (only 1 item added)
→ texture-generator: sword texture, ruby palette
→ item-generator: sword, ToolMaterial, recipe, creative tab [architecture=flat]
```

### Armor Set Request
```
"Add ruby armor"
→ Architecture: auto-detect → feature-based (5+ items)
→ texture-generator: helmet/chestplate/leggings/boots icons + equipment layers
→ item-generator: ArmorMaterial + 4 armor items + recipes + tags [architecture=feature-based]
```

### Complex Mod Request
```
"Make a magic mod with fire staff and ice sword"
→ Architecture: auto-detect → registry-logic-split (3+ systems)
→ texture-generator: staff + sword textures
→ item-generator: fire staff (spawns fireball on right-click) + ice sword (freeze effect) [architecture=registry-logic-split]
→ block-generator: (if any blocks needed) [architecture=registry-logic-split]
→ gameplay-generator: magic system if user wants mana/cooldown
```

**Architecture Context Format:** When dispatching, include `[architecture=<pattern>]` so sub-skills know WHERE to put generated code.

### Custom Entity with Animations
```
"Make a stone guardian mob with heavy walking and slam attack animations"
→ entity-design-expert: own full asset/code/runtime loop
  → entity-designer: blueprint + asset contract
  → official asset search/export: reference model, texture size, UV layout
  → theme retexture: same dimensions, same UV layout
  → model adaptation: Java geometry + entity dimensions
  → blockbench-animator: idle, walk, attack, hurt, death clips
  → entity-generator: entity logic + renderer + runtime animation bindings [architecture=<pattern>]
  → integrity-checker + build + runClient verification
```

## MCP Integration (v3.1)

ModFactory integrates with external MCP servers for enhanced accuracy. See `integration/mcp-ecosystem.md` for full setup.

### MCP-Aware Generation
**Before generating any code that references vanilla Minecraft classes, check if mcdev-mcp is available:**
```
mcdev-mcp tools:
  get_minecraft_source(className) → Exact method signatures
  search_minecraft_code(query)    → Find classes by name
  analyze_mixin(mixinCode)        → Validate before compile
```

**When MCPs are available:**
- ✅ Mixin: Verify method signatures with `get_minecraft_source` before writing
- ✅ API changes: Use `compare_versions` when upgrading between MC versions
- ✅ Documentation: Use mcmodding-mcp `search_fabric_docs` for official API refs

**When MCPs are unavailable:** Fall back to `fabric-mc-mod-development` skill + `auto-fix` error database.

## Phase 3: Closed-Loop Pipeline

After generating all code and resources, ModFactory runs the build→fix→rebuild loop:

```
1. GENERATE all code + resources
2. BUILD: gradlew build
   ├── SUCCESS → 5. OUTPUT complete project
   └── FAILED → 3. AUTO-FIX
3. AUTO-FIX: Parse errors → apply known fixes
4. REBUILD: gradlew build (go to step 2)
   (max 5 iterations, then escalate to user)
```

## Task Completeness Check (CRITICAL — before build)

**BEFORE proceeding to build, verify EVERY user-requested feature has generated files:**

```
User asked for: [list explicitly]
Generated:      [count generated files per feature]
⚠️  Missing:     [features with 0 generated files]
```

**If any feature has ZERO files → STOP. Return to generation step.**
**Do NOT proceed to integrity-check or build until all features covered.**

Example:
```
User: "thunder ore with worldgen"
Generated: items(2) blocks(1) recipes(2) worldgen(0) ← RED FLAG
→ worldgen missing! Go back to worldgen-generator.
```

## Output Checklist

After all sub-skills AND task completeness check pass, verify:
- [ ] All Java files compile-ready with correct imports
- [ ] All JSON files valid (models, recipes, blockstates, equipment)
- [ ] All PNG textures exist at correct paths
- [ ] `ModItems.initialize()` called in `ExampleMod.onInitialize()`
- [ ] Items added to creative inventory via `ItemGroupEvents`
- [ ] Recipes reference correct item IDs
- [ ] Tool tags created if items are tools
- [ ] Equipment JSON + both texture layers for armor
- [ ] `fabric.mod.json` entrypoints correct

## Context: What We've Built Before

The current project (`D:\MC\fabric-mod-dev`) contains a working reference implementation:
- MC 1.21.11, Yarn mappings, Fabric Loader 0.18.2
- 14 items (ruby material, apple food, lightning ruby, 5 tools, 4 armor pieces)
- 1 block (ruby_block) with recipes
- GearFactory engine at `forge_engine/` for texture generation
- All known pitfalls documented in `fabric-mc-mod-development` skill
