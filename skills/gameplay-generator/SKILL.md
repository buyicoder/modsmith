---
name: gameplay-generator
description: Use when the user needs complex gameplay systems (skills, classes, quests, economy, buffs, mana, cooldowns). Triggers on: "add a skill system", "create player classes", "make a quest", "add mana/cooldown", "create a buff/debuff system", or dispatched by mc-mod-master.
---

# Gameplay Generator — Phase 2

## Overview

Generates complete gameplay system code using patterns from industry-class mods. Each system follows a proven architecture from Tinkers Construct, Create, or Farmer's Delight.

**REQUIRED KNOWLEDGE:** `fabric-mc-mod-development` for registration patterns.
**REQUIRED CONTEXT:** `mod-analyzer/knowledge/tinkers-construct.json` for modifier/composable behavior patterns.

## Available System Templates

### Skill System (Tinkers Modifier Pattern)
```
Components:
├── Skill registry (like Tinkers' Modifier registry)
├── Skill data component (persistent player state)
├── Skill use handler (right-click/event trigger)
├── Cooldown manager (time-based)
├── Mana/energy manager (resource-based)
└── Network sync (client-server)
```

### Buff/Debuff System (Status Effect Pattern)
```
Components:
├── Custom StatusEffect registration
├── Buff application logic (item use / event / command)
├── Duration + tick callback handler
├── Stack rules (refresh/replace/stack)
└── Visual indicators (HUD overlay, particles)
```

### Class/Attribute System
```
Components:
├── Class registry (Warrior/Archer/Mage templates)
├── Attribute modifier application
├── Level-up progression
└── Class-specific skill restrictions
```

## Quick Generate: Skill System

```java
// common/skill/Skill.java — Base interface (Tinkers Modifier pattern)
public interface Skill {
    Identifier getId();
    int getMaxLevel();
    int getManaCost(int level);
    int getCooldownTicks(int level);
    ActionResult use(World world, PlayerEntity user, int level);
}

// common/skill/SkillRegistry.java — Central registry
public class SkillRegistry {
    private static final Map<Identifier, Skill> SKILLS = new HashMap<>();

    public static Skill register(Identifier id, Skill skill) {
        SKILLS.put(id, skill);
        return skill;
    }

    public static Optional<Skill> get(Identifier id) {
        return Optional.ofNullable(SKILLS.get(id));
    }
}

// common/skill/PlayerSkillData.java — Persistent data (component-based)
public class PlayerSkillData {
    private final Map<Identifier, Integer> skillLevels = new HashMap<>();
    private final Map<Identifier, Long> cooldowns = new HashMap<>();
    private int currentMana;
    private int maxMana;

    public boolean canUse(Skill skill) {
        if (currentMana < skill.getManaCost(getLevel(skill))) return false;
        Long cooldown = cooldowns.get(skill.getId());
        if (cooldown != null && System.currentTimeMillis() < cooldown) return false;
        return true;
    }

    public void use(Skill skill) {
        int level = getLevel(skill);
        currentMana -= skill.getManaCost(level);
        cooldowns.put(skill.getId(),
            System.currentTimeMillis() + skill.getCooldownTicks(level) * 50L);
    }
}

// Example: Fireball Skill
public class FireballSkill implements Skill {
    @Override
    public ActionResult use(World world, PlayerEntity user, int level) {
        if (world.isClient()) return ActionResult.SUCCESS;
        FireballEntity fireball = new FireballEntity(world, user,
            user.getRotationVector().x * 2,
            user.getRotationVector().y * 2,
            user.getRotationVector().z * 2);
        fireball.setPosition(user.getX(), user.getEyeY(), user.getZ());
        world.spawnEntity(fireball);
        return ActionResult.SUCCESS;
    }
}
```

## Quick Generate: Buff System

```java
// common/effect/CustomStatusEffect.java
public class RubyStrengthEffect extends StatusEffect {
    public RubyStrengthEffect() {
        super(StatusEffectCategory.BENEFICIAL, 0xFF4444); // red color
    }

    @Override
    public boolean canApplyUpdateEffect(int duration, int amplifier) {
        return duration % 20 == 0; // tick every second
    }

    @Override
    public boolean applyUpdateEffect(LivingEntity entity, int amplifier) {
        entity.addVelocity(0, 0.1, 0); // Example: slight levitation
        return true;
    }
}

// Registration in ModEffects
public static final StatusEffect RUBY_STRENGTH = Registry.register(
    Registries.STATUS_EFFECT,
    Identifier.of(MOD_ID, "ruby_strength"),
    new RubyStrengthEffect()
);
```

## Auto-Generated Files Per System

| System | Files Generated |
|--------|----------------|
| Skill System | Skill.java (interface), SkillRegistry.java, PlayerSkillData.java, <Name>Skill.java, ModSkills.java |
| Buff System | <Name>Effect.java, ModEffects.java, effect icon PNG |
| Class System | PlayerClass.java (enum), ClassRegistry.java, <Name>Class.java, ModAttributes.java |
| Economy | CurrencyItem.java, ShopScreen.java, ShopInventory.java, ModCurrency.java |

## System Integration with Items

Gameplay systems connect to items via the custom-behavior pattern:
```java
// A staff item that uses the skill system
public class FireStaffItem extends Item {
    @Override
    public ActionResult use(World world, PlayerEntity user, Hand hand) {
        Skill fireball = SkillRegistry.get(ModSkills.FIREBALL).get();
        PlayerSkillData data = PlayerSkillData.get(user);
        if (data.canUse(fireball)) {
            data.use(fireball);
            fireball.use(world, user, data.getLevel(fireball));
            return ActionResult.SUCCESS;
        }
        return ActionResult.FAIL;
    }
}
```

## Architecture Decision

Gameplay systems use the **content+foundation** pattern (Create style):
```
common/
├── skill/          ← Skill system (content)
├── effect/         ← Buff system (content)
├── playerclass/    ← Class system (content)
└── registry/       ← All registrations
```

For smaller mods, put gameplay systems directly in `common/` with a single class each.
