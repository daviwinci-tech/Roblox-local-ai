--[[
    Api.lua
    Komunikační modul pro připojení k Flask backendu.
    Odesílá požadavky na kontrolu spojení, vygenerování kódu, chat s historií, opravu a vysvětlení.
]]

local HttpService = game:GetService("HttpService")
local Settings = require(script.Parent.Settings)

local Api = {}

-- Pomocná funkce pro bezpečné odstranění lomítka na konci
local function rstrip(str, char)
    if not char then char = "%s" end
    return (string.gsub(str, char .. "*$", ""))
end

-- Pomocná funkce pro provedení HTTP POST požadavku
local function postRequest(url, payload)
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(payload)
        })
    end)
    
    if not success then
        warn("[Roblox AI Assistant] Síťový požadavek selhal: " .. tostring(response))
        return {
            success = false,
            message = "Nelze se připojit k backendu. Ujistěte se, že Flask server běží (python backend/app.py)."
        }
    end
    
    if response.StatusCode ~= 200 then
        local message = "Server vrátil chybu (" .. tostring(response.StatusCode) .. ")"
        pcall(function()
            local decoded = HttpService:JSONDecode(response.Body)
            if decoded and (decoded.error or decoded.response) then
                message = decoded.error or decoded.response
            end
        end)
        return {
            success = false,
            message = message
        }
    end
    
    local decodeSuccess, decodedBody = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)
    
    if not decodeSuccess then
        return {
            success = false,
            message = "Chyba při dekódování odpovědi od serveru."
        }
    end
    
    return {
        success = true,
        response = decodedBody.response or ""
    }
end

-- 1. Kontrola spojení s backendem a Ollamou
function Api.CheckHealth()
    local baseUrl = rstrip(Settings.GetBridgeUrl(), "/")
    local url = baseUrl .. "/health"
    
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "GET"
        })
    end)
    
    if not success then
        return {
            success = false,
            backend_connected = false,
            ollama_connected = false,
            message = "Flask backend je offline. Spusťte ho pomocí 'python backend/app.py'."
        }
    end
    
    if response.StatusCode ~= 200 then
        return {
            success = false,
            backend_connected = true,
            ollama_connected = false,
            message = "Backend odpověděl chybovým kódem: " .. tostring(response.StatusCode)
        }
    end
    
    local decodeSuccess, decodedBody = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)
    
    if not decodeSuccess then
        return {
            success = false,
            backend_connected = true,
            ollama_connected = false,
            message = "Backend vrátil neplatný formát dat."
        }
    end
    
    return {
        success = true,
        backend_connected = decodedBody.backend_connected or true,
        ollama_connected = decodedBody.ollama_connected or false,
        available_models = decodedBody.available_models or {},
        message = decodedBody.ollama_connected 
            and "Připojení k backendu i Ollamě je v pořádku!" 
            or "Backend běží, ale Ollama je offline nebo nedostupná."
    }
end

-- 2. Chat s historií konverzace (používá endpoint /chat)
function Api.Chat(messagesList)
    local baseUrl = rstrip(Settings.GetBridgeUrl(), "/")
    local url = baseUrl .. "/chat"
    
    local payload = {
        messages = messagesList,
        model = Settings.GetModel()
    }
    
    return postRequest(url, payload)
end

-- 3. Generování nového kódu (používá endpoint /generate)
function Api.Generate(prompt)
    local baseUrl = rstrip(Settings.GetBridgeUrl(), "/")
    local url = baseUrl .. "/generate"
    
    local payload = {
        prompt = prompt,
        model = Settings.GetModel()
    }
    
    return postRequest(url, payload)
end

-- 4. Oprava chyb v Lua skriptu (používá endpoint /fix)
function Api.Fix(code)
    local baseUrl = rstrip(Settings.GetBridgeUrl(), "/")
    local url = baseUrl .. "/fix"
    
    local payload = {
        code = code,
        model = Settings.GetModel()
    }
    
    return postRequest(url, payload)
end

-- 5. Vysvětlení Lua skriptu (používá endpoint /explain)
function Api.Explain(code)
    local baseUrl = rstrip(Settings.GetBridgeUrl(), "/")
    local url = baseUrl .. "/explain"
    
    local payload = {
        code = code,
        model = Settings.GetModel()
    }
    
    return postRequest(url, payload)
end

return Api
