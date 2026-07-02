--[[
    Theme.lua
    Zajišťuje barevné sladění rozhraní s Roblox Studio tématem (Dark / Light).
    Poskytuje paletu barev, která se automaticky aktualizuje podle nastavení Studia.
]]

local Theme = {}

local StudioSettings = nil
local success, err = pcall(function()
    StudioSettings = settings()
end)

-- Výchozí tmavá paleta pro případ, že kód neběží přímo v Roblox Studiu
local DefaultDarkPalette = {
    Background = Color3.fromRGB(36, 36, 36),        -- Hlavní pozadí panelu
    CardBackground = Color3.fromRGB(45, 45, 45),    -- Pozadí textových polí a zpráv
    HeaderBackground = Color3.fromRGB(30, 30, 30),  -- Pozadí hlavičky
    
    Text = Color3.fromRGB(240, 240, 240),            -- Hlavní text
    SubText = Color3.fromRGB(160, 160, 160),         -- Popisky a vedlejší text
    
    Accent = Color3.fromRGB(0, 162, 255),           -- Akcentní barva (Roblox modrá)
    AccentHover = Color3.fromRGB(50, 180, 255),      -- Hover efekt pro akcent
    
    Border = Color3.fromRGB(55, 55, 55),            -- Ohraničení prvků
    
    Button = Color3.fromRGB(50, 50, 50),            -- Pozadí standardního tlačítka
    ButtonHover = Color3.fromRGB(65, 65, 65),       -- Hover pro tlačítko
    ButtonText = Color3.fromRGB(255, 255, 255),      -- Text na tlačítku
    
    -- Barvy zpráv (ChatGPT styl)
    UserBubble = Color3.fromRGB(53, 55, 64),        -- Bublina uživatele
    AIBubble = Color3.fromRGB(68, 70, 84),          -- Bublina asistenta
    CodeBackground = Color3.fromRGB(30, 30, 30),    -- Pozadí bloku kódu
}

local DefaultLightPalette = {
    Background = Color3.fromRGB(245, 245, 245),
    CardBackground = Color3.fromRGB(255, 255, 255),
    HeaderBackground = Color3.fromRGB(230, 230, 230),
    
    Text = Color3.fromRGB(33, 33, 33),
    SubText = Color3.fromRGB(110, 110, 110),
    
    Accent = Color3.fromRGB(0, 132, 255),
    AccentHover = Color3.fromRGB(40, 150, 255),
    
    Border = Color3.fromRGB(220, 220, 220),
    
    Button = Color3.fromRGB(235, 235, 235),
    ButtonHover = Color3.fromRGB(220, 220, 220),
    ButtonText = Color3.fromRGB(33, 33, 33),
    
    UserBubble = Color3.fromRGB(240, 242, 245),
    AIBubble = Color3.fromRGB(255, 255, 255),
    CodeBackground = Color3.fromRGB(240, 240, 240),
}

-- Detekuje, zda Studio běží v tmavém režimu
function Theme.IsDarkTheme()
    if StudioSettings then
        local studioTheme = StudioSettings.Studio.Theme
        if studioTheme then
            -- Název tématu obsahuje "Dark" nebo "Tmavé"
            return string.find(string.lower(studioTheme.Name), "dark") ~= nil
        end
    end
    return true -- Výchozí je tmavý režim
end

-- Vrátí aktuální barevnou paletu
function Theme.GetColors()
    if Theme.IsDarkTheme() then
        -- Pokud běžíme ve Studiu, získáme některé barvy přímo ze Studio Theme API
        if StudioSettings then
            local studioTheme = StudioSettings.Studio.Theme
            local palette = {}
            for k, v in pairs(DefaultDarkPalette) do
                palette[k] = v
            end
            
            -- Přepsání nativními barvami pro 100% integraci
            pcall(function()
                palette.Background = studioTheme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
                palette.CardBackground = studioTheme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground)
                palette.Border = studioTheme:GetColor(Enum.StudioStyleGuideColor.Border)
                palette.Text = studioTheme:GetColor(Enum.StudioStyleGuideColor.MainText)
                palette.SubText = studioTheme:GetColor(Enum.StudioStyleGuideColor.DimmedText)
                palette.Button = studioTheme:GetColor(Enum.StudioStyleGuideColor.Button)
                palette.ButtonHover = studioTheme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Hover)
                palette.ButtonText = studioTheme:GetColor(Enum.StudioStyleGuideColor.ButtonText)
            end)
            return palette
        else
            return DefaultDarkPalette
        end
    else
        if StudioSettings then
            local studioTheme = StudioSettings.Studio.Theme
            local palette = {}
            for k, v in pairs(DefaultLightPalette) do
                palette[k] = v
            end
            
            pcall(function()
                palette.Background = studioTheme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
                palette.CardBackground = studioTheme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground)
                palette.Border = studioTheme:GetColor(Enum.StudioStyleGuideColor.Border)
                palette.Text = studioTheme:GetColor(Enum.StudioStyleGuideColor.MainText)
                palette.SubText = studioTheme:GetColor(Enum.StudioStyleGuideColor.DimmedText)
                palette.Button = studioTheme:GetColor(Enum.StudioStyleGuideColor.Button)
                palette.ButtonHover = studioTheme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Hover)
                palette.ButtonText = studioTheme:GetColor(Enum.StudioStyleGuideColor.ButtonText)
            end)
            return palette
        else
            return DefaultLightPalette
        end
    end
end

-- Poskytuje událost pro změnu tématu
function Theme.OnThemeChanged(callback)
    if StudioSettings then
        return StudioSettings.Studio.ThemeChanged:Connect(function()
            callback(Theme.GetColors())
        end)
    end
    return nil
end

return Theme
