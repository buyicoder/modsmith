# Entity Asset Contract Reference

The entity asset contract is the source of truth between Blockbench assets and Fabric runtime code.

## Required Fields

- `schemaVersion`: currently `1`.
- `entityId`: full namespaced id, e.g. `modid:dark_iron_golem`.
- `reference.source`: vanilla or user reference.
- `texture.path`: Fabric resource path to PNG.
- `texture.width` and `texture.height`: actual PNG dimensions.
- `model.javaPath`: client model Java file.
- `model.textureWidth` and `model.textureHeight`: values passed to `TexturedModelData.of`.
- `model.parts`: expected model part names.
- `renderer.javaPath`: renderer file.
- `renderer.textureIdentifier`: identifier returned by renderer.
- `runtime.entityTypeField`: registry field name.
- `runtime.dimensions`: `EntityType.Builder.dimensions(width, height)`.
- `runtime.spawnEgg`: spawn egg id.
- `animations`: stable clip names generated in Blockbench.

## Invariant

The PNG dimensions, Java model texture dimensions, and Blockbench resolution must match.
