---
name: command-generator
description: Use when the user needs custom Minecraft commands with argument parsing, permissions, and completion suggestions. Triggers on: "add a command", "create /command", "custom slash command", "make a teleport command", "admin command", or dispatched by mc-mod-master.
---

# Command Generator

## Overview

Generates Brigadier command registrations following Fabric's Command API. Covers simple commands, commands with arguments, subcommands, permission checks, and completion suggestions.

## Command Type Selection

```
What kind of command?
│
├── Simple command → /command (no args, single action)
├── With arguments → /command <number> <player> <block>
├── Subcommands → /command give|take|set <args>
├── Permission-gated → /command (ops only)
├── With suggestions → auto-complete player names, item IDs
└── Server-side only → /command (client never sees)
```

## Quick Templates

### Simple Command (no args)
```java
// common/command/ModCommands.java
public class ModCommands {
    public static void register() {
        CommandRegistrationCallback.EVENT.register((dispatcher, registryAccess, environment) -> {
            dispatcher.register(CommandManager.literal("heal")
                .executes(context -> {
                    ServerPlayerEntity player = context.getSource().getPlayerOrThrow();
                    player.setHealth(player.getMaxHealth());
                    context.getSource().sendFeedback(
                        () -> Text.literal("You have been healed!"),
                        false
                    );
                    return Command.SINGLE_SUCCESS;
                })
            );
        });
    }
}

// Call ModCommands.register() in onInitialize()
```

### Command with Arguments
```java
dispatcher.register(CommandManager.literal("givegem")
    .then(CommandManager.argument("target", EntityArgumentType.players())
        .then(CommandManager.argument("amount", IntegerArgumentType.integer(1, 64))
            .executes(context -> {
                Collection<ServerPlayerEntity> targets =
                    EntityArgumentType.getPlayers(context, "target");
                int amount = IntegerArgumentType.getInteger(context, "amount");
                ItemStack stack = new ItemStack(ModItems.RUBY, amount);
                for (ServerPlayerEntity target : targets) {
                    target.getInventory().offerOrDrop(stack);
                }
                context.getSource().sendFeedback(
                    () -> Text.literal("Gave " + amount + " rubies to " + targets.size() + " player(s)"),
                    true
                );
                return targets.size();
            })
        )
    )
);
```

### Subcommands
```java
dispatcher.register(CommandManager.literal("modfactory")
    .requires(source -> source.hasPermissionLevel(2)) // OP only
    .then(CommandManager.literal("reload")
        .executes(context -> {
            // Reload config
            context.getSource().sendFeedback(
                () -> Text.literal("Config reloaded!"), true);
            return Command.SINGLE_SUCCESS;
        })
    )
    .then(CommandManager.literal("debug")
        .then(CommandManager.argument("enabled", BoolArgumentType.bool())
            .executes(context -> {
                boolean enabled = BoolArgumentType.getBool(context, "enabled");
                context.getSource().sendFeedback(
                    () -> Text.literal("Debug mode: " + enabled), false);
                return Command.SINGLE_SUCCESS;
            })
        )
    )
    .then(CommandManager.literal("info")
        .executes(context -> {
            context.getSource().sendFeedback(
                () -> Text.literal("ModFactory v2.1.0"), false);
            return Command.SINGLE_SUCCESS;
        })
    )
);
```

### With Suggestions (Auto-Complete)
```java
dispatcher.register(CommandManager.literal("finditem")
    .then(CommandManager.argument("item", ItemStackArgumentType.itemStack(registryAccess))
        .suggests((context, builder) -> {
            // Suggest all mod items
            return ItemStackArgumentType.itemStack().listSuggestions(context, builder);
        })
        .executes(context -> {
            ItemStack item = ItemStackArgumentType.getItemStackArgument(context, "item")
                .createStack(1, false);
            context.getSource().sendFeedback(
                () -> Text.literal("Item: " + item.getName().getString()), false);
            return Command.SINGLE_SUCCESS;
        })
    )
);
```

### Teleport Command (with BlockPos)
```java
dispatcher.register(CommandManager.literal("tprandom")
    .requires(source -> source.hasPermissionLevel(2))
    .then(CommandManager.argument("range", IntegerArgumentType.integer(100, 10000))
        .executes(context -> {
            ServerPlayerEntity player = context.getSource().getPlayerOrThrow();
            int range = IntegerArgumentType.getInteger(context, "range");
            Random random = new Random();
            int x = random.nextInt(range * 2) - range;
            int z = random.nextInt(range * 2) - range;
            int y = player.getWorld().getTopY(Heightmap.Type.MOTION_BLOCKING, x, z);
            player.teleport(player.getServerWorld(), x, y, z, player.getYaw(), player.getPitch());
            context.getSource().sendFeedback(
                () -> Text.literal("Teleported to " + x + ", " + y + ", " + z), true);
            return Command.SINGLE_SUCCESS;
        })
    )
);
```

## Argument Types Reference

| Argument Type | Usage | Example |
|--------------|-------|---------|
| `IntegerArgumentType.integer(min, max)` | Numbers | `/heal <amount>` |
| `FloatArgumentType.floatArg(min, max)` | Decimals | `/speed <multiplier>` |
| `BoolArgumentType.bool()` | true/false | `/debug <on|off>` |
| `StringArgumentType.string()` | Text | `/rename <name>` |
| `StringArgumentType.greedyString()` | Multi-word text | `/broadcast <message>` |
| `EntityArgumentType.players()` | Player selector | `/give @a` |
| `EntityArgumentType.entities()` | Any entity selector | `/kill @e` |
| `BlockPosArgumentType.blockPos()` | Coordinates | `/spawn <x> <y> <z>` |
| `ItemStackArgumentType.itemStack()` | Item ID | `/give <item>` |
| `BlockStateArgumentType.blockState()` | Block ID | `/setblock <block>` |
| `ColorArgumentType.color()` | Color | `/team color <color>` |
| `Vec3ArgumentType.vec3()` | Vector | `/summon <x> <y> <z>` |

## Registration Pattern

```java
// In ExampleMod.onInitialize():
ModCommands.register();

// common/command/ModCommands.java
public class ModCommands {
    public static void register() {
        CommandRegistrationCallback.EVENT.register((dispatcher, registryAccess, environment) -> {
            // Register ALL commands here
        });
    }
}
```

## Permission Levels

| Level | Access |
|-------|--------|
| 0 | All players (default) |
| 1 | Can bypass spawn protection |
| 2 | Command blocks + OP level 2 (mods, most admin) |
| 3 | OP level 3 (server management) |
| 4 | OP level 4 (full server control) |

Use `.requires(source -> source.hasPermissionLevel(N))` to gate commands.

## Auto-Generated Files

| Component | File |
|-----------|------|
| Command registration | `common/command/ModCommands.java` |
| Main mod registration | `ExampleMod.onInitialize()` → `ModCommands.register()` |

## Common Mistakes

| Symptom | Fix |
|---------|-----|
| Command not found | Ensure `ModCommands.register()` is called in `onInitialize()` |
| "Unknown command" | Command registration must be on server thread, not client |
| Arguments not parsing | Argument order matters — put required before optional |
| Suggestions not working | `.suggests()` must come before `.executes()` in chain |
| Permission not working | `.requires()` must be on the root literal node |
