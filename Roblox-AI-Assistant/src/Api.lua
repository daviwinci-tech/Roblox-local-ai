--[[
    Api.lua
    Zabezpečený komunikační modul pro spojení Roblox Studio Pluginu s lokálním Python backendem.
--]]

local Api = {}

local HttpService = game:GetService("HttpService")

-- Výchozí adresa lokálního backendu
Api.BaseUrl = "http://127.0.0.1:5000"

-- Test dostupnosti serveru
function Api.CheckHealth(callback)
	task.spawn(function()
		local success, response = pcall(function()
			return HttpService:RequestAsync({
				Url = Api.BaseUrl .. "/health",
				Method = "GET"
			})
		end)
		
		if success and response.Success then
			local decodeSuccess, data = pcall(function()
				return HttpService:JSONDecode(response.Body)
			end)
			if decodeSuccess then
				callback(true, data)
			else
				callback(false, "Chyba při zpracování JSON odpovědi z /health.")
			end
		else
			callback(false, "Nelze se spojit s backendem na " .. Api.BaseUrl .. ". Ujistěte se, že spuštěn 'python backend/app.py'.")
		end
	end)
end

-- Stávající Chat API
function Api.SendChat(messages, model, callback)
	task.spawn(function()
		local payload = {
			messages = messages,
			model = model
		}
		
		local success, response = pcall(function()
			return HttpService:RequestAsync({
				Url = Api.BaseUrl .. "/chat",
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode(payload)
			})
		end)
		
		if success and response.Success then
			local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
			if decodeSuccess and data.status == "ok" then
				callback(true, data.response)
			else
				callback(false, data.error or "Neplatná odpověď z serveru.")
			end
		else
			callback(false, "Chyba komunikace s backendem.")
		end
	end)
end

-- ==========================================
-- NOVÉ AGENTNÍ API METODY
-- ==========================================

-- Zahájení agentního úkolu
function Api.AgentStart(goal, callback)
	task.spawn(function()
		local payload = { goal = goal }
		local success, response = pcall(function()
			return HttpService:RequestAsync({
				Url = Api.BaseUrl .. "/agent/start",
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode(payload)
			})
		end)
		
		if success and response.Success then
			local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
			if decodeSuccess and data.status == "ok" then
				callback(true, data.task_id, data.state)
			else
				callback(false, nil, data.error or "Chyba při startu agenta.")
			end
		else
			callback(false, nil, "Nelze se spojit s agentním backendem.")
		end
	end)
end

-- Provedení jednoho kroku agenta
function Api.AgentStep(taskId, toolResult, callback)
	task.spawn(function()
		local payload = {
			task_id = taskId,
			tool_result = toolResult
		}
		local success, response = pcall(function()
			return HttpService:RequestAsync({
				Url = Api.BaseUrl .. "/agent/step",
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode(payload)
			})
		end)
		
		if success and response.Success then
			local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
			if decodeSuccess then
				callback(true, data)
			else
				callback(false, "Chyba při čtení krokové odpovědi.")
			end
		else
			callback(false, "Chyba sítě při volání /agent/step.")
		end
	end)
end

-- Schválení navržené změny kódu
function Api.AgentApprove(taskId, diffId, callback)
	task.spawn(function()
		local payload = { task_id = taskId, diff_id = diffId or "all" }
		local success, response = pcall(function()
			return HttpService:RequestAsync({
				Url = Api.BaseUrl .. "/agent/approve",
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode(payload)
			})
		end)
		if success and response.Success then
			local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
			callback(decodeSuccess, data)
		else
			callback(false, "Chyba při schvalování úpravy.")
		end
	end)
end

-- Zamítnutí navržené změny kódu
function Api.AgentReject(taskId, diffId, callback)
	task.spawn(function()
		local payload = { task_id = taskId, diff_id = diffId or "all" }
		local success, response = pcall(function()
			return HttpService:RequestAsync({
				Url = Api.BaseUrl .. "/agent/reject",
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode(payload)
			})
		end)
		if success and response.Success then
			local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
			callback(decodeSuccess, data)
		else
			callback(false, "Chyba při zamítání úpravy.")
		end
	end)
end

return Api
