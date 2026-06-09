---
name: texture-ai-generator
description: Use when the user needs NEW item textures with novel shapes, AI-generated pixel art, or textures for items that don't have vanilla equivalents. Triggers on: "generate a new shape", "create a unique texture", "AI texture", "novel weapon shape", "custom item look", or dispatched by mc-mod-master when GearFactory can't handle the request.
---

# Texture AI Generator (minecraft-ai + Pixel GPT)

## Overview

Generates novel Minecraft item textures using AI models. Complements GearFactory (which excels at recoloring existing shapes). Use when the user needs entirely NEW shapes that don't exist in vanilla Minecraft.

**GearFactory vs Texture AI:**
| Scenario | GearFactory | Texture AI |
|----------|------------|------------|
| "Red sword like diamond but red" | ✅ Best | ⚠️ Overkill |
| "Curved scimitar sword" | ❌ No shape exists | ✅ Generates new shape |
| "Robot chestplate" | ❌ | ✅ Generates new design |
| "Mushroom staff" | ❌ | ✅ Generates from scratch |

## Tools

### 1. minecraft-ai (Jhon-crypt) — Local PyTorch

**Setup:**
```bash
git clone https://github.com/Jhon-crypt/minecraft-ai tools/minecraft-ai
cd tools/minecraft-ai
pip install torch torchvision pillow numpy
```

**Usage:**
```python
# Generate a texture from text prompt
from src.minecraft_ai_generator.texture_generator import generate_texture
generate_texture("a legendary ruby sword with golden hilt", output="ruby_sword_legendary.png")
```

**Output:** 16×16 PNG with transparent background.

**Limitations:**
- Requires GPU for fast generation (CPU works but slow)
- Pre-trained model generates Minecraft-styled items but may need fine-tuning
- 16×16 only (not 64×32 armor textures)

### 2. Pixel GPT — Web API

**Setup:** No installation needed. Web-based at pixelgpt.ai or desktop app.

**Usage via web:**
1. Describe the item: "Thunder sword with yellow lightning blade and dark handle"
2. Download generated 16×16 PNG
3. Place in ModFactory project at `textures/item/thunder_sword.png`

**Limitations:**
- Requires internet connection
- Free tier has limited generations

### 3. Deep Pixels — Web API

**Setup:** No installation. Web-based at stackviv.ai/ai-tools/ai-mc-texture.

**Best for:** Quick prototyping, batch generation of multiple texture variants.

## Generation Pipeline

```
User: "Create a scimitar sword with ruby blade"

1. texture-ai-generator receives request
2. Choose tool:
   - Local GPU available? → minecraft-ai
   - No GPU? → Pixel GPT (web)
3. Generate prompt: "curved scimitar sword, ruby red blade, gold crossguard, dark leather wrapped handle, minecraft style 16x16 pixel art"
4. Generate texture PNG
5. Validate: 16×16, PNG, transparent background
6. Place in project: assets/MODID/textures/item/scimitar.png
7. If needed, use GearFactory for palette matching armor set
```

## Integration with GearFactory

```
User wants: "Ruby scimitar + full armor set to match"

Step 1: texture-ai-generator → scimitar texture (new shape)
Step 2: GearFactory → ruby palette → helmet/chestplate/leggings/boots (recolor vanilla)
Step 3: All textures share the same ruby color palette for consistency
```

## AI Prompt Template

For best results with Pixel GPT or minecraft-ai:
```
"[item description], [material] [color], [style details], minecraft style 16x16 pixel art, transparent background, [view angle]"
```

Examples:
- "curved scimitar sword, ruby red blade with gold trim, dark leather handle, minecraft style 16x16 pixel art"
- "robot helmet, silver metal plates, glowing blue visor, minecraft style 16x16 pixel art"
- "nature staff, twisted wood with emerald crystal top, green glow, minecraft style 16x16 pixel art"

## Common Issues

| Issue | Fix |
|-------|-----|
| AI texture doesn't look Minecraft-like | Add "minecraft style 16x16 pixel art" to prompt |
| AI texture has background | Post-process with PowerShell to remove background |
| AI shape wrong | Generate multiple and pick best, or provide more specific prompt |
| GPU out of memory (minecraft-ai) | Reduce batch size or use CPU mode |
