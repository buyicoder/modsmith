---
name: item-generator
description: Use when the user needs to create Minecraft items (weapons, tools, armor, food, special items). Triggers on: "add a sword/pickaxe/axe/shovel/hoe", "create armor", "make a food item", "add a special item with right-click ability", or dispatched by mc-mod-master.
---

# Item Generator

## Overview

Generates complete Java source code, JSON resources, and registration code for Minecraft items. Supports all item types: materials, tools, armor, food, and custom-behavior items.

**REQUIRED KNOWLEDGE:** `fabric-mc-mod-development` skill for exact API patterns and mappings.

## Item Type Templates

### Material Item (simple)
```java
public static final Item RUBY = register("ruby", Item::new, new Item.Settings());
```

### Tool (Sword)
```java
public static final Item RUBY_SWORD = register("ruby_sword", Item::new,
    new Item.Settings().sword(RubyToolMaterial.INSTANCE, 3.0F, -2.4F));
```

### Tool (Pickaxe)
```java
public static final Item RUBY_PICKAXE = register("ruby_pickaxe", Item::new,
    new Item.Settings().pickaxe(RubyToolMaterial.INSTANCE, 1.0F, -2.8F));
```

### Tool (Axe) — MUST use AxeItem class!
```java
public static final Item RUBY_AXE = register("ruby_axe",
    s -> new AxeItem(RubyToolMaterial.INSTANCE, 5.0F, -3.0F, s), new Item.Settings());
```

### Tool (Shovel) — MUST use ShovelItem class!
```java
public static final Item RUBY_SHOVEL = register("ruby_shovel",
    s -> new ShovelItem(RubyToolMaterial.INSTANCE, 1.5F, -3.0F, s), new Item.Settings());
```

### Tool (Hoe) — MUST use HoeItem class!
```java
public static final Item RUBY_HOE = register("ruby_hoe",
    s -> new HoeItem(RubyToolMaterial.INSTANCE, -3.0F, 0.0F, s), new Item.Settings());
```

### Armor
```java
public static final Item RUBY_HELMET = register("ruby_helmet", Item::new,
    new Item.Settings().armor(RubyArmorMaterial.INSTANCE, EquipmentType.HELMET));
```

### Food
```java
public static final Item RUBY_APPLE = register("ruby_apple", Item::new,
    new Item.Settings().food(new FoodComponent.Builder()
        .nutrition(8).saturationModifier(1.2F).build()));
```

### Custom Behavior (Right-click)
```java
public class CustomItem extends Item {
    public CustomItem(Settings settings) { super(settings); }
    @Override
    public ActionResult use(World world, PlayerEntity user, Hand hand) {
        if (world.isClient()) return ActionResult.SUCCESS;
        // Custom logic here (spawn entity, apply effect, etc.)
        return ActionResult.SUCCESS;
    }
}
```

## Auto-Generated Files Per Item

| File | Path | Required? |
|------|------|-----------|
| ModItems.java entry | `src/main/java/.../ModItems.java` | Always |
| ToolMaterial class | `.../RubyToolMaterial.java` | Tools |
| ArmorMaterial class | `.../RubyArmorMaterial.java` | Armor |
| Item model JSON | `assets/MODID/models/item/<name>.json` | Always |
| Item mapping JSON | `assets/MODID/items/<name>.json` | 1.21.4+ |
| Texture PNG | `assets/MODID/textures/item/<name>.png` | Always |
| Recipe JSON | `data/MODID/recipe/<name>.json` | Optional |
| Equipment JSON | `assets/MODID/equipment/<name>.json` | Armor |
| Equipment textures | `textures/entity/equipment/humanoid/<name>.png` | Armor |
| Equipment leggings | `textures/entity/equipment/humanoid_leggings/<name>.png` | Armor |

## Common Mistakes to Avoid

1. **Axe/Shovel/Hoe**: MUST use `AxeItem`/`ShovelItem`/`HoeItem` class, not `Item::new` with `.axe()`/`.shovel()`/`.hoe()`
2. **ToolMaterial**: Is a Java Record, construct with `new ToolMaterial(...)`, don't try to `implements`
3. **Armor EquipmentAsset**: Use `RegistryKey.of(EquipmentAssetKeys.REGISTRY_KEY, Identifier.of(MOD_ID, name))` NOT `EquipmentAssetKeys.register(name)`
4. **Creative tab entries**: Use `entries.add()`, not `entries.accept()`
