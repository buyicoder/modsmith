# ModFactory Entity Pipeline

The entity pipeline turns a mob idea into verified Fabric files.

## Flow

1. Design blueprint with `entity-design-expert`.
2. Export official or Blockbench reference assets.
3. Write `models/<entity>.contract.json`.
4. Retheme texture without changing UV dimensions.
5. Adapt Java model and renderer.
6. Generate entity code, spawn egg, loot, lang, and resources.
7. Run `scripts/integrity-check.ps1`.
8. Run `gradlew build`.
9. Run `gradlew runClient`.
10. Verify the entity in-game.

## Commands

```powershell
powershell -File scripts\export-bbmodel-assets.ps1 -BbmodelPath models\iron_golem_official.bbmodel -ProjectDir . -EntityName dark_iron_golem -ModId modid
powershell -File scripts\validate-entity-assets.ps1 -ProjectDir . -ContractPath models\dark_iron_golem.contract.json
powershell -File scripts\integrity-check.ps1 -ProjectDir .
```
