# MC Mod Architecture Patterns — Analysis Summary

## Three Patterns, Three Mod Sizes

| | Trinkets (Small) | Farmer's Delight (Medium) | Supplementaries (Large) | Create (Very Large) | Tinkers (Very Large) |
|---|---|---|---|---|---|---|
| **Classes** | ~15 | ~100 | ~150 | ~200+ | ~300+ |
| **Package Strategy** | Flat | Feature-based + registry/ | Registry-logic separated | Content modules + foundation | Self-contained modules + library |
| **Registration** | In main mod class | `registry/ModXxx.java` (24 files) | `reg/ModXxx.java` (22 files, pure data) | Root `AllXxx.java` (30+ files) | Per-module registration |
| **When to Use** | <20 classes | 20-100 classes | 100-200 classes | 200-300 classes | 300+ classes |

## Pattern Decision Tree

```
How many classes will your mod have?
│
├── <20 → FLAT PATTERN (Trinkets)
│         Everything in one package
│         Registration in main mod class
│
├── 20-100 → FEATURE-BASED (Farmer's Delight)
│            common/registry/ for all ModXxx.java
│            common/item/ for custom item classes
│            common/block/ for custom block classes
│            common/block/entity/ for block entities
│            ⭐ DEFAULT for most mods
│
├── 100-200 → REGISTRY-LOGIC SPLIT (Supplementaries)
│             reg/ for ALL registrations (pure data, no logic)
│             common/ for ALL game logic (by feature)
│             Cleanest separation of concerns
│
├── 200-300 → CONTENT+FOUNDATION (Create)
│             content/<feature>/ for feature modules
│             foundation/ for shared infrastructure
│             AllXxx.java at root for registrations
│
└── 300+ → SELF-CONTAINED MODULES (Tinkers Construct)
           tools/ smeltery/ gadgets/ — each a mini-mod
           library/ for shared framework
           Per-module internal structure (item/,client/,network/,...)
```

## Key Pattern: Registry-Logic Separation (Supplementaries)

```
reg/          ← PURE DATA — only register(), no game logic
common/       ← PURE LOGIC — references reg/, never calls register()
├── block/    ← Block classes
├── items/    ← Item classes
├── events/   ← Event handlers
├── network/  ← Network packets
└── worldgen/ ← World generation
```

This is the cleanest pattern for medium-large mods. Registration is declarative, logic is operational.

## Key Pattern: Self-Contained Module (Tinkers Construct)

```
tools/              ← Complete tool system (= mini-mod)
├── item/           ← Tool item classes
├── modifiers/      ← Tool modifier behaviors
├── stats/          ← Tool stat calculation
├── recipe/         ← Tool crafting recipes
├── menu/           ← Tool GUI screens
├── network/        ← Tool network sync
├── client/         ← Tool rendering
├── data/           ← Tool data generation
└── logic/          ← Tool gameplay logic

smeltery/           ← Another self-contained mini-mod
gadgets/            ← Another...
```

Each module has its OWN internal structure. Modules share code via `library/`. Modules do NOT depend on each other.

## Registration Strategy Decision

| Strategy | Example | Best For |
|----------|---------|----------|
| **In main class** | Trinkets | <10 items/blocks |
| **registry/ subpackage** | Farmer's Delight | 10-50 items |
| **Root All*.java** | Create | 50+ items across modules |

## What ModFactory Should Generate

Based on the user's description, ModFactory should:

1. **Auto-detect mod size** from the user's request:
   - "Add a sword" → small → flat pattern
   - "Add a full equipment set with magic system" → medium → feature-based
   - "Make a complete tech mod with machines and power" → large → content+foundation

2. **Generate the right structure** automatically

3. **Default to Farmer's Delight pattern** (best fit for most mods—not too simple, not too complex)
