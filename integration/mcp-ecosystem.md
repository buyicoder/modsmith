# ModFactory MCP Integration Guide

## Integrated MCP Servers

ModFactory v3.1 integrates with the following external MCP servers for enhanced accuracy:

| MCP Server | NPM | Tools | What It Gives ModFactory |
|-----------|-----|-------|----------------------|
| **mcdev-mcp** | `@mcdxai/minecraft-dev-mcp` | 20 | Live MC source code, method signatures, Mixin validation |
| **mcmodding-mcp** | `mcmodding-mcp` | 6 | Official Fabric/NeoForge docs, mappings, examples |

## Install

### mcdev-mcp (Source Code Access)
```json
// .claude/settings.local.json
{
  "mcpServers": {
    "minecraft-dev": {
      "command": "npx",
      "args": ["-y", "@mcdxai/minecraft-dev-mcp"]
    }
  }
}
```

### mcmodding-mcp (Documentation Search)
```json
{
  "mcpServers": {
    "mcmodding": {
      "command": "npx",
      "args": ["-y", "mcmodding-mcp"]
    }
  }
}
```

## How ModFactory Uses MCPs

```
mc-mod-master generates code
    │
    ├── Need API verification?
    │   → mcdev-mcp: get_minecraft_source("LivingEntity.java")
    │   → Verify method signatures before generating Mixin
    │
    ├── Need documentation?
    │   → mcmodding-mcp: search_fabric_docs("entity registration")
    │   → Get official API reference
    │
    └── Code generated → build → auto-fix
```

## Integration Points

### 1. Method Signature Verification
When generating Mixin or custom item classes, ModFactory queries mcdev-mcp for the EXACT method signature in the target MC version. This eliminates "Invalid descriptor" errors.

```
Before (no MCP): "try getWorld() or getEntityWorld() — guess and fix"
After (with MCP): mcdev-mcp returns "Entity.getEntityWorld()" → generate correct code
```

### 2. API Change Detection  
When upgrading a mod between MC versions, mcdev-mcp's `compare_versions` tool identifies API changes that would break the mod.

### 3. Mixin Target Validation
Before compiling, mcdev-mcp's `analyze_mixin` tool validates all @Mixin annotations against the actual class structure.

### 4. Documentation Reference
mcmodding-mcp provides real-time Fabric API documentation, replacing guesswork with official references.

## Fallback Behavior

If MCP servers are unavailable, ModFactory falls back to its built-in knowledge:
- `fabric-mc-mod-development` skill (Yarn/Mojang mappings)
- `mod-analyzer` knowledge base (5 classic mod patterns)
- `auto-fix` error pattern database (14 patterns)

```java
// MCP-aware generation pseudocode
if (mcdevMCP_available()) {
    // Use live source for 100% accuracy
    String methodSig = mcdevMCP.getMethodSignature("LivingEntity", "damage");
    generateMixinWithCorrectSignature(methodSig);
} else {
    // Fallback to hardcoded knowledge
    generateMixinWithKnownSignature("damage(ServerWorld, DamageSource, float)");
}
```

## Blockbench MCP (3D Modeling + Texturing)

**Status:** ✅ Connected — Blockbench MCP active on localhost:3000

**Setup (completed):**
1. Blockbench installed: `~/AppData/Local/Programs/Blockbench/`
2. Plugin: `jasonjgardner/blockbench-mcp-plugin` loaded → `D:/MC/blockbench-mcp-plugin/dist/mcp.js`
3. MCP endpoint: `http://localhost:3000/bb-mcp`
4. Claude Code connected: `claude mcp add blockbench --transport http http://localhost:3000/bb-mcp`

**Available MCP tools:** model creation/edit, texture manipulation, UV mapping, animation, screenshot
**11 built-in prompts:** bedrock_block, hytale_model_creation, java_block, model_creation_geometry, etc.

**Integration:** Used by `entity-designer` for professional entity model generation. Claude can now directly create/edit Blockbench models.
