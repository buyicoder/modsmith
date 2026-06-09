# ModFactory

Claude Code plugin for modular, progressive Minecraft mod development. One master skill orchestrates specialized sub-skills to generate complete, compilable mod projects from natural language descriptions.

## Quick Start

```
/mc-mod-master Create a ruby sword with lightning power
```

The master skill automatically:
1. Parses your intent (item type, features, visual style)
2. Dispatches to texture-generator, item-generator, etc.
3. Assembles all files into a complete mod project
4. Provides build instructions

## Architecture

```
mc-mod-master (orchestrator)
+-- texture-generator    <- PNG textures via GearFactory
+-- item-generator       <- Java + JSON for items/tools/armor
+-- block-generator      <- Java + JSON for blocks
+-- entity-generator     <- mobs, bosses, pets
+-- gameplay-generator   <- skills, quests, economy
```

## Entity Pipeline

ModFactory can run a closed-loop entity pipeline:

```text
idea -> blueprint -> Blockbench assets -> asset contract -> Fabric code -> integrity check -> build -> runClient QA
```

See `docs/entity-pipeline.md`.

## Phase Status

| Phase | Skills | Status |
|------|--------|--------|
| 1 | master, texture, item, block | V1.0 |
| 2 | entity | Active |
| 3 | gameplay | Planned |

## Requirements

- Claude Code with skill support
- Java 21+ (for Minecraft 1.21+)
- [GearFactory](https://github.com/buyicoder/GearFactory) engine (for texture generation)
- [fabric-mc-mod-development](https://github.com/buyicoder/modfactory) skill (API reference)

## License

MIT
