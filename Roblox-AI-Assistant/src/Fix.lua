--[[
    Fix.lua
    Modul pro opravu vybraného Roblox Lua skriptu.
    Načte kód z aktuálně otevřeného/vybraného skriptu, odešle ho na analýzu a opravu do AI
    a následně vrátí nebo vloží opravenou verzi.
]]

local Selection = game:GetService("Selection")
local Api = require(script.Parent.Api)
local Insert = require(script.Parent.Insert)

local Fix = {}

-- Detekuje, zda je vybraný objekt platným skriptem
local function getSelectedScript()
    local currentSelection = Selection:Get()
    for _, item in ipairs(currentSelection) do
        if item:IsA("Script") or item:IsA("LocalScript") or item:IsA("ModuleScript") then
            return item
        end
    end
    return nil
end

-- Hlavní funkce pro provedení opravy kódu
function Fix.Execute()
    local targetScript = getSelectedScript()
    if not targetScript then
        return {
            success = false,
            message = "Chyba: Nejprve vyberte skript v okně Explorer (Script, LocalScript nebo ModuleScript)."
        }
    end
    
    local originalCode = targetScript.Source
    if not originalCode or string.gsub(originalCode, "%s+", "") == "" then
        return {
            success = false,
            message = "Chyba: Vybraný skript je prázdný. Není co opravovat."
        }
    end
    
    print("[Roblox AI Assistant] Spouštím opravu skriptu: " .. targetScript.Name)
    
    -- Volání API metody Fix
    local apiResult = Api.Fix(originalCode)
    
    if apiResult.success then
        -- Vyčistíme kód od případného balastu
        local cleanCode = Insert.CleanMarkdown(apiResult.response)
        
        return {
            success = true,
            originalScript = targetScript,
            originalCode = originalCode,
            fixedCode = cleanCode,
            rawResponse = apiResult.response,
            message = "Skript byl úspěšně zanalyzován a opraven!"
        }
    else
        return {
            success = false,
            message = apiResult.message or "Při opravě skriptu došlo k chybě."
        }
    end
end

return Fix
