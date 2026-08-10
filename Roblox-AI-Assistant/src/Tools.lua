--[[
    Tools.lua
    Nástrojový modul pro Roblox AI Agent.
    Tento modul provádí příkazy agenta přímo v prostředí Roblox Studio.
--]]

local Tools = {}

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local LogService = game:GetService("LogService")

-- Pomocná funkce pro vyhledání objektu podle tečkami oddělené cesty
local function findObjectByPath(path)
	if not path or path == "" then return nil end
	local parts = string.split(path, ".")
	local current = game
	
	for i, part in ipairs(parts) do
		if i == 1 then
			local success, service = pcall(function() return game:GetService(part) end)
			if success and service then
				current = service
			else
				current = game:FindFirstChild(part)
			end
		else
			if current then
				current = current:FindFirstChild(part)
			else
				return nil
			end
		end
	end
	return current
end

-- 1. Získá hierarchický strom objektů
function Tools.getExplorerTree(rootServiceName, maxDepth)
	rootServiceName = rootServiceName or "Workspace"
	maxDepth = maxDepth or 2
	
	local root = findObjectByPath(rootServiceName)
	if not root then
		return "Služba nebyla nalezena: " .. tostring(rootServiceName)
	end
	
	local function buildTree(instance, currentDepth)
		if currentDepth > maxDepth then return { name = instance.Name, className = instance.ClassName, truncated = true } end
		
		local node = {
			name = instance.Name,
			className = instance.ClassName,
			children = {}
		}
		
		for _, child in ipairs(instance:GetChildren()) do
			table.insert(node.children, buildTree(child, currentDepth + 1))
		end
		return node
	end
	
	local tree = buildTree(root, 1)
	local HttpService = game:GetService("HttpService")
	return HttpService:JSONEncode(tree)
end

-- 2. Přečte zdrojový kód skriptu
function Tools.readScript(scriptPath)
	local obj = findObjectByPath(scriptPath)
	if not obj then
		return "ERROR: Skript na cestě '" .. tostring(scriptPath) .. "' nebyl nalezen."
	end
	
	if not (obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript")) then
		return "ERROR: Objekt '" .. tostring(scriptPath) .. "' není skript (ClassName: " .. obj.ClassName .. ")."
	end
	
	return obj.Source
end

-- 3. Vyhledá skripty podle názvu
function Tools.searchScripts(query)
	query = string.lower(query or "")
	local results = {}
	
	local servicesToSearch = {
		game:GetService("Workspace"),
		game:GetService("ServerScriptService"),
		game:GetService("ReplicatedStorage"),
		game:GetService("ServerStorage"),
		game:GetService("StarterPlayer"),
		game:GetService("StarterGui")
	}
	
	for _, service in ipairs(servicesToSearch) do
		for _, descendant in ipairs(service:GetDescendants()) do
			if descendant:IsA("LuaSourceContainer") then
				if string.find(string.lower(descendant.Name), query, 1, true) then
					table.insert(results, descendant:GetFullName())
				end
			end
		end
	end
	
	local HttpService = game:GetService("HttpService")
	return HttpService:JSONEncode(results)
end

-- 4. Prohledá zdrojové kódy v celém projektu (grep)
function Tools.grepScripts(pattern)
	pattern = pattern or ""
	local matches = {}
	
	local servicesToSearch = {
		game:GetService("Workspace"),
		game:GetService("ServerScriptService"),
		game:GetService("ReplicatedStorage"),
		game:GetService("ServerStorage"),
		game:GetService("StarterPlayer"),
		game:GetService("StarterGui")
	}
	
	for _, service in ipairs(servicesToSearch) do
		for _, descendant in ipairs(service:GetDescendants()) do
			if descendant:IsA("LuaSourceContainer") then
				local source = descendant.Source
				if source and string.find(source, pattern, 1, true) then
					table.insert(matches, {
						path = descendant:GetFullName(),
						className = descendant.ClassName
					})
				end
			end
		end
	end
	
	local HttpService = game:GetService("HttpService")
	return HttpService:JSONEncode(matches)
end

-- 5. Získá označené objekty
function Tools.getSelection()
	local selected = Selection:Get()
	local names = {}
	for _, obj in ipairs(selected) do
		table.insert(names, {
			name = obj.Name,
			className = obj.ClassName,
			path = obj:GetFullName()
		})
	end
	local HttpService = game:GetService("HttpService")
	return HttpService:JSONEncode(names)
end

-- 6. Aplikuje změnu skriptu s vytvořením Undo bodu (ChangeHistoryService)
function Tools.editScript(path, newSource)
	local obj = findObjectByPath(path)
	if not obj then
		return false, "Skript nenalezen: " .. tostring(path)
	end
	
	if not (obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript")) then
		return false, "Objekt není skript: " .. tostring(path)
	end
	
	ChangeHistoryService:SetWaypoint("AI Agent: Pledging edit to " .. obj.Name)
	obj.Source = newSource
	ChangeHistoryService:SetWaypoint("AI Agent: Applied edit to " .. obj.Name)
	
	return true, "Úprava skriptu " .. path .. " byla úspěšně aplikována."
end

-- 7. Vytvoří nový skript s Undo bodem
function Tools.createScript(parentPath, name, scriptType, source)
	local parent = findObjectByPath(parentPath)
	if not parent then
		return false, "Rodičovské umístění nenalezeno: " .. tostring(parentPath)
	end
	
	scriptType = scriptType or "Script"
	local newScript
	
	if scriptType == "LocalScript" then
		newScript = Instance.new("LocalScript")
	elseif scriptType == "ModuleScript" then
		newScript = Instance.new("ModuleScript")
	else
		newScript = Instance.new("Script")
	end
	
	newScript.Name = name or "NewAIScript"
	newScript.Source = source or "-- Generováno AI Agentem\n"
	
	ChangeHistoryService:SetWaypoint("AI Agent: Creating new " .. scriptType .. " " .. newScript.Name)
	newScript.Parent = parent
	ChangeHistoryService:SetWaypoint("AI Agent: Created " .. newScript.Name)
	
	return true, "Názor na skript vytvořen: " .. newScript:GetFullName()
end

-- Spuštění konkrétního toolu podle názvu
function Tools.executeTool(actionName, actionInput)
	if actionName == "get_explorer_tree" then
		return Tools.getExplorerTree(actionInput.root_service, actionInput.max_depth)
	elseif actionName == "read_script" then
		return Tools.readScript(actionInput.path)
	elseif actionName == "search_scripts" then
		return Tools.searchScripts(actionInput.query)
	elseif actionName == "grep_scripts" then
		return Tools.grepScripts(actionInput.pattern)
	elseif actionName == "get_selection" then
		return Tools.getSelection()
	else
		return "Neznámý nástroj: " .. tostring(actionName)
	end
end

return Tools
