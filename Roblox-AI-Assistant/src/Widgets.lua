--[[
    Widgets.lua
    Vytváří a spravuje DockWidgetPluginGui v Roblox Studiu.
    Toto okno bude obsahovat celé grafické uživatelské rozhraní AI Assistanta.
]]

local Widgets = {}

local widgetInstance = nil

-- Inicializuje a vrátí instanci DockWidgetPluginGui
function Widgets.CreateWidget(plugin)
    if widgetInstance then
        return widgetInstance
    end
    
    local widgetId = "RobloxAIAssistant_DockWidget"
    
    -- Definice chování a počáteční velikosti okna
    local widgetInfo = DockWidgetPluginGuiInfo.new(
        Enum.InitialDockState.Left,  -- Výchozí ukotvení vlevo
        false,                       -- Inicializovat jako skryté (uživatel otevře tlačítkem)
        false,                       -- Neukládat předchozí stav (vynutit výchozí chování)
        300,                         -- Výchozí šířka
        600,                         -- Výchozí výška
        250,                         -- Minimální šířka
        400                          -- Minimální výška
    )
    
    -- Vytvoření samotného widgetu v Roblox Studiu
    local success, widget = pcall(function()
        local w = plugin:CreateDockWidgetPluginGui(widgetId, widgetInfo)
        w.Title = "Roblox AI Assistant"
        w.Name = "RobloxAIAssistantWidget"
        return w
    end)
    
    if success and widget then
        widgetInstance = widget
        return widgetInstance
    else
        warn("[Roblox AI Assistant] Selhalo vytvoření DockWidgetPluginGui: " .. tostring(widget))
        return nil
    end
end

-- Vrátí aktuální instanci widgetu (pokud existuje)
function Widgets.GetWidget()
    return widgetInstance
end

-- Přepne viditelnost widgetu
function Widgets.ToggleVisibility()
    if widgetInstance then
        widgetInstance.Enabled = not widgetInstance.Enabled
        return widgetInstance.Enabled
    end
    return false
end

-- Nastaví viditelnost widgetu
function Widgets.SetVisible(visible)
    if widgetInstance then
        widgetInstance.Enabled = visible
    end
end

return Widgets
