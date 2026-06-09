---
name: entity-generator
description: Use when the user needs to create custom Minecraft entities (mobs, bosses, pets, mounts, projectiles). Triggers on: "add a mob/boss/creature/pet/mount", "create an entity", "spawn a custom monster", "make a projectile/arrow", or dispatched by mc-mod-master.
---

# Entity Generator — Phase 2

## Overview

Generates complete entity registration, AI behavior, rendering, spawn rules, and loot tables. Supports mobs, bosses, pets, mounts, and projectiles.

**REQUIRED KNOWLEDGE:** `fabric-mc-mod-development` for registration patterns.
**REQUIRED CONTEXT:** `mod-analyzer/knowledge/architecture-patterns.md` for package structure.

## Critical: 1.21.11 Entity Rendering (RenderState API)

1.21.11 completely rewrote entity rendering. The old pattern `EntityModel<MyEntity>` is GONE.

**New pattern:** `EntityModel<RenderState>` — the model takes a RENDER STATE, not the entity.

```
Entity (server logic)  →  RenderState (data bridge)  →  Model (GPU vertices)
     │                          │                           │
 ThunderGolemEntity    LivingEntityRenderState     ThunderGolemEntityModel
 (AI, attributes)       (bodyYaw, pitch,           (head/body/arms/legs)
                         limbSwingAmplitude)
```

**Simplest setup (hostile mob):**
```java
// Model: use LivingEntityRenderState as type parameter
public class MyModel extends EntityModel<LivingEntityRenderState> {
    public MyModel(ModelPart root) { super(root); }
    public static TexturedModelData getTexturedModelData() { ... }
    @Override public void setAngles(LivingEntityRenderState state) { ... }
    // render() is FINAL in 1.21.11 — do NOT override it
}

// Renderer: 3 type params
public class MyRenderer extends MobEntityRenderer<MyEntity, LivingEntityRenderState, MyModel> {
    public static final EntityModelLayer LAYER = ...;
    public MyRenderer(Context ctx) { super(ctx, new MyModel(ctx.getPart(LAYER)), 0.7F); }
    @Override public LivingEntityRenderState createRenderState() { return new LivingEntityRenderState(); }
    @Override public Identifier getTexture(LivingEntityRenderState state) { return TEXTURE; }
}

// Client registration (both model layer AND renderer required!):
EntityModelLayerRegistry.registerModelLayer(MyRenderer.LAYER, MyModel::getTexturedModelData);
EntityRendererRegistry.register(MyEntityType, MyRenderer::new);
// ⚠️ Missing EITHER → NullPointerException: entityRenderer is null → game crash
```

## Yarn 1.21.11 API Notes

### EntityModel
- `ModelTransform.pivot(x,y,z)` → `ModelTransform.origin(x,y,z)` (Yarn only!)
- `render()` is **final** — model parts render automatically
- Type parameter: `EntityModel<LivingEntityRenderState>` not `EntityModel<MyEntity>`

### EntityAttributes (no GENERIC_ prefix in Yarn)
```
❌ EntityAttributes.GENERIC_MAX_HEALTH
✅ EntityAttributes.MAX_HEALTH
✅ EntityAttributes.MOVEMENT_SPEED
✅ EntityAttributes.ATTACK_DAMAGE
✅ EntityAttributes.ARMOR
✅ EntityAttributes.KNOCKBACK_RESISTANCE
```

### EntityType Registration
```java
// ❌ Old: .build("name")
// ✅ New: .build(RegistryKey.of(RegistryKeys.ENTITY_TYPE, Identifier.of(MOD_ID, "name")))
```

### SpawnEggItem (1.21.11)
```java
// Constructor takes ONLY Settings, NOT EntityType
new SpawnEggItem(new Item.Settings())
// Entity type is encoded in item NBT, not constructor
// Use SpawnEggItem.forEntity(entityType) as factory
// ⚠️ May crash in static initializer — test carefully
```

### Source Set Separation
- Entity class → `src/main/java/` (server + client shared)
- Model + Renderer → `src/client/java/` (client only)
- Client classes can't access `net.minecraft.client.*` from main source set

### Boss Bar
- Use `ServerBossBar` with RANGE-BASED management, not `onStartedTrackingBy`
- `onStartedTrackingBy` fires at entity tracking range (very far!)
- Manually add/remove players based on distance (<32 blocks recommended)

### Loot Table (1.21.11)
- `looting_enchant` → `enchanted_count_increase` with `"enchantment": "minecraft:looting"`
- All numeric values are floats: `1.0`, `0.0`
- Pools have `"bonus_rolls": 0.0` field
- Entity tables need `"random_sequence": "modid:entities/name"`

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

### Entity Model (with actual ModelPart code)

```java
// client/model/<Name>EntityModel.java
public class ThunderGolemEntityModel extends EntityModel<ThunderGolemEntity> {
    private final ModelPart head;
    private final ModelPart body;
    private final ModelPart rightArm;
    private final ModelPart leftArm;
    private final ModelPart rightLeg;
    private final ModelPart leftLeg;

    public ThunderGolemEntityModel(ModelPart root) {
        super(root);
        this.head = root.getChild("head");
        this.body = root.getChild("body");
        this.rightArm = root.getChild("right_arm");
        this.leftArm = root.getChild("left_arm");
        this.rightLeg = root.getChild("right_leg");
        this.leftLeg = root.getChild("left_leg");
    }

    public static TexturedModelData getTexturedModelData() {
        ModelData modelData = new ModelData();
        ModelPartData root = modelData.getRoot();
        root.addChild("head", ModelPartBuilder.create()
            .uv(0, 0).cuboid(-4.0F, -8.0F, -4.0F, 8, 8, 8), ModelTransform.pivot(0, 0, 0));
        root.addChild("body", ModelPartBuilder.create()
            .uv(0, 16).cuboid(-6.0F, 0.0F, -3.0F, 12, 10, 6), ModelTransform.pivot(0, 0, 0));
        root.addChild("right_arm", ModelPartBuilder.create()
            .uv(40, 16).cuboid(-3.0F, -2.0F, -2.0F, 4, 12, 4), ModelTransform.pivot(-8, 2, 0));
        root.addChild("left_arm", ModelPartBuilder.create()
            .uv(40, 16).mirrored().cuboid(-1.0F, -2.0F, -2.0F, 4, 12, 4), ModelTransform.pivot(8, 2, 0));
        root.addChild("right_leg", ModelPartBuilder.create()
            .uv(0, 32).cuboid(-2.0F, 0.0F, -2.0F, 4, 10, 4), ModelTransform.pivot(-3, 14, 0));
        root.addChild("left_leg", ModelPartBuilder.create()
            .uv(0, 32).mirrored().cuboid(-2.0F, 0.0F, -2.0F, 4, 10, 4), ModelTransform.pivot(3, 14, 0));
        return TexturedModelData.of(modelData, 64, 64);
    }

    @Override
    public void setAngles(ThunderGolemEntity entity, float limbAngle, float limbDistance,
            float animationProgress, float headYaw, float headPitch) {
        this.head.yaw = headYaw * 0.017453292F;
        this.head.pitch = headPitch * 0.017453292F;
        this.rightLeg.pitch = MathHelper.cos(limbAngle * 0.6662F) * 1.4F * limbDistance;
        this.leftLeg.pitch = MathHelper.cos(limbAngle * 0.6662F + 3.1415927F) * 1.4F * limbDistance;
        this.rightArm.pitch = MathHelper.cos(limbAngle * 0.6662F + 3.1415927F) * 1.4F * limbDistance;
        this.leftArm.pitch = MathHelper.cos(limbAngle * 0.6662F) * 1.4F * limbDistance;
    }

    @Override
    public void render(MatrixStack matrices, VertexConsumer vertices, int light, int overlay, int color) {
        head.render(matrices, vertices, light, overlay, color);
        body.render(matrices, vertices, light, overlay, color);
        rightArm.render(matrices, vertices, light, overlay, color);
        leftArm.render(matrices, vertices, light, overlay, color);
        rightLeg.render(matrices, vertices, light, overlay, color);
        leftLeg.render(matrices, vertices, light, overlay, color);
    }
}
```

Key dimensions reference:
- `cuboid(xOffset, yOffset, zOffset, width, height, depth)` — width/height/depth in pixels
- `uv(u, v)` — texture UV start coordinate on 64×64 entity texture
- `ModelTransform.pivot(x, y, z)` — rotation pivot point
- `.mirrored()` — mirror for left/right symmetry

**IMPORTANT:** Entity model code requires imports:
```java
import net.minecraft.client.model.*;
import net.minecraft.client.render.VertexConsumer;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.util.math.MathHelper;
```

### Entity Renderer

```java
// client/renderer/<Name>EntityRenderer.java
public class ThunderGolemEntityRenderer extends MobEntityRenderer<ThunderGolemEntity, ThunderGolemEntityModel> {
    private static final Identifier TEXTURE =
        Identifier.of(ExampleMod.MOD_ID, "textures/entity/thunder_golem.png");

    public ThunderGolemEntityRenderer(EntityRendererFactory.Context ctx) {
        super(ctx, new ThunderGolemEntityModel(ctx.getPart(ModModelLayers.THUNDER_GOLEM)), 0.6F);
    }

    @Override
    public Identifier getTexture(ThunderGolemEntity entity) {
        return TEXTURE;
    }
}
```

### ModelLayer Registration

```java
// client/<ModName>Client.java
public static final EntityModelLayer THUNDER_GOLEM =
    new EntityModelLayer(Identifier.of(MOD_ID, "thunder_golem"), "main");

@Override
public void onInitializeClient() {
    EntityRendererRegistry.register(ModEntityTypes.THUNDER_GOLEM,
        ThunderGolemEntityRenderer::new);
    EntityModelLayerRegistry.registerModelLayer(THUNDER_GOLEM,
        ThunderGolemEntityModel::getTexturedModelData);
}
```

### Entity Texture

Entity textures are 64×64 PNG with UV layout matching the model's `.uv()` calls. Generate via `appearance-designer` → "golem" category → recommend stone/metal body with colored cracks. Use `texture-ai-generator` for complex entity textures.

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
