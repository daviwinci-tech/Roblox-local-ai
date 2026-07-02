--[[
    Explain.lua
    Modul pro vysvětlení vybraného Roblox Lua skriptu krok za krokem.
    Načte kód z aktuálně otevřeného/vybraného skriptu a požádá AI o podrobný rozbor.
]]

local Selection = game:GetService("Selection")
local Api = require(script.Parent.Api)

local Explain = {}

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

-- Hlavní funkce pro spuštění rozboru kódu
function Explain.Execute()
    local targetScript = getSelectedScript()
    if not targetScript then
        return {
            success = false,
            message = "Chyba: Nejprve vyberte skript v okně Explorer (Script, LocalScript nebo ModuleScript)."
        }
    end
    
    local codeToExplain = targetScript.Source
    if not codeToExplain or string.gsub(codeToExplain, "%s+", "") == "" then
        return {
            success = false,
            message = "Chyba: Vybraný skript je prázdný. Není co vysvětlovat."
        }
    end
    
    print("[Roblox AI Assistant] Spouštím podrobný rozbor skriptu: " .. targetScript.Name)
    
    -- Volání API metody Explain
    local apiResult = Api.Explain(codeToExplain)
    
    if apiResult.success then
        return {
            success = true,
            scriptName = targetScript.Name,
            explanation = apiResult.response,
            message = "Vysvětlení bylo úspěšně vygenerováno!"
        }
    else
        return {
            success = false,
            message = apiResult.message or "Při analýze skriptu došlo k chybě."
        }
    end
end

return Explain
