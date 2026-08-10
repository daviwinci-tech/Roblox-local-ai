--[[
    UI.lua
    Vytváří grafické uživatelské rozhraní (GUI) s podporou Chat Mód a Agent Mód pro Roblox AI Agent.
--]]

local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")

local Theme = require(script.Parent.Theme)
local Api = require(script.Parent.Api)
local Insert = require(script.Parent.Insert)
local Fix = require(script.Parent.Fix)
local Explain = require(script.Parent.Explain)
local Settings = require(script.Parent.Settings)
local Tools = require(script.Parent.Tools)
local Diff = require(script.Parent.Diff)

local UI = {}

-- Globální prvky rozhraní
local mainFrame = nil
local modeChatBtn = nil
local modeAgentBtn = nil

local chatPanel = nil
local agentPanel = nil

-- Chat Mód prvky
local chatScroll = nil
local promptInput = nil
local generateBtn = nil
local fixBtn = nil
local explainBtn = nil
local insertBtn = nil
local copyBtn = nil
local settingsBtn = nil
local settingsPanel = nil
local statusLabel = nil

local isGenerating = false
local lastAIResponseText = ""
local messagesHistory = {}

-- Agent Mód prvky
local agentTaskInput = nil
local agentStartBtn = nil
local agentStatusBadge = nil
local agentLogScroll = nil
local pendingDiffFrame = nil
local diffPathLabel = nil
local diffReasonLabel = nil
local diffTextLabel = nil
local approveDiffBtn = nil
local rejectDiffBtn = nil

local activeTaskId = nil
local isAgentRunning = false

-- Pomocné funkce pro úpravu vzhledu
local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 6)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.fromRGB(100, 100, 100)
	stroke.Thickness = thickness or 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function addPadding(parent, top, bottom, left, right)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, top or 0)
	padding.PaddingBottom = UDim.new(0, bottom or 0)
	padding.PaddingLeft = UDim.new(0, left or 0)
	padding.PaddingRight = UDim.new(0, right or 0)
	padding.Parent = parent
	return padding
end

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
	button.TextSize = 13
	button.Parent = parent
	addCorner(button, 6)
	addStroke(button, colors.Border, 1)
	
	if onClick then
		button.MouseButton1Click:Connect(onClick)
	end
	return button
end

-- ==========================================
-- AGENT SPUŠTĚNÍ A SMYČKA V LUAU
-- ==========================================

local function addAgentLog(message, level)
	if not agentLogScroll then return end
	local colors = Theme.GetColors()
	
	local logFrame = Instance.new("Frame")
	logFrame.Size = UDim2.new(1, 0, 0, 0)
	logFrame.AutomaticSize = Enum.AutomaticSize.Y
	logFrame.BackgroundTransparency = 1
	
	local logText = Instance.new("TextLabel")
	logText.Size = UDim2.new(1, 0, 0, 0)
	logText.AutomaticSize = Enum.AutomaticSize.Y
	logText.BackgroundTransparency = 1
	logText.Text = message
	logText.Font = Enum.Font.Code
	logText.TextSize = 11
	logText.TextWrapped = true
	logText.TextXAlignment = Enum.TextXAlignment.Left
	
	if level == "error" then
		logText.TextColor3 = Color3.fromRGB(255, 100, 100)
	elseif level == "success" then
		logText.TextColor3 = Color3.fromRGB(100, 255, 150)
	elseif level == "tool" then
		logText.TextColor3 = Color3.fromRGB(100, 200, 255)
	elseif level == "warning" then
		logText.TextColor3 = Color3.fromRGB(255, 200, 100)
	else
		logText.TextColor3 = colors.Text
	end
	
	logText.Parent = logFrame
	logFrame.Parent = agentLogScroll
	agentLogScroll.CanvasPosition = Vector2.new(0, agentLogScroll.AbsoluteCanvasSize.Y)
end

local function updateAgentUI(state)
	if not state then return end
	local colors = Theme.GetColors()
	
	-- Aktualizace stavového odznaku
	local status = state.status or "idle"
	agentStatusBadge.Text = " STAV: " .. string.upper(status) .. " "
	
	if status == "planning" or status == "investigating" then
		agentStatusBadge.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
	elseif status == "editing" or status == "waiting_for_approval" then
		agentStatusBadge.BackgroundColor3 = Color3.fromRGB(220, 140, 0)
	elseif status == "completed" then
		agentStatusBadge.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
	elseif status == "failed" then
		agentStatusBadge.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	end
	
	-- Zobrazení schvalovacího okna pro diffs
	if status == "waiting_for_approval" and state.pending_diffs and #state.pending_diffs > 0 then
		local pending = state.pending_diffs[1]
		pendingDiffFrame.Visible = true
		diffPathLabel.Text = "Skript: " .. tostring(pending.path)
		diffReasonLabel.Text = "Důvod: " .. tostring(pending.description)
		
		-- Načteme aktuální kód z Roblox Studia
		local currentSource = Tools.readScript(pending.path)
		if string.find(currentSource, "ERROR:") then
			currentSource = "-- (Nový skript)"
		end
		
		local diffStr = Diff.generateLineDiff(currentSource, pending.new_source)
		diffTextLabel.Text = diffStr
	else
		pendingDiffFrame.Visible = false
	end
end

-- Vstoupí do agentní smyčky a zpracovává kroky autonomně
local function processAgentStep(taskId, toolResult)
	Api.AgentStep(taskId, toolResult, function(success, response)
		if not success or not response then
			addAgentLog("Chyba při komunikaci s agentem.", "error")
			isAgentRunning = false
			agentStartBtn.Text = "Spustit AI Agenta"
			return
		end
		
		-- Pokud krok vyžaduje spuštění nástroje v Roblox Studio
		if response.action_required == "execute_in_roblox" then
			local action = response.action
			local actionInput = response.action_input or {}
			
			addAgentLog("🛠️ Spouštím nástroj v Roblox Studio: " .. tostring(action), "tool")
			local result = Tools.executeTool(action, actionInput)
			
			updateAgentUI(response.state)
			-- Okamžitě pokračujeme v dalším kroku s výsledkem z Roblox Studio
			task.wait(0.5)
			processAgentStep(taskId, result)
		else
			-- Standardní aktualizace stavu
			local state = response.state or response
			updateAgentUI(state)
			
			if state.logs and #state.logs > 0 then
				local lastLog = state.logs[#state.logs]
				addAgentLog(lastLog.message, lastLog.level)
			end
			
			if state.status == "completed" or state.status == "failed" then
				isAgentRunning = false
				agentStartBtn.Text = "Spustit AI Agenta"
			end
		end
	end)
end

local function startAgentTask()
	if isAgentRunning then return end
	local goal = agentTaskInput.Text
	if string.gsub(goal, "%s+", "") == "" then return end
	
	isAgentRunning = true
	agentStartBtn.Text = "Agent Běží..."
	
	-- Vyčištění logu
	for _, child in ipairs(agentLogScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	
	addAgentLog("🚀 Spouštím AI Agenta pro úkol: " .. goal, "info")
	
	Api.AgentStart(goal, function(success, taskId, initialState)
		if success and taskId then
			activeTaskId = taskId
			updateAgentUI(initialState)
			-- Započetí prvního kroku
			processAgentStep(taskId, nil)
		else
			addAgentLog("Chyba při inicializaci agenta.", "error")
			isAgentRunning = false
			agentStartBtn.Text = "Spustit AI Agenta"
		end
	end)
end

-- ==========================================
-- VYTVOŘENÍ HLAVNÍHO GUI DOCK WIDGETU
-- ==========================================

function UI.CreateMainDockWidget(plugin)
	local pluginGui = plugin:CreateDockWidgetPluginGui(
		"RobloxAIAgent_DockWidget",
		DockWidgetPluginGuiInfo.new(
			Enum.InitialDockState.Right,
			true,  -- InitialEnabled
			false, -- OverridePreviousState
			340,   -- DefaultWidth
			520,   -- DefaultHeight
			260,   -- MinWidth
			380    -- MinHeight
		)
	)
	pluginGui.Title = "Roblox AI Local Agent"
	
	local colors = Theme.GetColors()
	
	mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = colors.Background
	mainFrame.Parent = pluginGui
	
	-- 1. Horní lišta s přepínačem Módů (Chat vs Agent)
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 36)
	topBar.BackgroundColor3 = colors.CardBackground
	topBar.Parent = mainFrame
	addStroke(topBar, colors.Border, 1)
	
	modeChatBtn = Instance.new("TextButton")
	modeChatBtn.Size = UDim2.new(0.5, -2, 1, 0)
	modeChatBtn.Position = UDim2.new(0, 0, 0, 0)
	modeChatBtn.BackgroundColor3 = colors.Accent
	modeChatBtn.Text = "💬 Chat Mód"
	modeChatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	modeChatBtn.Font = Enum.Font.SourceSansBold
	modeChatBtn.TextSize = 13
	modeChatBtn.Parent = topBar
	
	modeAgentBtn = Instance.new("TextButton")
	modeAgentBtn.Size = UDim2.new(0.5, -2, 1, 0)
	modeAgentBtn.Position = UDim2.new(0.5, 2, 0, 0)
	modeAgentBtn.BackgroundColor3 = colors.Button
	modeAgentBtn.Text = "🤖 Agent Mód"
	modeAgentBtn.TextColor3 = colors.ButtonText
	modeAgentBtn.Font = Enum.Font.SourceSansBold
	modeAgentBtn.TextSize = 13
	modeAgentBtn.Parent = topBar
	
	-- Panel pro Chat Mód
	chatPanel = Instance.new("Frame")
	chatPanel.Size = UDim2.new(1, 0, 1, -36)
	chatPanel.Position = UDim2.new(0, 0, 0, 36)
	chatPanel.BackgroundTransparency = 1
	chatPanel.Parent = mainFrame
	
	-- Panel pro Agent Mód
	agentPanel = Instance.new("Frame")
	agentPanel.Size = UDim2.new(1, 0, 1, -36)
	agentPanel.Position = UDim2.new(0, 0, 0, 36)
	agentPanel.BackgroundTransparency = 1
	agentPanel.Visible = false
	agentPanel.Parent = mainFrame
	
	-- Přepínání mezi záložkami
	modeChatBtn.MouseButton1Click:Connect(function()
		chatPanel.Visible = true
		agentPanel.Visible = false
		modeChatBtn.BackgroundColor3 = colors.Accent
		modeChatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		modeAgentBtn.BackgroundColor3 = colors.Button
		modeAgentBtn.TextColor3 = colors.ButtonText
	end)
	
	modeAgentBtn.MouseButton1Click:Connect(function()
		chatPanel.Visible = false
		agentPanel.Visible = true
		modeAgentBtn.BackgroundColor3 = colors.Accent
		modeAgentBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		modeChatBtn.BackgroundColor3 = colors.Button
		modeChatBtn.TextColor3 = colors.ButtonText
	end)
	
	-- ==========================================
	-- INTEGRACE CHAT MÓDU
	-- ==========================================
	chatScroll = Instance.new("ScrollingFrame")
	chatScroll.Size = UDim2.new(1, -16, 1, -110)
	chatScroll.Position = UDim2.new(0, 8, 0, 8)
	chatScroll.BackgroundTransparency = 1
	chatScroll.ScrollBarThickness = 4
	chatScroll.Parent = chatPanel
	
	local chatLayout = Instance.new("UIListLayout")
	chatLayout.SortOrder = Enum.SortOrder.LayoutOrder
	chatLayout.Padding = UDim.new(0, 8)
	chatLayout.Parent = chatScroll
	
	local inputArea = Instance.new("Frame")
	inputArea.Size = UDim2.new(1, -16, 0, 90)
	inputArea.Position = UDim2.new(0, 8, 1, -95)
	inputArea.BackgroundColor3 = colors.CardBackground
	inputArea.Parent = chatPanel
	addCorner(inputArea, 8)
	addStroke(inputArea, colors.Border, 1)
	addPadding(inputArea, 6, 6, 8, 8)
	
	promptInput = Instance.new("TextBox")
	promptInput.Size = UDim2.new(1, 0, 0, 48)
	promptInput.BackgroundColor3 = colors.Background
	promptInput.Text = ""
	promptInput.PlaceholderText = "Napiš dotaz k Roblox Luau kódu..."
	promptInput.PlaceholderColor3 = colors.SubText
	promptInput.TextColor3 = colors.Text
	promptInput.Font = Enum.Font.SourceSans
	promptInput.TextSize = 13
	promptInput.TextXAlignment = Enum.TextXAlignment.Left
	promptInput.TextYAlignment = Enum.TextYAlignment.Top
	promptInput.ClearTextOnFocus = false
	promptInput.Parent = inputArea
	addCorner(promptInput, 6)
	addStroke(promptInput, colors.Border, 1)
	
	generateBtn = createButton("GenerateBtn", "Generovat", UDim2.new(0.3, 0, 0, 24), UDim2.new(0.7, 0, 0, 54), inputArea, colors, function()
		if promptInput.Text ~= "" then
			Api.SendChat({{role="user", content=promptInput.Text}}, Settings.GetModel(), function(success, resp)
				if success then
					local colors = Theme.GetColors()
					addAgentLog("Odpověď obdržena.", "success")
				end
			end)
		end
	end)

	-- ==========================================
	-- INTEGRACE AGENT MÓDU
	-- ==========================================
	addPadding(agentPanel, 8, 8, 8, 8)
	
	local taskLabel = Instance.new("TextLabel")
	taskLabel.Size = UDim2.new(1, 0, 0, 18)
	taskLabel.BackgroundTransparency = 1
	taskLabel.Text = "Zadej vývojový úkol pro AI Agenta:"
	taskLabel.TextColor3 = colors.Text
	taskLabel.Font = Enum.Font.SourceSansBold
	taskLabel.TextSize = 13
	taskLabel.TextXAlignment = Enum.TextXAlignment.Left
	taskLabel.Parent = agentPanel
	
	agentTaskInput = Instance.new("TextBox")
	agentTaskInput.Size = UDim2.new(1, 0, 0, 44)
	agentTaskInput.Position = UDim2.new(0, 0, 0, 22)
	agentTaskInput.BackgroundColor3 = colors.CardBackground
	agentTaskInput.Text = "Oprav mining systém a zkontroluj RemoteEvents."
	agentTaskInput.TextColor3 = colors.Text
	agentTaskInput.Font = Enum.Font.SourceSans
	agentTaskInput.TextSize = 13
	agentTaskInput.TextWrapped = true
	agentTaskInput.TextXAlignment = Enum.TextXAlignment.Left
	agentTaskInput.TextYAlignment = Enum.TextYAlignment.Top
	agentTaskInput.Parent = agentPanel
	addCorner(agentTaskInput, 6)
	addStroke(agentTaskInput, colors.Border, 1)
	addPadding(agentTaskInput, 4, 4, 6, 6)
	
	agentStartBtn = createButton("AgentStartBtn", "🚀 Spustit AI Agenta", UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, 72), agentPanel, colors, startAgentTask)
	agentStartBtn.BackgroundColor3 = colors.Accent
	agentStartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	
	-- Stavový odznak
	agentStatusBadge = Instance.new("TextLabel")
	agentStatusBadge.Size = UDim2.new(1, 0, 0, 20)
	agentStatusBadge.Position = UDim2.new(0, 0, 0, 106)
	agentStatusBadge.BackgroundColor3 = colors.CardBackground
	agentStatusBadge.Text = " STAV: ČEKÁ NA ZADÁNÍ ÚKOLU "
	agentStatusBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
	agentStatusBadge.Font = Enum.Font.SourceSansBold
	agentStatusBadge.TextSize = 11
	agentStatusBadge.Parent = agentPanel
	addCorner(agentStatusBadge, 4)
	
	-- Log feed průběhu
	agentLogScroll = Instance.new("ScrollingFrame")
	agentLogScroll.Size = UDim2.new(1, 0, 1, -250)
	agentLogScroll.Position = UDim2.new(0, 0, 0, 132)
	agentLogScroll.BackgroundColor3 = colors.CardBackground
	agentLogScroll.ScrollBarThickness = 4
	agentLogScroll.Parent = agentPanel
	addCorner(agentLogScroll, 6)
	addStroke(agentLogScroll, colors.Border, 1)
	addPadding(agentLogScroll, 6, 6, 6, 6)
	
	local logLayout = Instance.new("UIListLayout")
	logLayout.SortOrder = Enum.SortOrder.LayoutOrder
	logLayout.Padding = UDim.new(0, 4)
	logLayout.Parent = agentLogScroll
	
	-- Schvalovací rámec pro Diff změn
	pendingDiffFrame = Instance.new("Frame")
	pendingDiffFrame.Size = UDim2.new(1, 0, 0, 110)
	pendingDiffFrame.Position = UDim2.new(0, 0, 1, -112)
	pendingDiffFrame.BackgroundColor3 = Color3.fromRGB(30, 25, 15)
	pendingDiffFrame.Visible = false
	pendingDiffFrame.Parent = agentPanel
	addCorner(pendingDiffFrame, 6)
	addStroke(pendingDiffFrame, Color3.fromRGB(200, 150, 50), 1)
	addPadding(pendingDiffFrame, 6, 6, 8, 8)
	
	diffPathLabel = Instance.new("TextLabel")
	diffPathLabel.Size = UDim2.new(1, 0, 0, 16)
	diffPathLabel.BackgroundTransparency = 1
	diffPathLabel.Text = "Skript: -"
	diffPathLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	diffPathLabel.Font = Enum.Font.SourceSansBold
	diffPathLabel.TextSize = 12
	diffPathLabel.TextXAlignment = Enum.TextXAlignment.Left
	diffPathLabel.Parent = pendingDiffFrame
	
	diffReasonLabel = Instance.new("TextLabel")
	diffReasonLabel.Size = UDim2.new(1, 0, 0, 14)
	diffReasonLabel.Position = UDim2.new(0, 0, 0, 16)
	diffReasonLabel.BackgroundTransparency = 1
	diffReasonLabel.Text = "Důvod: -"
	diffReasonLabel.TextColor3 = colors.SubText
	diffReasonLabel.Font = Enum.Font.SourceSansItalic
	diffReasonLabel.TextSize = 11
	diffReasonLabel.TextXAlignment = Enum.TextXAlignment.Left
	diffReasonLabel.Parent = pendingDiffFrame
	
	approveDiffBtn = createButton("ApproveBtn", "✓ Aplikovat Změnu", UDim2.new(0.48, 0, 0, 26), UDim2.new(0, 0, 1, -28), pendingDiffFrame, colors, function()
		if activeTaskId then
			Api.AgentApprove(activeTaskId, "all", function(success, res)
				if success then
					addAgentLog("Změna byla úspěšně aplikována v Roblox Studiu.", "success")
					processAgentStep(activeTaskId, "Změna kódu schválena uživatelem a aplikována.")
				end
			end)
		end
	end)
	approveDiffBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
	approveDiffBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	
	rejectDiffBtn = createButton("RejectBtn", "✕ Zamítnout", UDim2.new(0.48, 0, 0, 26), UDim2.new(0.52, 0, 1, -28), pendingDiffFrame, colors, function()
		if activeTaskId then
			Api.AgentReject(activeTaskId, "all", function(success, res)
				addAgentLog("Změna byla uživatelem zamítnuta.", "warning")
				processAgentStep(activeTaskId, "Uživatel zamítl navrženou změnu.")
			end)
		end
	end)
	rejectDiffBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	rejectDiffBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	
	return pluginGui
end

return UI
