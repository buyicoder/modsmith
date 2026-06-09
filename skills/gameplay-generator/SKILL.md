---
name: gameplay-generator
description: Use when the user needs complex gameplay systems (skills, classes, quests, economy, buffs). Triggers on: "add a skill system", "create player classes", "make a quest", "add mana/cooldown system", or dispatched by mc-mod-master. (Phase 3 - stub)
---

# Gameplay Generator

## Status: Phase 3 (Planned)

Complex gameplay systems are the core differentiator of this plugin vs CreativeMode. Each system requires domain-specific modeling.

## Planned Systems

### Skill System
- Cooldown management (component-based)
- Mana/energy resource system
- Multi-level skill upgrades
- Skill unlock trees
- Visual effects integration

### Class System
- Warrior/Archer/Mage templates
- Attribute modifiers (strength, agility, intelligence)
- Class-specific skill restrictions
- Level-up progression

### Quest System
- Kill/collect/deliver quest types
- Quest giver NPC integration
- Reward tables
- Quest chain/sequence support

### Economy System
- Custom currency items
- Shop GUI (trade interface)
- Price configuration
- Buy/sell mechanics

### Buff/Debuff System
- Status effect registration
- Duration + tick callbacks
- Stack rules
- Visual indicators (particles, overlay)

## Architecture Pattern (Planned)

Each gameplay system follows a common architecture:
```
System Manager (singleton)
├── Data Component (persistent player state)
├── Event Handlers (triggers)
├── Network Packets (client-server sync)
└── GUI/Screen (user interface)
```

**Current Phase 1 recommendation:** Use `item-generator` custom-behavior items for simple gameplay mechanics. Full gameplay systems will be available in Phase 3.
