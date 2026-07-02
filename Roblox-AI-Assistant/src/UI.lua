--[[
    UI.lua
    Vytváří grafické uživatelské rozhraní (GUI) ve stylu ChatGPT.
    Používá moderní prvky jako UICorner, UIStroke, UIPadding a automatické rolování.
    Propojuje akce tlačítek s moduly Api, Insert, Fix, Explain a Settings.
]]

local HttpService = game:GetService("HttpService")
local Theme = require(script.Parent.Theme)
local Api = require(script.Parent.Api)
local Insert = require(script.Parent.Insert)
local Fix = require(script.Parent.Fix)
local Explain = require(script.Parent.Explain)
local Settings = require(script.Parent.Settings)

local UI = {}

-- Globální reference pro interakci
local mainFrame = nil
local chatScroll = nil
local promptInput = nil
local generateBtn = nil
local fixBtn = nil
local explainBtn = nil
local insertBtn = nil
local copyBtn = nil
local settingsBtn = nil
local settingsPanel = nil
local modelInput = nil
local urlInput = nil
local statusLabel = nil

local isGenerating = false
local lastAIResponseText = ""
local messagesHistory = {} -- Historie zpráv pro uchování kontextu v chat endpointu

-- Pomocná funkce pro vytvoření UICorner
local function addCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = parent
    return corner
end

-- Pomocná funkce pro vytvoření UIStroke (ohraničení)
local function addStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(100, 100, 100)
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

-- Pomocná funkce pro vytvoření UIPadding
local function addPadding(parent, top, bottom, left, right)
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, top or 0)
    padding.PaddingBottom = UDim.new(0, bottom or 0)
    padding.PaddingLeft = UDim.new(0, left or 0)
    padding.PaddingRight = UDim.new(0, right or 0)
    padding.Parent = parent
    return padding
end

-- Pomocná funkce pro vytvoření textového tlačítka s hover efektem
local function createButton(name, text, size, position, parent, colors, onClick)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = colors.Button
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = colors.ButtonText
    button.Font = Enum.Font.SourceSans
    button.TextSize = 14
    button.Parent = parent
    
    addCorner(button, 5)
    local stroke = addStroke(button, colors.Border, 1)
    
    button.MouseButton1Click:Connect(function()
        if not isGenerating then
            onClick()
        end
    end)
    
    -- Hover a stisknutí efekty
    button.MouseEnter:Connect(function()
        if not isGenerating then
            button.BackgroundColor3 = colors.ButtonHover
        end
    end)
    
    button.MouseLeave:Connect(function()
        if not isGenerating then
            button.BackgroundColor3 = colors.Button
        end
    end)
    
    return button, stroke
end

-- Přidá bublinu do chatu (Uživatel / AI)
local function addChatBubble(sender, text, colors)
    local bubbleFrame = Instance.new("Frame")
    bubbleFrame.Name = sender .. "Bubble"
    bubbleFrame.Size = UDim2.new(1, 0, 0, 0) -- Výška se přizpůsobí textu
    bubbleFrame.BorderSizePixel = 0
    bubbleFrame.BackgroundTransparency = 0
    
    if sender == "User" then
        bubbleFrame.BackgroundColor3 = colors.UserBubble
    elseif sender == "System" then
        bubbleFrame.BackgroundColor3 = colors.Background
    else
        bubbleFrame.BackgroundColor3 = colors.AIBubble
    end
    
    addPadding(bubbleFrame, 8, 8, 12, 12)
    
    -- Rozvržení obsahu
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 4)
    listLayout.Parent = bubbleFrame
    
    -- Popisek odesílatele
    local senderLabel = Instance.new("TextLabel")
    senderLabel.Size = UDim2.new(1, 0, 0, 16)
    senderLabel.BackgroundTransparency = 1
    
    if sender == "User" then
        senderLabel.Text = "VY"
        senderLabel.TextColor3 = colors.Accent
    elseif sender == "System" then
        senderLabel.Text = "SYSTÉM"
        senderLabel.TextColor3 = Color3.fromRGB(220, 100, 100)
    else
        senderLabel.Text = "AI ASISTENT (" .. Settings.GetModel() .. ")"
        senderLabel.TextColor3 = Color3.fromRGB(80, 200, 120)
    end
    
    senderLabel.Font = Enum.Font.SourceSansBold
    senderLabel.TextSize = 12
    senderLabel.TextXAlignment = Enum.TextXAlignment.Left
    senderLabel.Parent = bubbleFrame
    
    -- Samotný text zprávy
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, 0, 0, 0)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = text
    messageLabel.TextColor3 = colors.Text
    messageLabel.Font = (sender == "User" or sender == "System") and Enum.Font.SourceSans or Enum.Font.Code
    messageLabel.TextSize = 13
    messageLabel.TextWrapped = true
    messageLabel.RichText = true
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.AutomaticSize = Enum.AutomaticSize.Y
    messageLabel.Parent = bubbleFrame
    
    bubbleFrame.AutomaticSize = Enum.AutomaticSize.Y
    bubbleFrame.Parent = chatScroll
    
    -- Automatické scrollování dolů po přidání bubliny
    task.spawn(function()
        task.wait(0.05)
        chatScroll.CanvasPosition = Vector2.new(0, chatScroll.AbsoluteCanvasSize.Y)
    end)
end

-- Vyčistí historii chatu
local function clearChat()
    for _, child in ipairs(chatScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    chatScroll.CanvasPosition = Vector2.new(0, 0)
    lastAIResponseText = ""
    messagesHistory = {}
    
    if insertBtn then insertBtn.Visible = false end
    if copyBtn then copyBtn.Visible = false end
    
    local colors = Theme.GetColors()
    addChatBubble("AI", "Historie konverzace byla vymazána. Jak ti mohu dnes pomoci s Roblox Luau?", colors)
end

-- Simuluje postupné vypisování textu ("typewriter" efekt) pro pocit reálného streamování z AI!
local function simulateStreamingText(sender, fullText, colors)
    local bubbleFrame = Instance.new("Frame")
    bubbleFrame.Name = sender .. "Bubble"
    bubbleFrame.Size = UDim2.new(1, 0, 0, 0)
    bubbleFrame.BorderSizePixel = 0
    bubbleFrame.BackgroundColor3 = colors.AIBubble
    addPadding(bubbleFrame, 8, 8, 12, 12)
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 4)
    listLayout.Parent = bubbleFrame
    
    local senderLabel = Instance.new("TextLabel")
    senderLabel.Size = UDim2.new(1, 0, 0, 16)
    senderLabel.BackgroundTransparency = 1
    senderLabel.Text = "AI ASISTENT (" .. Settings.GetModel() .. ")"
    senderLabel.TextColor3 = Color3.fromRGB(80, 200, 120)
    senderLabel.Font = Enum.Font.SourceSansBold
    senderLabel.TextSize = 12
    senderLabel.TextXAlignment = Enum.TextXAlignment.Left
    senderLabel.Parent = bubbleFrame
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, 0, 0, 0)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = ""
    messageLabel.TextColor3 = colors.Text
    messageLabel.Font = Enum.Font.Code
    messageLabel.TextSize = 13
    messageLabel.TextWrapped = true
    messageLabel.RichText = true
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.AutomaticSize = Enum.AutomaticSize.Y
    messageLabel.Parent = bubbleFrame
    
    bubbleFrame.AutomaticSize = Enum.AutomaticSize.Y
    bubbleFrame.Parent = chatScroll
    
    -- Postupné vypisování slov pro plynulé zobrazení
    task.spawn(function()
        local words = {}
        for word in string.gmatch(fullText, "[^%s]+%s*") do
            table.insert(words, word)
        end
        
        local currentText = ""
        local step = math.max(1, math.floor(#words / 40)) -- Upraví rychlost vypisování u velmi dlouhých zpráv
        
        for i = 1, #words, step do
            local nextLimit = math.min(#words, i + step - 1)
            for j = i, nextLimit do
                currentText = currentText .. words[j]
            end
            messageLabel.Text = currentText
            chatScroll.CanvasPosition = Vector2.new(0, chatScroll.AbsoluteCanvasSize.Y)
            task.wait(0.01)
        end
        
        -- Ujistíme se, že se vypíše 100% textu na konci
        messageLabel.Text = fullText
        chatScroll.CanvasPosition = Vector2.new(0, chatScroll.AbsoluteCanvasSize.Y)
    end)
end

-- Spustí generování / chatování
local function startGeneration(promptText, mode)
    if isGenerating then return end
    if mode == "Generate" and string.gsub(promptText, "%s+", "") == "" then return end
    
    isGenerating = true
    generateBtn.Text = "Odesílám..."
    generateBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    fixBtn.Active = false
    explainBtn.Active = false
    
    local colors = Theme.GetColors()
    
    -- Přidání uživatelského promptu do chatu a historie
    if mode == "Generate" then
        addChatBubble("User", promptText, colors)
        table.insert(messagesHistory, {role = "user", content = promptText})
        promptInput.Text = ""
    elseif mode == "Fix" then
        addChatBubble("User", "🔧 Opravit vybraný skript v Exploreru", colors)
    elseif mode == "Explain" then
        addChatBubble("User", "📖 Vysvětlit vybraný skript v Exploreru", colors)
    end
    
    -- Přidáme dočasnou zprávu o načítání
    local loadingBubble = Instance.new("Frame")
    loadingBubble.Name = "LoadingBubble"
    loadingBubble.Size = UDim2.new(1, 0, 0, 40)
    loadingBubble.BackgroundColor3 = colors.AIBubble
    loadingBubble.BorderSizePixel = 0
    addPadding(loadingBubble, 8, 8, 12, 12)
    
    local loadingText = Instance.new("TextLabel")
    loadingText.Size = UDim2.new(1, 0, 1, 0)
    loadingText.BackgroundTransparency = 1
    loadingText.Text = "Přemýšlím... Odezva z lokální Ollamy..."
    loadingText.TextColor3 = colors.SubText
    loadingText.Font = Enum.Font.SourceSansItalic
    loadingText.TextSize = 13
    loadingText.TextXAlignment = Enum.TextXAlignment.Left
    loadingText.Parent = loadingBubble
    loadingBubble.Parent = chatScroll
    
    task.spawn(function()
        local result
        if mode == "Fix" then
            result = Fix.Execute()
        elseif mode == "Explain" then
            result = Explain.Execute()
        else
            -- Pro standardní chat posíláme celou historii
            result = Api.Chat(messagesHistory)
        end
        
        -- Odstranění načítací bubliny
        loadingBubble:Destroy()
        
        isGenerating = false
        generateBtn.Text = "Generovat"
        generateBtn.BackgroundColor3 = colors.Accent
        fixBtn.Active = true
        explainBtn.Active = true
        
        if result.success then
            local responseText = ""
            if mode == "Fix" then
                responseText = "Zde je opravená verze skriptu:\n\n```lua\n" .. result.fixedCode .. "\n```\n\n" .. (result.message or "")
                lastAIResponseText = result.fixedCode
            elseif mode == "Explain" then
                responseText = result.explanation
                lastAIResponseText = result.explanation
            else
                responseText = result.response
                lastAIResponseText = result.response
                -- Uložíme odpověď AI do historie konverzace
                table.insert(messagesHistory, {role = "assistant", content = responseText})
            end
            
            -- Simulujeme plynulé vykreslení (streamování) pro úžasný UX zážitek!
            simulateStreamingText("AI", responseText, colors)
            
            -- Nastavení viditelnosti tlačítek pro vložení a kopírování
            if mode == "Fix" or string.find(responseText, "```") then
                insertBtn.Visible = true
            else
                insertBtn.Visible = false
            end
            copyBtn.Visible = true
        else
            addChatBubble("AI", "CHYBA: " .. (result.message or "Neznámá chyba komunikace s backendem."), colors)
            insertBtn.Visible = false
            copyBtn.Visible = false
        end
    end)
end

-- Otestuje a aktualizuje stav připojení
local function testConnection()
    if statusLabel then
        statusLabel.Text = "Testuji spojení..."
        statusLabel.TextColor3 = Color3.fromRGB(200, 200, 100)
    end
    
    task.spawn(function()
        local health = Api.CheckHealth()
        local colors = Theme.GetColors()
        
        if statusLabel then
            if health.success then
                if health.ollama_connected then
                    statusLabel.Text = "● PŘIPOJENO K OLLAMĚ"
                    statusLabel.TextColor3 = Color3.fromRGB(80, 200, 120)
                else
                    statusLabel.Text = "● BACKEND BĚŽÍ (Ollama Offline)"
                    statusLabel.TextColor3 = Color3.fromRGB(220, 150, 50)
                end
            else
                statusLabel.Text = "● OFFLINE (Backend neběží)"
                statusLabel.TextColor3 = Color3.fromRGB(220, 100, 100)
            end
        end
        
        -- Přidáme log do chatu o testu připojení
        addChatBubble("System", health.message, colors)
    end)
end

-- Aktualizuje barvy prvků podle aktuálního tématu
local function applyThemeColors(colors)
    mainFrame.BackgroundColor3 = colors.Background
    
    -- Hlavička
    local header = mainFrame:FindFirstChild("Header")
    if header then
        header.BackgroundColor3 = colors.HeaderBackground
        local title = header:FindFirstChild("Title")
        if title then title.TextColor3 = colors.Text end
    end
    
    -- Chat oblast
    chatScroll.BackgroundColor3 = colors.Background
    
    -- Vstupní oblast
    local inputArea = mainFrame:FindFirstChild("InputArea")
    if inputArea then
        inputArea.BackgroundColor3 = colors.HeaderBackground
        local inputFrame = inputArea:FindFirstChild("InputFrame")
        if inputFrame then
            inputFrame.BackgroundColor3 = colors.CardBackground
            inputFrame.UIStroke.Color = colors.Border
            if promptInput then
                promptInput.TextColor3 = colors.Text
                promptInput.PlaceholderColor3 = colors.SubText
            end
        end
        
        -- Tlačítka
        if generateBtn then
            generateBtn.BackgroundColor3 = isGenerating and Color3.fromRGB(100, 100, 100) or colors.Accent
            generateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            generateBtn.UIStroke.Color = colors.Accent
        end
        
        if fixBtn then
            fixBtn.BackgroundColor3 = colors.Button
            fixBtn.TextColor3 = colors.ButtonText
            fixBtn.UIStroke.Color = colors.Border
        end
        
        if explainBtn then
            explainBtn.BackgroundColor3 = colors.Button
            explainBtn.TextColor3 = colors.ButtonText
            explainBtn.UIStroke.Color = colors.Border
        end
        
        if insertBtn then
            insertBtn.BackgroundColor3 = colors.Button
            insertBtn.TextColor3 = colors.ButtonText
            insertBtn.UIStroke.Color = colors.Border
        end
        
        if copyBtn then
            copyBtn.BackgroundColor3 = colors.Button
            copyBtn.TextColor3 = colors.ButtonText
            copyBtn.UIStroke.Color = colors.Border
        end
        
        if settingsBtn then
            settingsBtn.BackgroundColor3 = colors.Button
            settingsBtn.TextColor3 = colors.ButtonText
            settingsBtn.UIStroke.Color = colors.Border
        end
    end
    
    -- Nastavení panel
    if settingsPanel then
        settingsPanel.BackgroundColor3 = colors.CardBackground
        settingsPanel.UIStroke.Color = colors.Border
        local title = settingsPanel:FindFirstChild("Title")
        if title then title.TextColor3 = colors.Text end
        
        local mLabel = settingsPanel:FindFirstChild("ModelLabel")
        if mLabel then mLabel.TextColor3 = colors.Text end
        
        local uLabel = settingsPanel:FindFirstChild("UrlLabel")
        if uLabel then uLabel.TextColor3 = colors.Text end
        
        if urlInput then
            urlInput.BackgroundColor3 = colors.Background
            urlInput.TextColor3 = colors.Text
            urlInput.UIStroke.Color = colors.Border
        end
        
        if modelInput then
            modelInput.BackgroundColor3 = colors.Background
            modelInput.TextColor3 = colors.Text
            modelInput.UIStroke.Color = colors.Border
        end
    end
    
    -- Aktualizovat již existující zprávy v chatu
    for _, bubble in ipairs(chatScroll:GetChildren()) do
        if bubble:IsA("Frame") then
            local isUser = string.find(bubble.Name, "User") ~= nil
            local isSystem = string.find(bubble.Name, "System") ~= nil
            
            if isUser then
                bubble.BackgroundColor3 = colors.UserBubble
            elseif isSystem then
                bubble.BackgroundColor3 = colors.Background
            else
                bubble.BackgroundColor3 = colors.AIBubble
            end
            
            -- Projdeme všechny labely a nastavíme jim správnou barvu
            for _, child in ipairs(bubble:GetChildren()) do
                if child:IsA("TextLabel") then
                    if child.Name == "TextLabel" then
                        child.TextColor3 = colors.Text
                    elseif child.Name == "SenderLabel" then
                        child.TextColor3 = isUser and colors.Accent or (isSystem and Color3.fromRGB(220, 100, 100) or Color3.fromRGB(80, 200, 120))
                    end
                end
            end
        end
    end
end

-- Hlavní inicializační funkce UI
function UI.CreateInterface(parent, plugin)
    local colors = Theme.GetColors()
    
    -- 1. Hlavní kontejner
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "RobloxAI_MainFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundColor3 = colors.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = parent
    
    -- 2. Horní lišta / Hlavička
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 45)
    header.BackgroundColor3 = colors.HeaderBackground
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    addPadding(header, 0, 0, 12, 12)
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0.5, 0, 1, 0)
    title.BackgroundTransparency = 1
    title.Text = "Roblox AI Assistant"
    title.TextColor3 = colors.Text
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    local clearBtn = Instance.new("TextButton")
    clearBtn.Name = "ClearButton"
    clearBtn.Size = UDim2.new(0, 70, 0, 24)
    clearBtn.Position = UDim2.new(1, -70, 0.5, -12)
    clearBtn.BackgroundColor3 = colors.Button
    clearBtn.Text = "Vyčistit"
    clearBtn.TextColor3 = colors.ButtonText
    clearBtn.Font = Enum.Font.SourceSans
    clearBtn.TextSize = 12
    clearBtn.Parent = header
    addCorner(clearBtn, 4)
    addStroke(clearBtn, colors.Border, 1)
    clearBtn.MouseButton1Click:Connect(clearChat)
    
    -- 3. Rolovací plocha pro chat
    chatScroll = Instance.new("ScrollingFrame")
    chatScroll.Name = "ChatScroll"
    chatScroll.Size = UDim2.new(1, 0, 1, -215) -- Rezerva pro zápatí
    chatScroll.Position = UDim2.new(0, 0, 0, 45)
    chatScroll.BackgroundTransparency = 1
    chatScroll.BorderSizePixel = 0
    chatScroll.ScrollBarThickness = 5
    chatScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    chatScroll.CanvasSize = UDim2.new(1, 0, 0, 0)
    chatScroll.Parent = mainFrame
    
    addPadding(chatScroll, 8, 8, 0, 0)
    
    local chatListLayout = Instance.new("UIListLayout")
    chatListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    chatListLayout.Padding = UDim.new(0, 6)
    chatListLayout.Parent = chatScroll
    
    -- 4. Spodní panel (Zadávání promptů a tlačítka)
    local inputArea = Instance.new("Frame")
    inputArea.Name = "InputArea"
    inputArea.Size = UDim2.new(1, 0, 0, 170)
    inputArea.Position = UDim2.new(0, 0, 1, -170)
    inputArea.BackgroundColor3 = colors.HeaderBackground
    inputArea.BorderSizePixel = 0
    inputArea.Parent = mainFrame
    
    addPadding(inputArea, 8, 8, 12, 12)
    
    -- Rámeček pro TextBox (vstup)
    local inputFrame = Instance.new("Frame")
    inputFrame.Name = "InputFrame"
    inputFrame.Size = UDim2.new(1, 0, 0, 70)
    inputFrame.BackgroundColor3 = colors.CardBackground
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = inputArea
    addCorner(inputFrame, 6)
    local inputFrameStroke = addStroke(inputFrame, colors.Border, 1)
    
    promptInput = Instance.new("TextBox")
    promptInput.Name = "PromptInput"
    promptInput.Size = UDim2.new(1, 0, 1, 0)
    promptInput.BackgroundTransparency = 1
    promptInput.Text = ""
    promptInput.PlaceholderText = "Zeptejte se asistenta nebo popište skript, který chcete vytvořit..."
    promptInput.TextColor3 = colors.Text
    promptInput.PlaceholderColor3 = colors.SubText
    promptInput.Font = Enum.Font.SourceSans
    promptInput.TextSize = 13
    promptInput.TextWrapped = true
    promptInput.ClearTextOnFocus = false
    promptInput.MultiLine = true
    promptInput.TextXAlignment = Enum.TextXAlignment.Left
    promptInput.TextYAlignment = Enum.TextYAlignment.Top
    promptInput.Parent = inputFrame
    addPadding(promptInput, 6, 6, 8, 8)
    
    -- Řada tlačítek 1 (Generovat, Opravit, Vysvětlit)
    local btnRow1 = Instance.new("Frame")
    btnRow1.Name = "ButtonRow1"
    btnRow1.Size = UDim2.new(1, 0, 0, 32)
    btnRow1.Position = UDim2.new(0, 0, 0, 78)
    btnRow1.BackgroundTransparency = 1
    btnRow1.Parent = inputArea
    
    local row1Layout = Instance.new("UIListLayout")
    row1Layout.FillDirection = Enum.FillDirection.Horizontal
    row1Layout.SortOrder = Enum.SortOrder.LayoutOrder
    row1Layout.Padding = UDim.new(0, 6)
    row1Layout.Parent = btnRow1
    
    generateBtn = createButton("GenerateBtn", "Generovat", UDim2.new(0.4, -4, 1, 0), UDim2.new(0, 0, 0, 0), btnRow1, colors, function()
        startGeneration(promptInput.Text, "Generate")
    end)
    generateBtn.BackgroundColor3 = colors.Accent
    generateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    fixBtn = createButton("FixBtn", "Opravit skript", UDim2.new(0.3, -4, 1, 0), UDim2.new(0, 0, 0, 0), btnRow1, colors, function()
        startGeneration("Opravit vybraný skript", "Fix")
    end)
    
    explainBtn = createButton("ExplainBtn", "Vysvětlit", UDim2.new(0.3, -4, 1, 0), UDim2.new(0, 0, 0, 0), btnRow1, colors, function()
        startGeneration("Vysvětlit vybraný skript", "Explain")
    end)
    
    -- Řada tlačítek 2 (Kopírovat, Vložit, Nastavení)
    local btnRow2 = Instance.new("Frame")
    btnRow2.Name = "ButtonRow2"
    btnRow2.Size = UDim2.new(1, 0, 0, 28)
    btnRow2.Position = UDim2.new(0, 0, 0, 116)
    btnRow2.BackgroundTransparency = 1
    btnRow2.Parent = inputArea
    
    local row2Layout = Instance.new("UIListLayout")
    row2Layout.FillDirection = Enum.FillDirection.Horizontal
    row2Layout.SortOrder = Enum.SortOrder.LayoutOrder
    row2Layout.Padding = UDim.new(0, 6)
    row2Layout.Parent = btnRow2
    
    insertBtn = createButton("InsertBtn", "Vložit do Scriptu", UDim2.new(0.45, -4, 1, 0), UDim2.new(0, 0, 0, 0), btnRow2, colors, function()
        if lastAIResponseText ~= "" then
            local success, target = Insert.InsertIntoStudio(lastAIResponseText)
            if success and target then
                print("[Roblox AI Assistant] Kód byl úspěšně nahrán do: " .. target:GetFullName())
            end
        end
    end)
    insertBtn.Visible = false -- Zobrazíme až po obdržení odpovědi
    
    copyBtn = createButton("CopyBtn", "Kopírovat kód", UDim2.new(0.35, -4, 1, 0), UDim2.new(0, 0, 0, 0), btnRow2, colors, function()
        if lastAIResponseText ~= "" then
            local clean = Insert.CleanMarkdown(lastAIResponseText)
            pcall(function()
                -- Vytiskneme do logu pro snadné kopírování, pokud standardní schránka není dostupná
                print("================ ROBLOX AI ASSISTANT KÓD ================")
                print(clean)
                print("=========================================================")
            end)
        end
    end)
    copyBtn.Visible = false
    
    settingsBtn = createButton("SettingsBtn", "Nastavení", UDim2.new(0.2, -4, 1, 0), UDim2.new(0, 0, 0, 0), btnRow2, colors, function()
        settingsPanel.Visible = not settingsPanel.Visible
    end)
    
    -- 5. Nastavení panel (vysouvací nebo překryvný)
    settingsPanel = Instance.new("Frame")
    settingsPanel.Name = "SettingsPanel"
    settingsPanel.Size = UDim2.new(0.94, 0, 0, 220)
    settingsPanel.Position = UDim2.new(0.03, 0, 0.05, 0)
    settingsPanel.BackgroundColor3 = colors.CardBackground
    settingsPanel.Visible = false
    settingsPanel.ZIndex = 10
    settingsPanel.Parent = mainFrame
    
    addCorner(settingsPanel, 8)
    addStroke(settingsPanel, colors.Border, 1)
    addPadding(settingsPanel, 12, 12, 12, 12)
    
    local settingsTitle = Instance.new("TextLabel")
    settingsTitle.Name = "Title"
    settingsTitle.Size = UDim2.new(1, 0, 0, 20)
    settingsTitle.BackgroundTransparency = 1
    settingsTitle.Text = "Nastavení asistentu"
    settingsTitle.TextColor3 = colors.Text
    settingsTitle.Font = Enum.Font.SourceSansBold
    settingsTitle.TextSize = 14
    settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
    settingsTitle.Parent = settingsPanel
    
    -- Popisek modelu
    local modelLabel = Instance.new("TextLabel")
    modelLabel.Name = "ModelLabel"
    modelLabel.Size = UDim2.new(1, 0, 0, 16)
    modelLabel.Position = UDim2.new(0, 0, 0, 25)
    modelLabel.BackgroundTransparency = 1
    modelLabel.Text = "Ollama Model:"
    modelLabel.TextColor3 = colors.Text
    modelLabel.Font = Enum.Font.SourceSans
    modelLabel.TextSize = 12
    modelLabel.TextXAlignment = Enum.TextXAlignment.Left
    modelLabel.Parent = settingsPanel
    
    -- TextBox k ručnímu zápisu modelu
    modelInput = Instance.new("TextBox")
    modelInput.Name = "ModelInput"
    modelInput.Size = UDim2.new(1, 0, 0, 24)
    modelInput.Position = UDim2.new(0, 0, 0, 44)
    modelInput.BackgroundColor3 = colors.Background
    modelInput.Text = Settings.GetModel()
    modelInput.TextColor3 = colors.Text
    modelInput.Font = Enum.Font.SourceSans
    modelInput.TextSize = 12
    modelInput.Parent = settingsPanel
    addCorner(modelInput, 4)
    addStroke(modelInput, colors.Border, 1)
    
    modelInput.FocusLost:Connect(function(enterPressed)
        if modelInput.Text ~= "" then
            Settings.SetModel(modelInput.Text)
            print("[Roblox AI Assistant] Model změněn na: " .. modelInput.Text)
        end
    end)
    
    -- Popisek adresy backendu
    local urlLabel = Instance.new("TextLabel")
    urlLabel.Name = "UrlLabel"
    urlLabel.Size = UDim2.new(1, 0, 0, 16)
    urlLabel.Position = UDim2.new(0, 0, 0, 75)
    urlLabel.BackgroundTransparency = 1
    urlLabel.Text = "URL Adresa Flask Backendu:"
    urlLabel.TextColor3 = colors.Text
    urlLabel.Font = Enum.Font.SourceSans
    urlLabel.TextSize = 12
    urlLabel.TextXAlignment = Enum.TextXAlignment.Left
    urlLabel.Parent = settingsPanel
    
    -- Vstup adresy backendu
    urlInput = Instance.new("TextBox")
    urlInput.Name = "UrlInput"
    urlInput.Size = UDim2.new(1, 0, 0, 24)
    urlInput.Position = UDim2.new(0, 0, 0, 94)
    urlInput.BackgroundColor3 = colors.Background
    urlInput.Text = Settings.GetBridgeUrl()
    urlInput.TextColor3 = colors.Text
    urlInput.Font = Enum.Font.SourceSans
    urlInput.TextSize = 12
    urlInput.Parent = settingsPanel
    addCorner(urlInput, 4)
    addStroke(urlInput, colors.Border, 1)
    
    urlInput.FocusLost:Connect(function(enterPressed)
        if urlInput.Text ~= "" then
            Settings.SetBridgeUrl(urlInput.Text)
            print("[Roblox AI Assistant] Adresa bridge změněna na: " .. urlInput.Text)
        end
    end)
    
    -- Stavový řádek připojení
    statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, 0, 0, 18)
    statusLabel.Position = UDim2.new(0, 0, 0, 128)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "● Načítám stav připojení..."
    statusLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
    statusLabel.Font = Enum.Font.SourceSansBold
    statusLabel.TextSize = 11
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = settingsPanel
    
    -- Tlačítko pro otestování spojení
    local testBtn = Instance.new("TextButton")
    testBtn.Name = "TestConnectionBtn"
    testBtn.Size = UDim2.new(0.46, 0, 0, 26)
    testBtn.Position = UDim2.new(0, 0, 0, 155)
    testBtn.BackgroundColor3 = colors.Button
    testBtn.Text = "Test připojení"
    testBtn.TextColor3 = colors.ButtonText
    testBtn.Font = Enum.Font.SourceSans
    testBtn.TextSize = 12
    testBtn.Parent = settingsPanel
    addCorner(testBtn, 4)
    addStroke(testBtn, colors.Border, 1)
    testBtn.MouseButton1Click:Connect(testConnection)
    
    -- Zavřít/Uložit nastavení
    local closeSettingsBtn = Instance.new("TextButton")
    closeSettingsBtn.Name = "CloseSettingsBtn"
    closeSettingsBtn.Size = UDim2.new(0.48, 0, 0, 26)
    closeSettingsBtn.Position = UDim2.new(0.52, 0, 0, 155)
    closeSettingsBtn.BackgroundColor3 = colors.Accent
    closeSettingsBtn.Text = "Zavřít"
    closeSettingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeSettingsBtn.Font = Enum.Font.SourceSansBold
    closeSettingsBtn.TextSize = 12
    closeSettingsBtn.Parent = settingsPanel
    addCorner(closeSettingsBtn, 4)
    
    closeSettingsBtn.MouseButton1Click:Connect(function()
        settingsPanel.Visible = false
    end)
    
    -- 6. Detekce změn motivu vzhledu
    Theme.OnThemeChanged(function(newColors)
        applyThemeColors(newColors)
    end)
    
    applyThemeColors(colors)
    
    -- Úvodní uvítací bublina od AI
    addChatBubble("AI", "Ahoj! Jsem tvůj lokální Roblox AI Assistant spuštěný přes Ollamu. Jak ti mohu dnes pomoci s programováním v Luau?", colors)
    
    -- Po startu otestujeme připojení na pozadí
    task.spawn(testConnection)
end

return UI
