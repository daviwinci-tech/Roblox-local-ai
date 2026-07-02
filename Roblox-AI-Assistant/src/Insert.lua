--[[
    Insert.lua
    Zajišťuje vložení vygenerovaného kódu do Roblox Studia.
    Pokud je vybrán nějaký skript (Script, LocalScript, ModuleScript), přepíše nebo doplní jeho Source.
    Pokud není vybráno nic, vytvoří nový Script v aktuálním kontextu a nastaví ho jako aktivní výběr.
]]

local Selection = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local Insert = {}

-- Pomocná funkce k detekci, zda je objekt skriptem
local function isScript(instance)
    return instance and (instance:IsA("Script") or instance:IsA("LocalScript") or instance:IsA("ModuleScript"))
end

-- Vyčistí kód od případných markdown bloků ```lua ... ```
function Insert.CleanMarkdown(code)
    if not code then return "" end
    
    -- Najde začátek bloku ```lua nebo ```
    local cleanCode = code
    local startIdx, endIdx = string.find(cleanCode, "^%s*```[Ll]ua")
    if startIdx then
        cleanCode = string.sub(cleanCode, endIdx + 1)
    else
        startIdx, endIdx = string.find(cleanCode, "^%s*```")
        if startIdx then
            cleanCode = string.sub(cleanCode, endIdx + 1)
        end
    end
    
    -- Najde konec bloku ```
    local lastIdx = string.find(cleanCode, "```%s*$")
    if lastIdx then
        cleanCode = string.sub(cleanCode, 1, lastIdx - 1)
    end
    
    -- Odstraní úvodní a koncové prázdné znaky
    cleanCode = string.gsub(cleanCode, "^%s*(.-)%s*$", "%1")
    
    return cleanCode
end

-- Vloží kód do vybraného nebo nově vytvořeného skriptu
function Insert.InsertIntoStudio(rawCode)
    local codeToInsert = Insert.CleanMarkdown(rawCode)
    if codeToInsert == "" then
        warn("[Roblox AI Assistant] Pokus o vložení prázdného kódu.")
        return false
    end
    
    local currentSelection = Selection:Get()
    local targetScript = nil
    
    -- Hledáme první skript v aktuálním výběru
    for _, item in ipairs(currentSelection) do
        if isScript(item) then
            targetScript = item
            break
        end
    end
    
    -- Pokud skript není vybrán, vytvoříme nový
    if not targetScript then
        -- Pokusíme se najít rozumného rodiče (např. vybranou složku, nebo Workspace)
        local parent = workspace
        if #currentSelection > 0 then
            local possibleParent = currentSelection[1]
            if possibleParent:IsA("Folder") or possibleParent:IsA("Model") or possibleParent:IsA("ServerScriptService") or possibleParent:IsA("ReplicatedStorage") then
                parent = possibleParent
            end
        end
        
        -- Rozhodneme se pro ServerScriptService pro herní skripty, nebo Workspace jako výchozí
        if parent == workspace and game:GetService("ServerScriptService") then
            parent = game:GetService("ServerScriptService")
        end
        
        -- Vytvoření skriptu
        local success, newScript = pcall(function()
            local s = Instance.new("Script")
            s.Name = "AIScript"
            s.Source = "-- Vygenerováno pomocí Roblox AI Assistant\n\n"
            s.Parent = parent
            return s
        end)
        
        if success and newScript then
            targetScript = newScript
            Selection:Set({targetScript})
        else
            warn("[Roblox AI Assistant] Selhalo vytvoření nového skriptu.")
            return false
        end
    end
    
    -- Zapsání kódu do skriptu s podporou Undo (Zpět)
    if targetScript then
        local success, err = pcall(function()
            -- Nastavení historie pro možnost stisknout Ctrl+Z
            ChangeHistoryService:SetWaypoint("BeforeAIInsert")
            
            -- Zapíšeme kód
            targetScript.Source = codeToInsert
            
            ChangeHistoryService:SetWaypoint("AfterAIInsert")
        end)
        
        if success then
            print("[Roblox AI Assistant] Kód byl úspěšně vložen do skriptu: " .. targetScript:GetFullName())
            return true, targetScript
        else
            warn("[Roblox AI Assistant] Selhal zápis do skriptu: " .. tostring(err))
            return false
        end
    end
    
    return false
end

return Insert
