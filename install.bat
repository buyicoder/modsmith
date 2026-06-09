@echo off
echo ========================================
echo  ModFactory v3.1 — One-Click Install
echo ========================================
echo.

echo [1/4] Installing mcdev-mcp (Minecraft source access)...
call npm install -g @mcdxai/minecraft-dev-mcp 2>nul
if %errorlevel% equ 0 (
    echo   [OK] mcdev-mcp installed
) else (
    echo   [SKIP] npm not available — mcdev-mcp skipped
)

echo [2/4] Installing mcmodding-mcp (Fabric docs)...
call npm install -g mcmodding-mcp 2>nul
if %errorlevel% equ 0 (
    echo   [OK] mcmodding-mcp installed
) else (
    echo   [SKIP] npm not available — mcmodding-mcp skipped
)

echo [3/4] Installing GearFactory engine...
if exist "forge_engine" (
    echo   [OK] GearFactory already present
) else (
    echo   [INFO] Clone from https://github.com/buyicoder/GearFactory
    git clone https://github.com/buyicoder/GearFactory.git forge_engine 2>nul
    if %errorlevel% equ 0 (
        echo   [OK] GearFactory installed
    ) else (
        echo   [SKIP] git not available — install manually
    )
)

echo [4/4] Configuring MCP servers...
if not exist ".claude" mkdir .claude
if exist ".claude\settings.local.json" (
    echo   [SKIP] settings.local.json already exists
) else (
    echo { > .claude\settings.local.json
    echo   "mcpServers": { >> .claude\settings.local.json
    echo     "minecraft-dev": { >> .claude\settings.local.json
    echo       "command": "npx", >> .claude\settings.local.json
    echo       "args": ["-y", "@mcdxai/minecraft-dev-mcp"] >> .claude\settings.local.json
    echo     }, >> .claude\settings.local.json
    echo     "mcmodding": { >> .claude\settings.local.json
    echo       "command": "npx", >> .claude\settings.local.json
    echo       "args": ["-y", "mcmodding-mcp"] >> .claude\settings.local.json
    echo     } >> .claude\settings.local.json
    echo   } >> .claude\settings.local.json
    echo } >> .claude\settings.local.json
    echo   [OK] MCP config created
)

echo.
echo ========================================
echo  Install Complete!
echo ========================================
echo.
echo  ModFactory skills: 17 (auto-loaded)
echo  MCP servers: mcdev-mcp + mcmodding-mcp
echo  GearFactory: texture engine
echo  Architecture: 5 patterns from classic mods
echo.
echo  Usage: Just describe your mod idea!
echo  "Create a thunder sword that summons lightning"
echo.
pause
