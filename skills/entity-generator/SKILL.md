---
name: entity-generator
description: Use when the user needs to create custom Minecraft entities (mobs, bosses, pets, mounts, projectiles). Triggers on: "add a mob/boss/creature/pet/mount", "create an entity", "spawn a custom monster", "make a projectile/arrow", or dispatched by mc-mod-master.
---

# Entity Generator — Phase 2

## Overview

Generates complete entity registration, AI behavior, rendering, spawn rules, and loot tables. Supports mobs, bosses, pets, mounts, and projectiles.

**REQUIRED KNOWLEDGE:** `fabric-mc-mod-development` for registration patterns.
**REQUIRED CONTEXT:** `mod-analyzer/knowledge/architecture-patterns.md` for package structure.

## Entity Type Selection

```
Entity type?
│
├── Hostile Mob → MobEntity + MeleeAttackGoal + SpawnRestriction
├── Boss → MobEntity + multi-phase AI + boss bar + special drops
├── Pet/Companion → TameableEntity + FollowOwnerGoal + sit/stand
├── Mount → HorseBaseEntity + riding logic + saddle
└── Projectile → PersistentProjectileEntity + collision logic
```

## Quick Generate

### Simple Hostile Mob

```java
// common/entity/<Name>Entity.java
public class RubyGolemEntity extends HostileEntity {
    public RubyGolemEntity(EntityType<? extends HostileEntity> type, World world) {
        super(type, world);
    }

    @Override
    protected void initGoals() {
        this.goalSelector.add(0, new SwimGoal(this));
        this.goalSelector.add(1, new MeleeAttackGoal(this, 1.0D, false));
        this.goalSelector.add(2, new WanderAroundFarGoal(this, 1.0D));
        this.goalSelector.add(3, new LookAtEntityGoal(this, PlayerEntity.class, 8.0F));
        this.targetSelector.add(1, new RevengeGoal(this));
        this.targetSelector.add(2, new ActiveTargetGoal<>(this, PlayerEntity.class, true));
    }

    public static DefaultAttributeContainer.Builder createAttributes() {
        return HostileEntity.createHostileAttributes()
            .add(EntityAttributes.GENERIC_MAX_HEALTH, 40.0D)
            .add(EntityAttributes.GENERIC_MOVEMENT_SPEED, 0.25D)
            .add(EntityAttributes.GENERIC_ATTACK_DAMAGE, 6.0D)
            .add(EntityAttributes.GENERIC_FOLLOW_RANGE, 35.0D);
    }
}
```

### Entity Model + Renderer

```java
// client/model/<Name>EntityModel.java
public class RubyGolemEntityModel extends EntityModel<RubyGolemEntity> {
    private final ModelPart body;
    // ... standard model parts and animation
}

// client/renderer/<Name>EntityRenderer.java
public class RubyGolemEntityRenderer extends MobEntityRenderer<RubyGolemEntity, RubyGolemEntityModel> {
    public RubyGolemEntityRenderer(EntityRendererFactory.Context ctx) {
        super(ctx, new RubyGolemEntityModel(ctx.getPart(ModModelLayers.RUBY_GOLEM)), 0.5F);
    }

    @Override
    public Identifier getTexture(RubyGolemEntity entity) {
        return Identifier.of(ExampleMod.MOD_ID, "textures/entity/ruby_golem.png");
    }
}
```

### Registration

```java
// common/registry/ModEntityTypes.java
public static final EntityType<RubyGolemEntity> RUBY_GOLEM = Registry.register(
    Registries.ENTITY_TYPE,
    Identifier.of(MOD_ID, "ruby_golem"),
    FabricEntityTypeBuilder.create(SpawnGroup.MONSTER, RubyGolemEntity::new)
        .dimensions(EntityDimensions.fixed(1.4F, 2.7F))
        .trackRangeChunks(8)
        .build()
);
```

### Client Registration

```java
// client/<ModName>Client.java (in onInitializeClient)
EntityRendererRegistry.register(ModEntityTypes.RUBY_GOLEM, RubyGolemEntityRenderer::new);
EntityModelLayerRegistry.registerModelLayer(ModModelLayers.RUBY_GOLEM, RubyGolemEntityModel::getTexturedModelData);
```

### Spawn Rules

```java
// common/event/EntitySpawnEvents.java
SpawnRestriction.register(ModEntityTypes.RUBY_GOLEM,
    SpawnLocationTypes.ON_GROUND, Heightmap.Type.MOTION_BLOCKING_NO_LEAVES,
    HostileEntity::canSpawnInDark);
FabricDefaultBiomeModifications.addSpawn(
    BiomeSelectors.foundInOverworld(), SpawnGroup.MONSTER,
    ModEntityTypes.RUBY_GOLEM, 15, 1, 3);
```

## Auto-Generated Files Per Entity

| File | Required | Architecture-aware path |
|------|----------|------------------------|
| Entity class | Yes | `common/entity/<Name>Entity.java` |
| Entity model | Yes | `client/model/<Name>EntityModel.java` |
| Entity renderer | Yes | `client/renderer/<Name>EntityRenderer.java` |
| Registration | Yes | `common/registry/ModEntityTypes.java` |
| Spawn egg item | Optional | `common/registry/ModItems.java` |
| Spawn rules | Optional | `common/event/EntitySpawnEvents.java` |
| Loot table JSON | Optional | `data/MODID/loot_table/entities/<name>.json` |
| Entity texture PNG | Yes | `textures/entity/<name>.png` |
| Spawn egg texture | Optional | `textures/item/<name>_spawn_egg.png` |

## Common AI Goals (Reference)

| Goal | Purpose |
|------|---------|
| `SwimGoal` | Float in water |
| `MeleeAttackGoal` | Chase + melee attack |
| `BowAttackGoal` | Ranged bow attack |
| `WanderAroundFarGoal` | Random walking |
| `LookAtEntityGoal` | Look at nearby players |
| `FollowOwnerGoal` | Pet follows owner |
| `SitGoal` | Pet sits on command |
| `RevengeGoal` | Attack whoever hurt me |
| `ActiveTargetGoal` | Target specific entity types |
| `FleeEntityGoal` | Run away from target |

## Architecture Integration

Entity classes go in the same package pattern as items/blocks:

| Architecture | Entity class | Renderer |
|-------------|-------------|----------|
| flat | `ExampleEntity.java` | Same package |
| feature-based | `common/entity/` | `client/renderer/` |
| registry-logic-split | `common/entities/` | `client/renderer/` |
| content+foundation | `content/<module>/entity/` | `content/<module>/client/renderer/` |

## Entity Texture Generation

Entity textures are special — they need UV-mapped model textures, not simple 16x16 icons. Use `texture-generator` for simple entity textures or recommend Blockbench for complex models.
