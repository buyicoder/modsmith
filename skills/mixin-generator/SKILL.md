---
name: mixin-generator
description: Use when the user needs to modify vanilla Minecraft behavior via Mixin injection. Triggers on: "add a mixin", "modify vanilla behavior", "inject into", "override Minecraft class", "change how [vanilla feature] works", or dispatched by mc-mod-master.
---

# Mixin Generator

## Overview

Generates Mixin classes for modifying vanilla Minecraft behavior. Mixins are the primary way Fabric mods change vanilla game logic without replacing entire classes.

## Mixin Type Selection

```
What do you want to do?
│
├── Add code BEFORE a method → @Inject(at = @At("HEAD"))
├── Add code AFTER a method → @Inject(at = @At("RETURN"))
├── Modify method arguments → @ModifyArgs / @ModifyVariable
├── Replace method entirely → @Overwrite (use sparingly)
├── Add field/method to class → @Mixin + @Unique
├── Cancel a method call → @Inject + ci.cancel()
├── Redirect method call → @Redirect
└── Access private member → @Accessor / @Invoker
```

## Quick Templates

### @Inject — Add code at method entry
```java
@Mixin(PlayerEntity.class)
public class PlayerEntityMixin {
    @Inject(method = "tick", at = @At("HEAD"))
    private void onTick(CallbackInfo ci) {
        // Code runs at start of every PlayerEntity.tick()
    }
}
```

### @Inject — Add code at method return
```java
@Mixin(LivingEntity.class)
public class LivingEntityDamageMixin {
    @Inject(method = "damage", at = @At("RETURN"))
    private void onDamage(DamageSource source, float amount, CallbackInfo ci) {
        // Code runs after damage is applied
    }
}
```

### @ModifyArg — Change method parameter
```java
@Mixin(ItemEntity.class)
public class ItemEntityMixin {
    @ModifyArg(method = "tick", at = @At(value = "INVOKE",
        target = "Lnet/minecraft/entity/ItemEntity;setVelocity(DDD)V"), index = 1)
    private double modifyFallSpeed(double original) {
        return original * 0.5; // Items fall 50% slower
    }
}
```

### @Redirect — Replace method call
```java
@Mixin(Block.class)
public class BlockMixin {
    @Redirect(method = "onBreak", at = @At(value = "INVOKE",
        target = "Lnet/minecraft/block/Block;dropStacks(Lnet/minecraft/block/BlockState;Lnet/minecraft/world/World;Lnet/minecraft/util/math/BlockPos;Lnet/minecraft/block/entity/BlockEntity;Lnet/minecraft/entity/Entity;Lnet/minecraft/item/ItemStack;)V"))
    private void redirectDrop(BlockState state, World world, BlockPos pos,
            BlockEntity blockEntity, Entity entity, ItemStack stack) {
        // Custom drop logic
    }
}
```

### @Accessor — Access private field
```java
@Mixin(PlayerEntity.class)
public interface PlayerEntityAccessor {
    @Accessor("sleepTimer")
    void setSleepTimer(int timer);

    @Accessor("sleepTimer")
    int getSleepTimer();
}
```

### @Invoker — Call private method
```java
@Mixin(LivingEntity.class)
public interface LivingEntityInvoker {
    @Invoker("getJumpVelocity")
    float invokeGetJumpVelocity();
}
```

## Mixin Config JSON

```json
// MODID.mixins.json — Required for Mixin to work
{
  "required": true,
  "package": "com.example.mixin",
  "compatibilityLevel": "JAVA_21",
  "mixins": [
    "PlayerEntityMixin",
    "LivingEntityDamageMixin"
  ],
  "client": [
    "client.ClientRenderMixin"
  ],
  "injectors": {
    "defaultRequire": 1
  }
}
```

Must be referenced in `fabric.mod.json`:
```json
"mixins": ["MODID.mixins.json"]
```

## Version-Specific Method Names (Critical!)

Mixins reference vanilla method signatures. These CHANGE between MC versions.

**CRITICAL PITFALL:** Method signatures add/remove parameters between versions.
- MC 1.21.11: `LivingEntity.damage(ServerWorld, DamageSource, float)` ← FIRST param is ServerWorld!
- Earlier MC 1.21: `LivingEntity.damage(DamageSource, float)` ← NO ServerWorld

**Always verify the exact method signature** by checking the source jar:
```bash
# Check actual method signature in remapped jar
jar tf .gradle/loom-cache/.../*.jar | grep "ClassName"
# Then decompile
javap -c ClassName.class
```

**Common signature changes:**
| Method | MC <1.21.2 | MC 1.21.2+ |
|--------|-----------|------------|
| `LivingEntity.damage` | `(DamageSource, float)` | `(ServerWorld, DamageSource, float)` |
| `Block.onBreak` | `(World, BlockPos, BlockState, PlayerEntity)` | `(World, BlockPos, BlockState, PlayerEntity, ItemStack)` |

**ERROR EXAMPLE:**
```
Invalid descriptor: Expected (L.../ServerWorld;L.../DamageSource;F...)V 
but found (L.../DamageSource;F...)V
```
This means you're missing the `ServerWorld` parameter in your Mixin method.

## Auto-Generated Files Per Mixin

| File | Path |
|------|------|
| Mixin class | `common/mixin/<Name>Mixin.java` |
| Mixin config JSON | `resources/MODID.mixins.json` |
| fabric.mod.json update | Add `"mixins"` entry |

## Common Mixin Targets

| Vanilla Class | Common Use Case |
|---------------|----------------|
| `PlayerEntity` | Player-specific behavior |
| `LivingEntity` | All living mobs |
| `ItemEntity` | Dropped items |
| `Block` | Block interactions |
| `ItemStack` | Item properties |
| `ServerPlayerEntity` | Server-side player logic |
| `MinecraftClient` | Client rendering |
| `InGameHud` | HUD modification |

## Architecture

Mixin classes go in `common/mixin/` (feature-based) or `mixin/` (flat). Client-only mixins go in `client/mixin/`.

The mixin config JSON MUST be at `src/main/resources/MODID.mixins.json` (root of resources).
