--[[
    Settings.lua
    Spravuje perzistentní nastavení Roblox AI Assistanta v Roblox Studiu.
    Umožňuje měnit cílový model a konfigurovat adresu bridge.
]]

local Settings = {}

-- Výchozí hodnoty
local DEFAULT_MODEL = "qwen2.5-coder:14b"
local DEFAULT_BRIDGE_URL = "http://127.0.0.1:5000"

-- Lokální cache pro případ, že plugin API není dostupné (např. při testování)
local localCache = {
    Model = DEFAULT_MODEL,
    BridgeUrl = DEFAULT_BRIDGE_URL
}

local pluginInstance = nil

-- Inicializuje nastavení s instancí pluginu pro možnost uložení přes plugin:SetSetting()
function Settings.Initialize(plugin)
    pluginInstance = plugin
    if pluginInstance then
        -- Pokus o načtení uložených hodnot
        local success, savedModel = pcall(function()
            return pluginInstance:GetSetting("RobloxAI_Model")
        end)
        if success and savedModel then
            localCache.Model = savedModel
        end

        local success2, savedUrl = pcall(function()
            return pluginInstance:GetSetting("RobloxAI_BridgeUrl")
        end)
        if success2 and savedUrl then
            localCache.BridgeUrl = savedUrl
        end
    end
end

-- Vrátí aktuální model Ollamy
function Settings.GetModel()
    return localCache.Model or DEFAULT_MODEL
end

-- Nastaví nový model Ollamy a perzistentně ho uloží
function Settings.SetModel(modelName)
    localCache.Model = modelName
    if pluginInstance then
        pcall(function()
            pluginInstance:SetSetting("RobloxAI_Model", modelName)
        end)
    end
end

-- Vrátí aktuální adresu Flask bridge
function Settings.GetBridgeUrl()
    return localCache.BridgeUrl or DEFAULT_BRIDGE_URL
end

-- Nastaví novou adresu Flask bridge a perzistentně ji uloží
function Settings.SetBridgeUrl(url)
    localCache.BridgeUrl = url
    if pluginInstance then
        pcall(function()
            pluginInstance:SetSetting("RobloxAI_BridgeUrl", url)
        end)
    end
end

-- Seznam podporovaných doporučených modelů pro nastavení UI
function Settings.GetRecommendedModels()
    return {
        "qwen2.5-coder:14b",
        "qwen2.5-coder:7b",
        "qwen2.5-coder:1.5b",
        "deepseek-coder",
        "llama3",
        "codellama"
    }
end

return Settings
