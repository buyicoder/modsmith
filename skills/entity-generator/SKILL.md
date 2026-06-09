---
name: entity-generator
description: Use when the user needs to create custom Minecraft entities (mobs, bosses, pets, mounts). Triggers on: "add a mob/boss/creature/pet", "create an entity", or dispatched by mc-mod-master. (Phase 2 - stub)
---

# Entity Generator

## Status: Phase 2 (Planned)

Entity generation requires significant boilerplate across multiple files. This skill will provide templates for:

### Planned Entity Types
- Hostile mob (zombie/skeleton style)
- Boss entity (multi-phase, special attacks)
- Passive mob (pet/ambient)
- Mount (rideable entity)
- Projectile (arrow/fireball style)

### Planned Output Files
- Entity class (extends `LivingEntity` or `MobEntity`)
- Entity model + renderer
- Spawn egg item registration
- Spawn rules JSON
- Loot table JSON
- Animation config (if needed)

### Entity AI Templates (Planned)
```java
// Goal-based AI composition
goalSelector.add(1, new SwimGoal(this));
goalSelector.add(2, new MeleeAttackGoal(this, 1.0D, false));
goalSelector.add(3, new WanderAroundFarGoal(this, 1.0D));
goalSelector.add(4, new LookAtEntityGoal(this, PlayerEntity.class, 8.0F));
```

**Current Phase 1 recommendation:** Use `item-generator` with custom-behavior Item class for simple entity-like interactions. Full entity generation will be available in Phase 2.
