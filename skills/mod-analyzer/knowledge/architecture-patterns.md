# MC Mod Architecture Patterns — Analysis Summary

## Three Patterns, Three Mod Sizes

| | Trinkets (Small) | Farmer's Delight (Medium) | Create (Large) |
|---|---|---|---|
| **Classes** | ~15 | ~100 | ~200+ |
| **Package Strategy** | Flat | Feature-based + registry/ | Content modules + foundation |
| **Registration** | In main mod class | `registry/ModXxx.java` (24 files) | Root `AllXxx.java` (30+ files) |
| **When to Use** | <20 classes | 20-100 classes | 100+ classes |

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
│
└── 100+ → CONTENT+FOUNDATION (Create)
           content/<feature>/ for feature modules
           foundation/ for shared infrastructure
           AllXxx.java at root for registrations
```

## Registration Strategy Decision

| Strategy | Example | Best For |
|----------|---------|----------|
| **In main class** | Trinkets | <10 items/blocks |
| **registry/ subpackage** | Farmer's Delight | 10-50 items |
| **Root All*.java** | Create | 50+ items across modules |

## What ModSmith Should Generate

Based on the user's description, ModSmith should:

1. **Auto-detect mod size** from the user's request:
   - "Add a sword" → small → flat pattern
   - "Add a full equipment set with magic system" → medium → feature-based
   - "Make a complete tech mod with machines and power" → large → content+foundation

2. **Generate the right structure** automatically

3. **Default to Farmer's Delight pattern** (best fit for most mods—not too simple, not too complex)
