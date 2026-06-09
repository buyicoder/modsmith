---
name: mod-analyzer
description: Use when the user wants to analyze an existing Minecraft mod's architecture, learn from open-source mods, extract code patterns, or understand how a popular mod implements a specific feature. Triggers on: "analyze [mod name]", "how does [mod] implement", "study [mod]", "learn from [mod]", "extract patterns from [mod]".
---

# Mod Analyzer

## Overview

Analyzes open-source Minecraft mods to extract architecture patterns, registration strategies, and reusable code templates. Builds a structured knowledge base that feeds into other ModFactory skills for generating better code.

## Workflow

```
1. User specifies a mod + feature
2. Clone/fetch source from GitHub
3. Scan package structure → architecture pattern
4. Trace registration chains
5. Extract key class hierarchies
6. Generate knowledge card (JSON)
7. Extract reusable code templates
8. Store in knowledge/ directory
```

## Architecture Pattern Recognition

### Package Strategy
| Pattern | Structure | Example Mods |
|---------|-----------|-------------|
| **Feature-based** | `common/block/`, `common/item/`, `common/block/entity/` | Farmer's Delight |
| **Layer-based** | `core/`, `feature/`, `integration/` | Create |
| **Module-based** | `moduleA/`, `moduleB/` | Botania |
| **Flat** | Everything in one package | Small mods |

### Registration Strategy
| Pattern | Signature | Used By |
|---------|-----------|---------|
| **Centralized Registry** | All `ModXxx.java` in `registry/` | Farmer's Delight, Create |
| **DeferredRegister** | `DeferredRegister.create()` per class | Forge mods |
| **Static Init** | `static {}` blocks in each class | Our project |
| **Supplier-based** | `registerWithTab()` returns Supplier | Farmer's Delight |

## Analysis Output

Each analyzed mod produces a knowledge card saved in `knowledge/<mod_name>.json`:

```json
{
  "name": "Farmer's Delight",
  "version": "1.21.1",
  "loader": "fabric",
  "mappings": "mojang",
  "package": "vectorwing.farmersdelight",
  "architecture": {
    "pattern": "feature-based",
    "packages": ["common/block", "common/item", "common/registry", "client/gui"],
    "entry_point": "FarmersDelight.java → CommonSetup"
  },
  "registration": {
    "strategy": "centralized registry + supplier",
    "registry_classes": 24,
    "pattern_file": "registry/ModItems.java"
  },
  "key_systems": [
    {
      "name": "Cooking Pot",
      "pattern": "BlockEntity + Menu + Screen",
      "classes": ["CookingPotBlock", "CookingPotBlockEntity", "CookingPotMenu", "CookingPotScreen"]
    }
  ]
}
```

## Knowledge Base

Currently analyzed mods in `knowledge/`:

| Mod | MC Version | Patterns Extracted |
|-----|-----------|-------------------|
| [Farmer's Delight](knowledge/farmers-delight.json) | 1.21.1 | Feature packages, Centralized registry, Supplier-based registration, BlockEntity+GUI, Knife tool, Food system |

## Quick Analyze Command

```bash
# Analyze a GitHub repo
curl -sL "https://api.github.com/repos/{owner}/{repo}/git/trees/main?recursive=1" | analyze-tree

# Extract registration pattern
grep -r "Registry.register\|Items.register\|DeferredRegister" src/
```

## Integration with Other Skills

When `mc-mod-master` generates code, it references analyzed knowledge:
- "Make a cooking pot like Farmer's Delight" → uses `farmers-delight.json` knowledge
- "Add a knife tool" → references KnifeItem pattern
- "Need a centralized registry" → copies registry/ structure
