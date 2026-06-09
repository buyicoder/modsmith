---
name: entity-designer
description: Use when the user wants to create a custom Minecraft entity and needs a complete design blueprint BEFORE any code is written. Triggers on: "design an entity", "plan a mob", "create a boss", "I want a creature that...", or dispatched by mc-mod-master as the FIRST step before entity-generator.
---

# Entity Designer — Blueprint Before Code

## Overview

Creates a complete entity design specification BEFORE any code is written. Prevents the "half-built entity" problem where model, texture, sounds, or spawn eggs are afterthoughts.

## The Design-First Rule

```
❌ WRONG: Write entity code → add model → add texture → add sounds → "done"
✅ RIGHT: Design ALL aspects → User approves → Generate all at once → Closure check
```

## Entity Blueprint Template

Every entity design MUST fill all sections before generation:

```markdown
# Entity Blueprint: [Name]

## 1. Concept
- Type: [Hostile / Neutral / Boss / Pet / Mount / Ambient]
- Theme: [Elemental / Mechanical / Undead / ...]
- Size: [Tiny / Small / Medium / Large / Giant]
- Role: [Guardian / Hunter / Support / Minion / Event Boss]

## 2. Visual Design
- Model shape: [Humanoid / Quadruped / Flying / Serpent / Blob / Custom]
- Reference vanilla: [Zombie / Iron Golem / Blaze / ...] for model proportions
- Texture palette: [from GearFactory palettes] → name:
- Distinctive features: [Glowing eyes / Crystal shards / Particle aura / ...]

## 3. Combat Stats
- Health: [number]
- Armor: [number]
- Attack damage (melee): [number]
- Attack damage (ranged): [number]
- Speed: [number]
- Knockback resistance: [0-1]

## 4. Behavior
- [ ] Melee attack
- [ ] Ranged attack (type: ________)
- [ ] Special ability (describe: ________)
- [ ] Flees when low health
- [ ] Calls for help
- [ ] Passive until provoked
- [ ] Patrols area
- [ ] Follows owner

## 5. Spawning
- [ ] Natural spawn (biome: ________, weight: ________)
- [ ] Structure spawn (structure: ________)
- [ ] Boss summon (summon item: ________)
- [ ] Spawn egg (colors: primary ________, secondary ________)
- [ ] Weather/Time condition (________)

## 6. Drops
- Common: [item × quantity]
- Rare: [item × quantity, chance %]
- Guaranteed: [item × quantity]
- XP: [amount]

## 7. Audio
- Ambient sound: [vanilla reference or custom]
- Hurt sound: [________]
- Death sound: [________]
- Attack sound: [________]
- Step sound: [________]

## 8. Model Detail
- Body parts: [head / body / arms / legs / wings / tail / ...]
- UV map size: [64x64 / 128x64]
- Animations: [walk / attack / idle / special / death]
- Model complexity: [Simple (4-6 parts) / Medium (7-10) / Complex (10+)]

## 9. Generation Checklist
Before generating code, verify:
- [ ] ALL sections above are filled
- [ ] User has approved the design
- [ ] Texture palette is chosen
- [ ] Sound strategy is decided
- [ ] Spawn method is clear
```

## Quality Gates

### Gate 1: Concept Complete
All 9 sections filled with specific values (no "TBD" or "maybe").

### Gate 2: User Approved
Present the blueprint to user. Wait for explicit approval before proceeding.

### Gate 3: Generation Ready
Blueprint passed to `entity-generator` which now knows exactly what to build.

## Integration with ModSmith Pipeline

```
User: "I want a thunder golem"
    │
    ▼
entity-designer ← RUNS FIRST
    │
    ├── Ask clarifying questions
    ├── Fill blueprint
    ├── Present to user
    └── User approves
    │
    ▼
entity-generator ← RECEIVES COMPLETE BLUEPRINT
    │
    ├── Knows model shape → generates correct ModelPart code
    ├── Knows texture palette → calls texture-generator
    ├── Knows sounds → generates ModSounds + sound JSONs
    ├── Knows spawn method → generates spawn egg or structure
    └── Knows drops → generates loot table
    │
    ▼
integrity-checker ← VERIFIES COMPLETENESS
    │
    └── Checks: All blueprint items have corresponding files
```

## Real Example: Thunder Golem Retrospective

What we DID (wrong):
```
❌ Wrote entity code → compiled → crashed (no renderer)
❌ Added renderer → crashed (no texture)
❌ Added texture → worked but no spawn egg
❌ Tried spawn egg → crashed (API changed)
❌ Forgot sounds entirely
❌ 20+ iterations
```

What we SHOULD have done (right):
```
✅ Fill blueprint first
✅ Model: Iron Golem shape, 64x64 texture
✅ Texture: dark stone body + golden cracks → thunder_golem.png
✅ Sounds: iron golem sounds (placeholder)
✅ Spawn egg: skip (API unstable) → use /summon + natural spawn
✅ User approves → generate all files at once → 1-2 iterations
```

## Minimum Viable Entity (MVE)

For quick prototyping, at minimum fill these:

```
- Type + Theme
- Health + Attack + Speed
- Behavior (pick from checklist)
- Spawn method (pick one)
- Drops (at least 1 item)
- Model ref (which vanilla entity to base proportions on)
- Texture palette name
- Audio: "use vanilla [entity] sounds"
```

All other fields can use defaults. But they must be CONSCIOUS defaults, not forgotten.
