--[[
    Main.server.lua
    Vstupní bod (Main Entrypoint) pro Roblox Studio Plugin "Roblox AI Assistant".
    Tento skript běží v Roblox Studiu jako plugin, vytváří horní lištu,
    tlačítko, inicializuje okno (DockWidget) a zavádí UI.
]]

-- Zkontrolujeme, zda kód běží v kontextu pluginu
if not plugin then
    return
end

-- Importy ostatních modulů
local Settings = require(script.Parent.Settings)
local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)
local UI = require(script.Parent.UI)

-- Globální proměnné
local toolbar = nil
local toggleButton = nil
local widget = nil

-- Inicializace pluginu
local function initialize()
    print("[Roblox AI Assistant] Inicializuji plugin...")
    
    -- 1. Inicializujeme nastavení perzistence
    Settings.Initialize(plugin)
    
    -- 2. Vytvoření horního panelu nástrojů (Toolbar) v Roblox Studiu
    toolbar = plugin:CreateToolbar("Roblox AI Assistant")
    
    -- 3. Vytvoření spouštěcího tlačítka v panelu nástrojů
    -- Parametry: ID, Popisek při najetí (Tooltip), Cesta k ikoně, Popisek tlačítka
    toggleButton = toolbar:CreateButton(
        "RobloxAI_ToggleBtn",
        "Otevře okno lokálního AI asistenta poháněného Ollamou.",
        "rbxassetid://10723345865", -- Moderní, minimalistická ikona robota/AI
        "AI Assistant"
    )
    
    -- Tlačítko bude klikatelné, i když hra běží
    toggleButton.ClickableWhenViewportHidden = true
    
    -- 4. Vytvoření DockWidgetPluginGui pomocí modulu Widgets
    widget = Widgets.CreateWidget(plugin)
    
    if not widget then
        warn("[Roblox AI Assistant] Chyba: Nepodařilo se vytvořit okno widgetu.")
        return
    end
    
    -- 5. Inicializujeme a vykreslíme uživatelské rozhraní do widgetu
    UI.CreateInterface(widget, plugin)
    
    -- 6. Propojení přepínání tlačítka s viditelností okna
    toggleButton.Click:Connect(function()
        local isEnabled = Widgets.ToggleVisibility()
        toggleButton:SetActive(isEnabled)
    end)
    
    -- Sledování stavu, kdy uživatel zavře widget křížkem
    widget:GetPropertyChangedSignal("Enabled"):Connect(function()
        toggleButton:SetActive(widget.Enabled)
    end)
    
    -- Nastavení stavu tlačítka na základě výchozího stavu widgetu
    toggleButton:SetActive(widget.Enabled)
    
    print("[Roblox AI Assistant] Plugin úspěšně načten a připraven k použití!")
end

-- Bezpečné spuštění inicializace
local success, err = pcall(initialize)
if not success then
    warn("[Roblox AI Assistant] Kritická chyba při spouštění pluginu: " .. tostring(err))
end
