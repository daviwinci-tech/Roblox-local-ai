import React, { useState, useEffect, useRef } from "react";
import {
  Play,
  Terminal,
  Settings as SettingsIcon,
  Folder,
  FileCode,
  Check,
  Copy,
  ArrowRight,
  BookOpen,
  Cpu,
  Layers,
  AlertTriangle,
  RefreshCw,
  Download,
  Maximize2,
  ChevronRight,
  Info,
  ExternalLink,
  Code,
  Sparkles,
  Trash2,
  Save,
  CheckCircle,
  HelpCircle,
  Laptop
} from "lucide-react";

// Simulované soubory v Roblox Studio Exploreru
interface SimulatedFile {
  id: string;
  name: string;
  type: "Script" | "LocalScript" | "ModuleScript";
  path: string;
  source: string;
}

const INITIAL_SIMULATED_FILES: SimulatedFile[] = [
  {
    id: "killpart",
    name: "KillPart",
    type: "Script",
    path: "Workspace.KillPart",
    source: `-- Jednoduchý skript pro zabití hráče při doteku
local part = script.Parent

local function onTouched(otherPart)
	local character = otherPart.Parent
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	
	if humanoid then
		humanoid.Health = 0 -- Zabije postavu
	end
end

part.Touched:Connect(onTouched)
`
  },
  {
    id: "doublejump",
    name: "DoubleJump",
    type: "LocalScript",
    path: "StarterPlayer.StarterPlayerScripts.DoubleJump",
    source: `-- ROZBITÝ SKRIPT (klikněte na "Opravit skript" pro demonstraci!)
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local char = player.Character

-- CHYBA: Chybí kontrola načtení postavy a humanoidu
-- CHYba: Chybí UserInputService pro zachycení skoku

char.Touched:Connect(function()
	print("pokus o skok")
	-- Jak udělat double jump??
end)
`
  },
  {
    id: "leaderboard",
    name: "Leaderboard",
    type: "Script",
    path: "ServerScriptService.Leaderboard",
    source: `-- Skript pro vytvoření herních statistik hráče
local Players = game:GetService("Players")

local function onPlayerAdded(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local gold = Instance.new("IntValue")
	gold.Name = "Gold"
	gold.Value = 100
	gold.Parent = leaderstats
end

Players.PlayerAdded:Connect(onPlayerAdded)
`
  }
];

// Zdrojové kódy reálného projektu pro Průzkumník Kódu
const REAL_PROJECT_FILES = {
  "bridge.py": {
    path: "Bridge/bridge.py",
    language: "python",
    desc: "Python Flask server fungující jako brána (bridge) mezi Roblox Studiem a lokálním Ollama API.",
    code: `import json
import os
import requests
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

CONFIG_PATH = os.path.join(os.path.dirname(__file__), "config.json")

def load_config():
    default_config = {
        "ollama_url": "http://127.0.0.1:11434/api/generate",
        "default_model": "qwen2.5-coder:14b",
        "host": "127.0.0.1",
        "port": 5000
    }
    if not os.path.exists(CONFIG_PATH):
        with open(CONFIG_PATH, "w", encoding="utf-8") as f:
            json.dump(default_config, f, indent=4)
        return default_config
    with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        return json.load(f)

config = load_config()

@app.route("/generate", methods=["POST"])
def generate():
    try:
        data = request.get_json() or {}
        prompt = data.get("prompt", "")
        if not prompt:
            return jsonify({"response": "Chyba: Prázdný prompt"}), 400
            
        model = data.get("model", config.get("default_model", "qwen2.5-coder:14b"))
        system_prompt = data.get("system_prompt", "Jsi asistent pro Roblox Luau.")
        
        payload = {
            "model": model,
            "prompt": f"{system_prompt}\\n\\nUživatel: {prompt}\\n\\nAsistent:",
            "stream": False,
            "options": {"temperature": 0.2}
        }
        
        response = requests.post(config.get("ollama_url"), json=payload, timeout=60)
        return jsonify({"response": response.json().get("response", "")})
    except Exception as e:
        return jsonify({"response": f"Chyba: {str(e)}"}), 500

if __name__ == "__main__":
    app.run(host=config.get("host"), port=config.get("port"))`
  },
  "Main.server.lua": {
    path: "src/Main.server.lua",
    language: "lua",
    desc: "Hlavní serverový spouštěcí skript Roblox pluginu. Registruje tlačítka, nástrojovou lištu a otevírá UI.",
    code: `-- Entrypoint pro Roblox Studio Plugin
if not plugin then return end

local Settings = require(script.Parent.Settings)
local Theme = require(script.Parent.Theme)
local Widgets = require(script.Parent.Widgets)
local UI = require(script.Parent.UI)

local function initialize()
    Settings.Initialize(plugin)
    local toolbar = plugin:CreateToolbar("Roblox AI Assistant")
    local toggleButton = toolbar:CreateButton(
        "RobloxAI_ToggleBtn",
        "Otevře okno lokálního AI asistenta.",
        "rbxassetid://18395028591",
        "AI Assistant"
    )
    toggleButton.ClickableWhenViewportHidden = true
    local widget = Widgets.CreateWidget(plugin)
    
    UI.CreateInterface(widget, plugin)
    
    toggleButton.Click:Connect(function()
        local isEnabled = Widgets.ToggleVisibility()
        toggleButton:SetActive(isEnabled)
    end)
    widget:GetPropertyChangedSignal("Enabled"):Connect(function()
        toggleButton:SetActive(widget.Enabled)
    end)
end

pcall(initialize)`
  },
  "Api.lua": {
    path: "src/Api.lua",
    language: "lua",
    desc: "Zajišťuje veškeré síťové požadavky (HttpService:RequestAsync) směrem k Flask bridge.",
    code: `local HttpService = game:GetService("HttpService")
local Settings = require(script.Parent.Settings)
local Api = {}

local function postRequest(url, payload)
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
    end)
    if not success then return {success = false, message = "Bridge neběží!"} end
    return {success = true, response = HttpService:JSONDecode(response.Body).response}
end

function Api.Generate(prompt)
    return postRequest(Settings.GetBridgeUrl(), {
        prompt = prompt,
        model = Settings.GetModel(),
        system_prompt = "Jsi seniorní Roblox Luau vývojář."
    })
end

function Api.Fix(code)
    return postRequest(Settings.GetBridgeUrl(), {
        prompt = "Oprav následující Roblox Lua skript. Vrať pouze opravený Lua kód.\\n\\n" .. code,
        model = Settings.GetModel()
    })
end

function Api.Explain(code)
    return postRequest(Settings.GetBridgeUrl(), {
        prompt = "Vysvětli následující Roblox Lua skript krok za krokem.\\n\\n" .. code,
        model = Settings.GetModel()
    })
end

return Api`
  },
  "UI.lua": {
    path: "src/UI.lua",
    language: "lua",
    desc: "GUI engine, který programově staví celé responzivní ChatGPT rozhraní s podporou tmavého/světlého režimu.",
    code: `local Theme = require(script.Parent.Theme)
local Api = require(script.Parent.Api)
local Insert = require(script.Parent.Insert)
local Settings = require(script.Parent.Settings)

local UI = {}

function UI.CreateInterface(parent, plugin)
    local colors = Theme.GetColors()
    
    -- Vytvoření hlavního rámce s ChatGPT stylem
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundColor3 = colors.Background
    mainFrame.Parent = parent
    
    -- Scrollovací okno na zprávy
    local chatScroll = Instance.new("ScrollingFrame")
    chatScroll.Size = UDim2.new(1, 0, 1, -215)
    chatScroll.Position = UDim2.new(0, 0, 0, 45)
    chatScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    chatScroll.Parent = mainFrame
    
    -- Vstupní TextBox a řady tlačítek (Generovat, Opravit, Vysvětlit)
    -- Podrobné navázání eventů: Api.Generate(), Fix.Execute(), Explain.Execute()
    -- Dynamické barvy aktualizované přes Theme.OnThemeChanged()
end

return UI`
  },
  "Insert.lua": {
    path: "src/Insert.lua",
    language: "lua",
    desc: "Manipuluje s Roblox Explorerem. Zapisuje kód do vybraných skriptů s plnou historií změn (Undo/Redo).",
    code: `local Selection = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Insert = {}

function Insert.CleanMarkdown(code)
    if not code then return "" end
    local clean = string.gsub(code, "^%s*\`\`\`[Ll]ua", "")
    clean = string.gsub(clean, "\`\`\`%s*$", "")
    return string.gsub(clean, "^%s*(.-)%s*$", "%1")
end

function Insert.InsertIntoStudio(rawCode)
    local codeToInsert = Insert.CleanMarkdown(rawCode)
    local currentSelection = Selection:Get()
    local targetScript = nil
    
    for _, item in ipairs(currentSelection) do
        if item:IsA("Script") or item:IsA("LocalScript") or item:IsA("ModuleScript") then
            targetScript = item
            break
        end
    end
    
    if not targetScript then
        targetScript = Instance.new("Script")
        targetScript.Name = "AIScript"
        targetScript.Parent = game:GetService("ServerScriptService")
        Selection:Set({targetScript})
    end
    
    ChangeHistoryService:SetWaypoint("BeforeAIInsert")
    targetScript.Source = codeToInsert
    ChangeHistoryService:SetWaypoint("AfterAIInsert")
    return true, targetScript
end

return Insert`
  },
  "Theme.lua": {
    path: "src/Theme.lua",
    language: "lua",
    desc: "Detekuje herní motiv (Dark/Light) v Roblox Studiu a převádí jej na elegantní paletu barev.",
    code: `local Theme = {}
local StudioSettings = settings()

local function getStudioTheme()
    return StudioSettings.Studio.Theme
end

function Theme.GetColors()
    local theme = getStudioTheme()
    local isDark = string.find(string.lower(theme.Name), "dark") ~= nil
    
    if isDark then
        return {
            Background = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground),
            CardBackground = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground),
            Text = theme:GetColor(Enum.StudioStyleGuideColor.MainText),
            Accent = Color3.fromRGB(0, 162, 255),
            Button = theme:GetColor(Enum.StudioStyleGuideColor.Button),
            ButtonHover = theme:GetColor(Enum.StudioStyleGuideColor.Button, Enum.StudioStyleGuideModifier.Hover),
            UserBubble = Color3.fromRGB(53, 55, 64),
            AIBubble = Color3.fromRGB(68, 70, 84),
        }
    else
        return {
            Background = Color3.fromRGB(245, 245, 245),
            CardBackground = Color3.fromRGB(255, 255, 255),
            Text = Color3.fromRGB(33, 33, 33),
            Accent = Color3.fromRGB(0, 132, 255),
            Button = Color3.fromRGB(235, 235, 235),
            UserBubble = Color3.fromRGB(240, 242, 245),
            AIBubble = Color3.fromRGB(255, 255, 255),
        }
    end
end

return Theme`
  }
};

export default function App() {
  // Aktivní pohled / tab
  const [activeTab, setActiveTab] = useState<"simulator" | "explorer" | "setup" | "architecture">("simulator");
  
  // Stavy Roblox Studio Simulatoru
  const [simulatedFiles, setSimulatedFiles] = useState<SimulatedFile[]>(INITIAL_SIMULATED_FILES);
  const [selectedFileId, setSelectedFileId] = useState<string>("killpart");
  const [selectedFileSource, setSelectedFileSource] = useState<string>(INITIAL_SIMULATED_FILES[0].source);
  
  // Stav Chatu v Simulatoru (ChatGPT styl)
  const [chatMessages, setChatMessages] = useState<Array<{ sender: "user" | "ai"; text: string; isCode?: boolean }>>([
    {
      sender: "ai",
      text: "Ahoj! Jsem tvůj lokální Roblox AI Assistant spuštěný přes Ollamu. Jak ti mohu dnes pomoci s programováním v Luau?"
    }
  ]);
  const [userPrompt, setUserPrompt] = useState<string>("");
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [ollamaModel, setOllamaModel] = useState<string>("qwen2.5-coder:14b");
  const [bridgeUrl, setBridgeUrl] = useState<string>("http://127.0.0.1:5000/generate");
  const [showSimSettings, setShowSimSettings] = useState<boolean>(false);
  
  // Stavy Průzkumníku Kódu
  const [selectedProjectFile, setSelectedProjectFile] = useState<keyof typeof REAL_PROJECT_FILES>("Main.server.lua");
  const [copiedFile, setCopiedFile] = useState<string | null>(null);

  // Stavy checklistu instalace
  const [checklist, setChecklist] = useState<Record<string, boolean>>({
    ollama: false,
    model: false,
    bridge: false,
    rojo: false,
    plugin: false
  });

  const chatEndRef = useRef<HTMLDivElement>(null);

  // Synchronizace editoru při změně vybraného souboru
  const handleSelectFile = (id: string) => {
    // Uložit změny aktuálního souboru před přepnutím
    setSimulatedFiles(prev => prev.map(f => f.id === selectedFileId ? { ...f, source: selectedFileSource } : f));
    
    // Načíst nový soubor
    const file = simulatedFiles.find(f => f.id === id);
    if (file) {
      setSelectedFileId(id);
      setSelectedFileSource(file.source);
    }
  };

  // Uložení aktuálního zdrojového kódu v simulátoru
  const handleSaveSource = () => {
    setSimulatedFiles(prev => prev.map(f => f.id === selectedFileId ? { ...f, source: selectedFileSource } : f));
    // Zobrazit bublinu nebo log o uložení
    const selected = simulatedFiles.find(f => f.id === selectedFileId);
    if (selected) {
      alert(`Zdrojový kód pro ${selected.name} byl v simulátoru uložen.`);
    }
  };

  // Odeslání dotazu do našeho reálného Gemini API backendu!
  const handleSendPrompt = async (forcedPrompt?: string, mode: "generate" | "fix" | "explain" = "generate") => {
    const promptToSend = forcedPrompt || userPrompt;
    if (!promptToSend.trim() && mode === "generate") return;

    // Přidáme zprávu od uživatele
    const newMessages = [...chatMessages];
    if (mode === "generate") {
      newMessages.push({ sender: "user", text: promptToSend });
      setUserPrompt("");
    } else if (mode === "fix") {
      newMessages.push({ sender: "user", text: `🔧 Opravit vybraný skript "${simulatedFiles.find(f => f.id === selectedFileId)?.name}"` });
    } else if (mode === "explain") {
      newMessages.push({ sender: "user", text: `📖 Vysvětlit vybraný skript "${simulatedFiles.find(f => f.id === selectedFileId)?.name}"` });
    }
    
    setChatMessages(newMessages);
    setIsLoading(true);

    try {
      let response;
      if (mode === "fix") {
        response = await fetch("/api/fix", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ code: selectedFileSource })
        });
      } else if (mode === "explain") {
        response = await fetch("/api/explain", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ code: selectedFileSource })
        });
      } else {
        response = await fetch("/api/generate", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ prompt: promptToSend, model: ollamaModel })
        });
      }

      const data = await response.json();
      if (response.ok && data.response) {
        setChatMessages(prev => [...prev, { sender: "ai", text: data.response }]);
      } else {
        setChatMessages(prev => [...prev, { sender: "ai", text: `Chyba API: ${data.error || "Neznámá chyba serveru."}` }]);
      }
    } catch (err: any) {
      setChatMessages(prev => [...prev, { sender: "ai", text: `Chyba připojení k lokálnímu backendu: ${err.message}` }]);
    } finally {
      setIsLoading(false);
    }
  };

  // Vložení vygenerovaného Lua kódu z poslední AI zprávy zpět do simulovaného Editoru!
  const handleInsertCodeIntoEditor = () => {
    // Najdeme poslední zprávu od AI, která obsahuje kód
    const aiMessages = chatMessages.filter(m => m.sender === "ai");
    if (aiMessages.length === 0) return;
    
    const lastMessage = aiMessages[aiMessages.length - 1].text;
    
    // Extrahujeme kód z bloku ```lua ... ```
    const regex = /```lua([\s\S]*?)```/g;
    const match = regex.exec(lastMessage);
    let extractedCode = "";
    
    if (match && match[1]) {
      extractedCode = match[1].trim();
    } else {
      // Pokud tam není formalizovaný blok, pokusíme se vzít celou zprávu
      extractedCode = lastMessage.trim();
    }

    if (extractedCode) {
      setSelectedFileSource(extractedCode);
      // Synchronizujeme do seznamu souborů
      setSimulatedFiles(prev => prev.map(f => f.id === selectedFileId ? { ...f, source: extractedCode } : f));
      
      // Přidáme systémový log do chatu
      setChatMessages(prev => [...prev, {
        sender: "ai",
        text: `*Systém: Vygenerovaný kód byl úspěšně vložen do aktivního skriptu "${simulatedFiles.find(f => f.id === selectedFileId)?.name}"!*`
      }]);
    }
  };

  // Kopírování kódu do schránky
  const copyToClipboard = (text: string, label: string) => {
    navigator.clipboard.writeText(text);
    setCopiedFile(label);
    setTimeout(() => setCopiedFile(null), 2000);
  };

  const clearChat = () => {
    setChatMessages([
      {
        sender: "ai",
        text: "Ahoj! Jsem tvůj lokální Roblox AI Assistant spuštěný přes Ollamu. Jak ti mohu dnes pomoci s programováním v Luau?"
      }
    ]);
  };

  const toggleChecklist = (key: string) => {
    setChecklist(prev => ({ ...prev, [key]: !prev[key] }));
  };

  // Automatické scrollování chatu dolů
  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [chatMessages, isLoading]);

  const activeFile = simulatedFiles.find(f => f.id === selectedFileId);

  return (
    <div className="min-h-screen bg-slate-900 text-slate-100 font-sans flex flex-col selection:bg-sky-500/30 selection:text-sky-200">
      
      {/* Hlavní Header */}
      <header className="border-b border-slate-800 bg-slate-950/80 backdrop-blur sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 py-4 flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="h-10 w-10 rounded-xl bg-gradient-to-tr from-sky-600 to-indigo-600 flex items-center justify-center shadow-lg shadow-sky-500/20 ring-1 ring-sky-400/30">
              <Sparkles className="h-5 w-5 text-sky-100" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl font-bold tracking-tight text-white font-sans">Roblox AI Assistant</h1>
                <span className="text-[10px] bg-sky-500/10 text-sky-400 ring-1 ring-sky-400/20 px-2 py-0.5 rounded-full font-medium">OPEN SOURCE</span>
              </div>
              <p className="text-xs text-slate-400">Interaktivní portál, průvodce a simulátor lokálního AI pluginu pro Roblox Studio</p>
            </div>
          </div>

          {/* Navigační menu */}
          <nav className="flex bg-slate-900/90 p-1 rounded-xl border border-slate-800">
            <button
              onClick={() => setActiveTab("simulator")}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 ${
                activeTab === "simulator"
                  ? "bg-sky-600 text-white shadow-md shadow-sky-500/15"
                  : "text-slate-400 hover:text-slate-200 hover:bg-slate-800/50"
              }`}
            >
              <Laptop className="h-4 w-4" />
              <span>Simulátor Studia</span>
            </button>
            <button
              onClick={() => setActiveTab("explorer")}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 ${
                activeTab === "explorer"
                  ? "bg-sky-600 text-white shadow-md shadow-sky-500/15"
                  : "text-slate-400 hover:text-slate-200 hover:bg-slate-800/50"
              }`}
            >
              <Code className="h-4 w-4" />
              <span>Zdrojové kódy</span>
            </button>
            <button
              onClick={() => setActiveTab("setup")}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 ${
                activeTab === "setup"
                  ? "bg-sky-600 text-white shadow-md shadow-sky-500/15"
                  : "text-slate-400 hover:text-slate-200 hover:bg-slate-800/50"
              }`}
            >
              <BookOpen className="h-4 w-4" />
              <span>Návod k instalaci</span>
            </button>
            <button
              onClick={() => setActiveTab("architecture")}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 ${
                activeTab === "architecture"
                  ? "bg-sky-600 text-white shadow-md shadow-sky-500/15"
                  : "text-slate-400 hover:text-slate-200 hover:bg-slate-800/50"
              }`}
            >
              <Cpu className="h-4 w-4" />
              <span>SOLID Architektura</span>
            </button>
          </nav>
        </div>
      </header>

      {/* Hlavní obsah podle aktivní záložky */}
      <main className="flex-1 max-w-7xl w-full mx-auto p-4 md:p-6">
        
        {/* TAB 1: SIMULÁTOR ROBLOX STUDIA */}
        {activeTab === "simulator" && (
          <div className="grid grid-cols-1 xl:grid-cols-12 gap-6 items-start">
            
            {/* Informační úvodní sloupec */}
            <div className="xl:col-span-12 bg-gradient-to-r from-slate-950 to-slate-900 border border-slate-800 rounded-2xl p-5 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
              <div className="space-y-1">
                <h2 className="text-lg font-bold text-white flex items-center gap-2">
                  <span className="flex h-2.5 w-2.5 rounded-full bg-emerald-500 animate-pulse" />
                  Plně funkční online simulátor
                </h2>
                <p className="text-sm text-slate-400 max-w-3xl">
                  Vyzkoušejte si chování Roblox pluginu přímo zde v prohlížeči! Zvolte skript v levém panelu,
                  zeptejte se na úpravu nebo klikněte na <strong>Opravit</strong> / <strong>Vysvětlit</strong>.
                  Náš serverový proxy modul s umělou inteligencí vygeneruje skutečný kód, který pak můžete stisknutím
                  <strong>Vložit do Scriptu</strong> nahrát rovnou do simulovaného editoru.
                </p>
              </div>
              <div className="bg-slate-900 px-4 py-2 rounded-xl border border-slate-800 text-xs flex items-center gap-3">
                <div>
                  <span className="text-slate-400">Model simulátoru: </span>
                  <span className="text-sky-400 font-mono font-medium">gemini-3.5-flash (Proxy)</span>
                </div>
              </div>
            </div>

            {/* LEVÝ PANEL: Roblox Studio Explorer & Script Editor */}
            <div className="xl:col-span-7 bg-slate-950 rounded-2xl border border-slate-800 shadow-2xl overflow-hidden flex flex-col h-[650px]">
              
              {/* Roblox Studio Lišta */}
              <div className="bg-[#1e1e1e] px-4 py-2 flex items-center justify-between border-b border-zinc-800 text-xs font-mono text-zinc-300">
                <div className="flex items-center gap-2">
                  <div className="h-2.5 w-2.5 rounded-full bg-rose-500" />
                  <span className="font-bold text-white">Roblox Studio</span>
                  <span className="text-zinc-500">|</span>
                  <span className="text-sky-400">Místo: Vývojový_Server_Place</span>
                </div>
                <div className="flex items-center gap-3">
                  <button onClick={handleSaveSource} className="flex items-center gap-1.5 px-2.5 py-1 rounded bg-[#2e2e2e] hover:bg-[#3d3d3d] text-zinc-300 transition-colors">
                    <Save className="h-3.5 w-3.5 text-emerald-400" />
                    <span>Uložit skript</span>
                  </button>
                  <span className="px-2 py-0.5 rounded bg-zinc-800 text-emerald-400 font-bold">ONLINE</span>
                </div>
              </div>

              {/* Tělo editoru s Explorerem */}
              <div className="flex-1 flex overflow-hidden">
                
                {/* 1. Roblox Explorer (Boční panel) */}
                <div className="w-56 bg-[#252526] border-r border-zinc-800 flex flex-col text-xs font-mono select-none">
                  <div className="bg-[#1e1e1e] p-2 text-[11px] font-bold text-zinc-400 tracking-wider uppercase border-b border-zinc-800 flex items-center justify-between">
                    <span>Explorer (Strom)</span>
                    <Folder className="h-3.5 w-3.5 text-zinc-500" />
                  </div>
                  <div className="flex-1 p-2 space-y-3 overflow-y-auto text-zinc-300">
                    
                    {/* Workspace složka */}
                    <div className="space-y-1">
                      <div className="flex items-center gap-1.5 font-bold text-zinc-400">
                        <ChevronRight className="h-3 w-3 rotate-90" />
                        <Folder className="h-3.5 w-3.5 text-yellow-500" />
                        <span>Workspace</span>
                      </div>
                      <div className="pl-6 space-y-0.5">
                        {simulatedFiles.filter(f => f.path.startsWith("Workspace")).map(file => (
                          <button
                            key={file.id}
                            onClick={() => handleSelectFile(file.id)}
                            className={`w-full flex items-center gap-1.5 py-1 px-2 rounded text-left transition-colors ${
                              selectedFileId === file.id
                                ? "bg-sky-500/20 text-sky-300 border-l-2 border-sky-400"
                                : "hover:bg-zinc-800 text-zinc-400"
                            }`}
                          >
                            <FileCode className="h-3.5 w-3.5 text-sky-400" />
                            <span>{file.name}</span>
                          </button>
                        ))}
                      </div>
                    </div>

                    {/* ServerScriptService složka */}
                    <div className="space-y-1">
                      <div className="flex items-center gap-1.5 font-bold text-zinc-400">
                        <ChevronRight className="h-3 w-3 rotate-90" />
                        <Folder className="h-3.5 w-3.5 text-blue-500" />
                        <span>ServerScriptService</span>
                      </div>
                      <div className="pl-6 space-y-0.5">
                        {simulatedFiles.filter(f => f.path.startsWith("ServerScriptService")).map(file => (
                          <button
                            key={file.id}
                            onClick={() => handleSelectFile(file.id)}
                            className={`w-full flex items-center gap-1.5 py-1 px-2 rounded text-left transition-colors ${
                              selectedFileId === file.id
                                ? "bg-sky-500/20 text-sky-300 border-l-2 border-sky-400"
                                : "hover:bg-zinc-800 text-zinc-400"
                            }`}
                          >
                            <FileCode className="h-3.5 w-3.5 text-indigo-400" />
                            <span>{file.name}</span>
                          </button>
                        ))}
                      </div>
                    </div>

                    {/* StarterPlayerScripts složka */}
                    <div className="space-y-1">
                      <div className="flex items-center gap-1.5 font-bold text-zinc-400">
                        <ChevronRight className="h-3 w-3 rotate-90" />
                        <Folder className="h-3.5 w-3.5 text-purple-500" />
                        <span>StarterPlayer</span>
                      </div>
                      <div className="pl-6 space-y-0.5">
                        {simulatedFiles.filter(f => f.path.startsWith("StarterPlayer")).map(file => (
                          <button
                            key={file.id}
                            onClick={() => handleSelectFile(file.id)}
                            className={`w-full flex items-center gap-1.5 py-1 px-2 rounded text-left transition-colors ${
                              selectedFileId === file.id
                                ? "bg-sky-500/20 text-sky-300 border-l-2 border-sky-400"
                                : "hover:bg-zinc-800 text-zinc-400"
                            }`}
                          >
                            <FileCode className="h-3.5 w-3.5 text-purple-400" />
                            <span>{file.name}</span>
                          </button>
                        ))}
                      </div>
                    </div>

                  </div>
                </div>

                {/* 2. Roblox Script Editor */}
                <div className="flex-1 bg-[#1e1e1e] flex flex-col font-mono text-sm overflow-hidden">
                  <div className="bg-[#2d2d2d] px-3 py-1.5 text-xs text-zinc-400 border-b border-zinc-800 flex items-center gap-2 justify-between">
                    <span className="flex items-center gap-1.5 text-zinc-300">
                      <FileCode className={`h-3.5 w-3.5 ${activeFile?.type === "LocalScript" ? "text-purple-400" : "text-sky-400"}`} />
                      {activeFile?.path}.lua
                    </span>
                    <span className="text-[10px] text-zinc-500">UTF-8 - Luau Standard</span>
                  </div>
                  
                  {/* Psací plocha simulátoru */}
                  <div className="flex-1 flex overflow-hidden">
                    {/* Řádková čísla */}
                    <div className="w-10 bg-[#1e1e1e] text-right pr-2 py-4 text-zinc-600 border-r border-zinc-800 select-none text-xs leading-6">
                      {Array.from({ length: 25 }).map((_, i) => (
                        <div key={i}>{i + 1}</div>
                      ))}
                    </div>
                    {/* Textarea */}
                    <textarea
                      value={selectedFileSource}
                      onChange={(e) => setSelectedFileSource(e.target.value)}
                      className="flex-1 bg-[#1e1e1e] text-zinc-200 p-4 font-mono text-xs focus:outline-none resize-none overflow-y-auto leading-6"
                      placeholder="Sem napište svůj Roblox kód nebo nechte AI vygenerovat kód tlačítkem..."
                      spellCheck={false}
                    />
                  </div>
                </div>

              </div>

              {/* Panel informací o aktivním skriptu */}
              <div className="bg-[#1e1e1e] border-t border-zinc-800 p-2.5 px-4 flex items-center justify-between text-xs text-zinc-400">
                <div className="flex items-center gap-2">
                  <span className="h-2 w-2 rounded-full bg-emerald-500" />
                  <span>Aktivní typ: <strong className="text-zinc-200">{activeFile?.type}</strong></span>
                </div>
                <span className="text-zinc-500">Uložení změn probíhá lokálně v simulátoru</span>
              </div>
            </div>

            {/* PRAVÝ PANEL: Simulovaný Roblox AI Assistant Plugin (ChatGPT-style) */}
            <div className="xl:col-span-5 bg-slate-950 rounded-2xl border border-slate-800 shadow-2xl overflow-hidden flex flex-col h-[650px]">
              
              {/* Plugin Header */}
              <div className="bg-slate-900 border-b border-slate-800 p-3 px-4 flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <div className="h-7 w-7 rounded bg-sky-500/10 border border-sky-400/20 flex items-center justify-center">
                    <Sparkles className="h-4 w-4 text-sky-400" />
                  </div>
                  <div>
                    <h3 className="text-sm font-bold text-white leading-none">Roblox AI Assistant</h3>
                    <span className="text-[10px] text-sky-400 font-mono font-medium">Běží na: {ollamaModel}</span>
                  </div>
                </div>

                <div className="flex items-center gap-2">
                  <button
                    onClick={() => setShowSimSettings(!showSimSettings)}
                    className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 transition-colors"
                    title="Nastavení pluginu"
                  >
                    <SettingsIcon className="h-4 w-4" />
                  </button>
                  <button
                    onClick={clearChat}
                    className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 transition-colors"
                    title="Vyčistit chat"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              </div>

              {/* Vnitřek panelu */}
              <div className="flex-1 flex flex-col relative overflow-hidden">
                
                {/* 1. Nastavení panelu (překryvné) */}
                {showSimSettings && (
                  <div className="absolute inset-x-0 top-0 bg-slate-900 border-b border-slate-800 p-4 z-20 space-y-4 animate-in fade-in slide-in-from-top-2 duration-200">
                    <h4 className="text-xs font-bold uppercase tracking-wider text-slate-300">Nastavení simulovaného pluginu</h4>
                    
                    <div className="space-y-3 text-xs">
                      <div className="space-y-1">
                        <label className="text-slate-400 block font-medium">Cílový model Ollamy:</label>
                        <select
                          value={ollamaModel}
                          onChange={(e) => setOllamaModel(e.target.value)}
                          className="w-full bg-slate-950 border border-slate-800 rounded px-2.5 py-1.5 text-slate-200 focus:outline-none focus:border-sky-500 font-mono"
                        >
                          <option value="qwen2.5-coder:14b">qwen2.5-coder:14b (Výchozí)</option>
                          <option value="qwen2.5-coder:7b">qwen2.5-coder:7b</option>
                          <option value="deepseek-coder">deepseek-coder</option>
                          <option value="llama3">llama3</option>
                        </select>
                      </div>

                      <div className="space-y-1">
                        <label className="text-slate-400 block font-medium">Lokální adresa Bridge:</label>
                        <input
                          type="text"
                          value={bridgeUrl}
                          onChange={(e) => setBridgeUrl(e.target.value)}
                          className="w-full bg-slate-950 border border-slate-800 rounded px-2.5 py-1.5 text-slate-200 focus:outline-none focus:border-sky-500 font-mono"
                        />
                      </div>
                    </div>

                    <div className="flex justify-end pt-1">
                      <button
                        onClick={() => setShowSimSettings(false)}
                        className="px-3 py-1.5 bg-sky-600 hover:bg-sky-500 text-white font-medium text-xs rounded transition-colors"
                      >
                        Uložit nastavení
                      </button>
                    </div>
                  </div>
                )}

                {/* 2. Chat Historie */}
                <div className="flex-1 p-4 overflow-y-auto space-y-4 bg-slate-950 text-xs flex flex-col">
                  {chatMessages.map((msg, idx) => (
                    <div
                      key={idx}
                      className={`flex flex-col max-w-[85%] rounded-2xl p-3.5 ${
                        msg.sender === "user"
                          ? "bg-sky-600/10 border border-sky-500/20 text-sky-100 self-end rounded-tr-none"
                          : "bg-slate-900 border border-slate-800 text-slate-200 self-start rounded-tl-none font-mono leading-relaxed"
                      }`}
                    >
                      <div className="text-[10px] uppercase font-bold tracking-wider text-slate-400 mb-1">
                        {msg.sender === "user" ? "Vy" : `AI Asistent (${ollamaModel})`}
                      </div>
                      
                      {/* Vykreslení markdown textu jednoduše s odřádkováním */}
                      <div className="whitespace-pre-wrap select-text break-words">
                        {msg.text}
                      </div>
                    </div>
                  ))}

                  {/* Loading spinner */}
                  {isLoading && (
                    <div className="bg-slate-900 border border-slate-800 rounded-2xl rounded-tl-none p-3.5 max-w-[85%] self-start flex items-center gap-3">
                      <RefreshCw className="h-4 w-4 text-sky-400 animate-spin" />
                      <span className="text-slate-400 font-serif italic text-xs">Ollma API generuje odezvu...</span>
                    </div>
                  )}
                  <div ref={chatEndRef} />
                </div>

                {/* Akční kontextová tlačítka zobrazená po generování */}
                {chatMessages.length > 1 && !isLoading && (
                  <div className="bg-slate-900/50 border-t border-slate-900/80 p-2 flex items-center justify-center gap-2 shrink-0">
                    <button
                      onClick={handleInsertCodeIntoEditor}
                      className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-sky-600/10 hover:bg-sky-600/20 text-sky-400 border border-sky-500/20 font-bold transition-colors"
                    >
                      <Download className="h-3.5 w-3.5" />
                      <span>Vložit do Scriptu</span>
                    </button>
                    <button
                      onClick={() => {
                        const lastAI = chatMessages.filter(m => m.sender === "ai").pop()?.text || "";
                        copyToClipboard(lastAI, "last-response");
                      }}
                      className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 font-bold transition-colors"
                    >
                      <Copy className="h-3.5 w-3.5" />
                      <span>Kopírovat kód</span>
                    </button>
                  </div>
                )}

                {/* 3. Vstupní plocha pro dotazy */}
                <div className="bg-slate-900 border-t border-slate-800 p-3.5 space-y-3 shrink-0">
                  <div className="bg-slate-950 rounded-xl border border-slate-800 overflow-hidden flex items-end">
                    <textarea
                      value={userPrompt}
                      onChange={(e) => setUserPrompt(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === "Enter" && !e.shiftKey) {
                          e.preventDefault();
                          handleSendPrompt();
                        }
                      }}
                      disabled={isLoading}
                      placeholder="Sem napište dotaz pro AI nebo klikněte níže..."
                      className="flex-1 bg-slate-950 text-slate-200 text-xs p-3 focus:outline-none resize-none h-14"
                    />
                  </div>

                  {/* Spodní řada rychlých tlačítek */}
                  <div className="grid grid-cols-3 gap-2">
                    <button
                      onClick={() => handleSendPrompt(userPrompt, "generate")}
                      disabled={isLoading || !userPrompt.trim()}
                      className="px-2.5 py-2 rounded-lg bg-sky-600 hover:bg-sky-500 text-white font-bold transition-colors disabled:opacity-40 flex items-center justify-center gap-1.5"
                    >
                      <Sparkles className="h-3.5 w-3.5" />
                      <span>Generovat</span>
                    </button>

                    <button
                      onClick={() => handleSendPrompt("Opravit skript", "fix")}
                      disabled={isLoading}
                      className="px-2.5 py-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 font-bold transition-colors flex items-center justify-center gap-1.5"
                    >
                      <WrenchIcon className="h-3.5 w-3.5 text-sky-400" />
                      <span>Opravit skript</span>
                    </button>

                    <button
                      onClick={() => handleSendPrompt("Vysvětlit skript", "explain")}
                      disabled={isLoading}
                      className="px-2.5 py-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 font-bold transition-colors flex items-center justify-center gap-1.5"
                    >
                      <BookOpen className="h-3.5 w-3.5 text-sky-400" />
                      <span>Vysvětlit</span>
                    </button>
                  </div>
                </div>

              </div>
            </div>

          </div>
        )}

        {/* TAB 2: PRŮZKUMNÍK KÓDU (PROJECT FILE EXPLORER) */}
        {activeTab === "explorer" && (
          <div className="grid grid-cols-1 lg:grid-cols-4 gap-6 items-start">
            
            {/* Seznam souborů projektu */}
            <div className="lg:col-span-1 bg-slate-950 border border-slate-800 rounded-2xl p-4 space-y-4">
              <div>
                <h3 className="font-bold text-white text-sm">Průzkumník Kódu</h3>
                <p className="text-xs text-slate-400">Přehled reálných souborů vytvořených v projektu Roblox-AI-Assistant</p>
              </div>

              <div className="space-y-1">
                <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider block px-2 mb-1">Python Bridge (Flask)</span>
                <button
                  onClick={() => setSelectedProjectFile("bridge.py")}
                  className={`w-full flex items-center justify-between p-2.5 rounded-xl text-xs text-left transition-all ${
                    selectedProjectFile === "bridge.py"
                      ? "bg-sky-600 text-white font-medium"
                      : "bg-slate-900/50 text-slate-300 hover:bg-slate-900 border border-slate-800/80"
                  }`}
                >
                  <div className="flex items-center gap-2">
                    <FileCode className="h-4 w-4 text-yellow-500" />
                    <span>bridge.py</span>
                  </div>
                  <ChevronRight className="h-3 w-3 opacity-60" />
                </button>
              </div>

              <div className="space-y-1">
                <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider block px-2 mb-1">Luau Plugin (Roblox)</span>
                
                {[
                  "Main.server.lua",
                  "Api.lua",
                  "UI.lua",
                  "Insert.lua",
                  "Theme.lua"
                ].map((fileName) => {
                  return (
                    <button
                      key={fileName}
                      onClick={() => setSelectedProjectFile(fileName as any)}
                      className={`w-full flex items-center justify-between p-2.5 rounded-xl text-xs text-left transition-all ${
                        selectedProjectFile === fileName
                          ? "bg-sky-600 text-white font-medium"
                          : "bg-slate-900/50 text-slate-300 hover:bg-slate-900 border border-slate-800/80"
                      }`}
                    >
                      <div className="flex items-center gap-2">
                        <FileCode className="h-4 w-4 text-sky-400" />
                        <span>{fileName}</span>
                      </div>
                      <ChevronRight className="h-3 w-3 opacity-60" />
                    </button>
                  );
                })}
              </div>

              <div className="bg-slate-900 p-3.5 rounded-xl border border-slate-800 space-y-2 text-xs">
                <h4 className="font-bold text-slate-200">Rojo default.project</h4>
                <p className="text-slate-400 text-[11px] leading-relaxed">
                  Konfigurační soubor pro Rojo se nachází na adrese: <code className="text-sky-400 font-mono">Plugin/default.project.json</code>.
                  Tento soubor mapuje Luau soubory z vaší složky do herního stromu Roblox Studia.
                </p>
              </div>
            </div>

            {/* Zobrazení zdrojového kódu vybraného souboru */}
            <div className="lg:col-span-3 bg-slate-950 border border-slate-800 rounded-2xl overflow-hidden flex flex-col h-[650px] shadow-2xl">
              <div className="bg-slate-900 border-b border-slate-800 p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="text-xs bg-sky-500/10 text-sky-400 px-2.5 py-0.5 rounded-full font-mono font-medium">
                      {REAL_PROJECT_FILES[selectedProjectFile].path}
                    </span>
                  </div>
                  <h3 className="text-base font-bold text-white mt-1">{selectedProjectFile}</h3>
                  <p className="text-xs text-slate-400 mt-0.5">{REAL_PROJECT_FILES[selectedProjectFile].desc}</p>
                </div>

                <button
                  onClick={() => copyToClipboard(REAL_PROJECT_FILES[selectedProjectFile].code, selectedProjectFile)}
                  className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-2 border border-slate-700/80 self-start sm:self-auto shrink-0"
                >
                  {copiedFile === selectedProjectFile ? (
                    <>
                      <Check className="h-4 w-4 text-emerald-400" />
                      <span className="text-emerald-400">Zkopírováno!</span>
                    </>
                  ) : (
                    <>
                      <Copy className="h-4 w-4" />
                      <span>Kopírovat kód</span>
                    </>
                  )}
                </button>
              </div>

              {/* Code Editor Frame */}
              <div className="flex-1 overflow-auto bg-[#0d1117] p-5 font-mono text-xs text-slate-200 leading-relaxed leading-6 whitespace-pre">
                <code>
                  {REAL_PROJECT_FILES[selectedProjectFile].code}
                </code>
              </div>
            </div>

          </div>
        )}

        {/* TAB 3: NÁVOD K INSTALACI (INSTALLATION & SETUP) */}
        {activeTab === "setup" && (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            
            {/* Průvodce s interaktivním checklistem */}
            <div className="lg:col-span-1 bg-slate-950 border border-slate-800 rounded-2xl p-5 space-y-5">
              <div>
                <h3 className="font-bold text-white text-base">Průvodce instalací</h3>
                <p className="text-xs text-slate-400">Označujte si hotové kroky pro sledování celkového postupu zprovoznění</p>
              </div>

              {/* Checklist panel */}
              <div className="space-y-3">
                
                <div
                  onClick={() => toggleChecklist("ollama")}
                  className={`flex items-start gap-3 p-3 rounded-xl border cursor-pointer select-none transition-all duration-200 ${
                    checklist.ollama
                      ? "bg-emerald-500/5 border-emerald-500/20 text-slate-300"
                      : "bg-slate-900 border-slate-800 text-slate-400 hover:border-slate-700"
                  }`}
                >
                  <div className={`mt-0.5 h-4 w-4 rounded flex items-center justify-center border shrink-0 ${
                    checklist.ollama ? "bg-emerald-500 border-emerald-400 text-white" : "border-slate-600"
                  }`}>
                    {checklist.ollama && <Check className="h-3 w-3" />}
                  </div>
                  <div>
                    <span className={`text-xs font-bold block ${checklist.ollama ? "text-slate-200 line-through" : "text-white"}`}>1. Příprava Ollamy</span>
                    <span className="text-[11px] block text-slate-400 mt-0.5">Stažení a instalace Ollamy, stažení Qwen coder modelu</span>
                  </div>
                </div>

                <div
                  onClick={() => toggleChecklist("bridge")}
                  className={`flex items-start gap-3 p-3 rounded-xl border cursor-pointer select-none transition-all duration-200 ${
                    checklist.bridge
                      ? "bg-emerald-500/5 border-emerald-500/20 text-slate-300"
                      : "bg-slate-900 border-slate-800 text-slate-400 hover:border-slate-700"
                  }`}
                >
                  <div className={`mt-0.5 h-4 w-4 rounded flex items-center justify-center border shrink-0 ${
                    checklist.bridge ? "bg-emerald-500 border-emerald-400 text-white" : "border-slate-600"
                  }`}>
                    {checklist.bridge && <Check className="h-3 w-3" />}
                  </div>
                  <div>
                    <span className={`text-xs font-bold block ${checklist.bridge ? "text-slate-200 line-through" : "text-white"}`}>2. Python Bridge</span>
                    <span className="text-[11px] block text-slate-400 mt-0.5">Spuštění lokálního Flask bridge serveru přes start.bat</span>
                  </div>
                </div>

                <div
                  onClick={() => toggleChecklist("rojo")}
                  className={`flex items-start gap-3 p-3 rounded-xl border cursor-pointer select-none transition-all duration-200 ${
                    checklist.rojo
                      ? "bg-emerald-500/5 border-emerald-500/20 text-slate-300"
                      : "bg-slate-900 border-slate-800 text-slate-400 hover:border-slate-700"
                  }`}
                >
                  <div className={`mt-0.5 h-4 w-4 rounded flex items-center justify-center border shrink-0 ${
                    checklist.rojo ? "bg-emerald-500 border-emerald-400 text-white" : "border-slate-600"
                  }`}>
                    {checklist.rojo && <Check className="h-3 w-3" />}
                  </div>
                  <div>
                    <span className={`text-xs font-bold block ${checklist.rojo ? "text-slate-200 line-through" : "text-white"}`}>3. Spuštění Rojo</span>
                    <span className="text-[11px] block text-slate-400 mt-0.5">Inicializace Rojo synchronizačního serveru pro VS Code</span>
                  </div>
                </div>

                <div
                  onClick={() => toggleChecklist("plugin")}
                  className={`flex items-start gap-3 p-3 rounded-xl border cursor-pointer select-none transition-all duration-200 ${
                    checklist.plugin
                      ? "bg-emerald-500/5 border-emerald-500/20 text-slate-300"
                      : "bg-slate-900 border-slate-800 text-slate-400 hover:border-slate-700"
                  }`}
                >
                  <div className={`mt-0.5 h-4 w-4 rounded flex items-center justify-center border shrink-0 ${
                    checklist.plugin ? "bg-emerald-500 border-emerald-400 text-white" : "border-slate-600"
                  }`}>
                    {checklist.plugin && <Check className="h-3 w-3" />}
                  </div>
                  <div>
                    <span className={`text-xs font-bold block ${checklist.plugin ? "text-slate-200 line-through" : "text-white"}`}>4. Instalace ve Studiu</span>
                    <span className="text-[11px] block text-slate-400 mt-0.5">Připojení Rojo, uložení pluginu jako Local Plugin</span>
                  </div>
                </div>

              </div>

              {/* Progress bar */}
              <div className="bg-slate-900 p-4 rounded-xl border border-slate-800 space-y-2">
                <div className="flex justify-between text-xs font-bold text-slate-300">
                  <span>Celkový postup</span>
                  <span>{Math.round((Object.values(checklist).filter(Boolean).length / Object.keys(checklist).length) * 100)}%</span>
                </div>
                <div className="h-2 w-full bg-slate-950 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-gradient-to-r from-sky-500 to-indigo-500 transition-all duration-300"
                    style={{ width: `${(Object.values(checklist).filter(Boolean).length / Object.keys(checklist).length) * 100}%` }}
                  />
                </div>
              </div>
            </div>

            {/* Podrobné interaktivní panely s návody */}
            <div className="lg:col-span-2 space-y-6">
              
              {/* Krok 1 */}
              <div className="bg-slate-950 border border-slate-800 rounded-2xl p-5 space-y-3">
                <div className="flex items-center gap-2">
                  <span className="h-6 w-6 rounded bg-sky-500/10 text-sky-400 border border-sky-400/20 flex items-center justify-center text-xs font-bold">1</span>
                  <h4 className="font-bold text-white text-sm">Příprava Ollamy a stažení herního LLM modelu</h4>
                </div>
                <p className="text-xs text-slate-400 leading-relaxed">
                  Ollama běží přímo na vašem hardware a hostuje otevřené modely lokálně. Pro nejlepší výsledky doporučujeme řadu 
                  <strong> Qwen 2.5 Coder</strong> vyvinutou pro programování.
                </p>
                <div className="bg-slate-900 rounded-xl p-3 border border-slate-800 space-y-2 text-xs">
                  <span className="text-slate-400 font-medium">Spusťte v terminálu (PowerShell / Terminal):</span>
                  <div className="bg-slate-950 p-2.5 rounded-lg border border-slate-800 font-mono text-sky-300 flex items-center justify-between">
                    <span>ollama run qwen2.5-coder:14b</span>
                    <button
                      onClick={() => copyToClipboard("ollama run qwen2.5-coder:14b", "cmd-ollama")}
                      className="p-1 hover:bg-slate-800 rounded text-slate-400 hover:text-white transition-colors"
                    >
                      <Copy className="h-3.5 w-3.5" />
                    </button>
                  </div>
                </div>
              </div>

              {/* Krok 2 */}
              <div className="bg-slate-950 border border-slate-800 rounded-2xl p-5 space-y-3">
                <div className="flex items-center gap-2">
                  <span className="h-6 w-6 rounded bg-sky-500/10 text-sky-400 border border-sky-400/20 flex items-center justify-center text-xs font-bold">2</span>
                  <h4 className="font-bold text-white text-sm">Spuštění Python Flask Bridge serveru</h4>
                </div>
                <p className="text-xs text-slate-400 leading-relaxed">
                  Bridge server je nezbytný k tomu, aby mohl Roblox odesílat požadavky přes <code className="text-sky-400 font-mono">HttpService</code> bez bezpečnostních 
                  kontextových chyb. Spravuje připojení a formátování payloadů.
                </p>
                <div className="bg-slate-900 rounded-xl p-3 border border-slate-800 space-y-2 text-xs">
                  <span className="text-slate-400 font-medium">Stiskněte <code className="text-sky-400 font-mono">start.bat</code> nebo spusťte manuálně:</span>
                  <div className="bg-slate-950 p-2.5 rounded-lg border border-slate-800 font-mono text-sky-300 space-y-1.5">
                    <div>cd Roblox-AI-Assistant/Bridge</div>
                    <div>pip install -r requirements.txt</div>
                    <div>python bridge.py</div>
                  </div>
                </div>
              </div>

              {/* Krok 3 */}
              <div className="bg-slate-950 border border-slate-800 rounded-2xl p-5 space-y-3">
                <div className="flex items-center gap-2">
                  <span className="h-6 w-6 rounded bg-sky-500/10 text-sky-400 border border-sky-400/20 flex items-center justify-center text-xs font-bold">3</span>
                  <h4 className="font-bold text-white text-sm">Spuštění synchronizace přes Rojo a uložení pluginu</h4>
                </div>
                <p className="text-xs text-slate-400 leading-relaxed">
                  Rojo udržuje synchronizovanou složku vašeho lokálního disku se stromem herních instancí. Sestavení se provede jednoduše:
                </p>
                <div className="bg-slate-900 rounded-xl p-4 border border-slate-800 space-y-3 text-xs leading-relaxed">
                  <div className="flex gap-2">
                    <span className="font-bold text-sky-400">3a.</span>
                    <span>Ve složce projektu spusťte příkaz: <code className="text-sky-400 bg-slate-950 px-1.5 py-0.5 rounded font-mono">rojo serve Plugin/default.project.json</code></span>
                  </div>
                  <div className="flex gap-2">
                    <span className="font-bold text-sky-400">3b.</span>
                    <span>Otevřete Roblox Studio, spusťte Rojo Plugin a klikněte na <strong>Connect</strong>.</span>
                  </div>
                  <div className="flex gap-2">
                    <span className="font-bold text-sky-400">3c.</span>
                    <span>Klikněte pravým tlačítkem na složku <code className="text-sky-400 font-mono">RobloxAIAssistant</code> v Exploreru a zvolte <strong>Save as Local Plugin...</strong>.</span>
                  </div>
                </div>
              </div>

            </div>

          </div>
        )}

        {/* TAB 4: ARCHITEKTURA A SOLID DESIGN */}
        {activeTab === "architecture" && (
          <div className="space-y-6">
            
            {/* Úvodní architektonický blok */}
            <div className="bg-slate-950 border border-slate-800 rounded-2xl p-6 text-center max-w-3xl mx-auto space-y-3">
              <Layers className="h-10 w-10 text-sky-400 mx-auto" />
              <h3 className="font-bold text-white text-lg">SOLID Architektura & Rozdělení Zodpovědností</h3>
              <p className="text-xs text-slate-400 leading-relaxed">
                Tento Roblox plugin je navržen podle přísných pravidel čisté softwarové architektury. Každý soubor
                odpovídá jedné zodpovědnosti (Single Responsibility Principle) a komunikace probíhá skrz modularizované rozhraní.
              </p>
            </div>

            {/* Interaktivní grafická vizualizace */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              
              <div className="bg-slate-950 border border-slate-800 rounded-2xl p-5 space-y-3">
                <div className="flex items-center gap-2">
                  <div className="h-7 w-7 rounded bg-amber-500/10 border border-amber-400/20 flex items-center justify-center">
                    <Layers className="h-4 w-4 text-amber-400" />
                  </div>
                  <h4 className="font-bold text-white text-sm">Prezentační vrstva (UI)</h4>
                </div>
                <p className="text-xs text-slate-400 leading-relaxed">
                  Moduly odpovědné výhradně za zobrazení a interakci s uživatelem. Neobsahují žádné složité logiky generování ani přímé HTTP volání.
                </p>
                <ul className="text-xs space-y-2 text-slate-300 font-mono bg-slate-900 p-3 rounded-xl border border-slate-800/80">
                  <li className="flex items-center gap-1.5">
                    <span className="h-1.5 w-1.5 rounded-full bg-amber-400" />
                    <span>src/UI.lua (ChatGPT layout)</span>
                  </li>
                  <li className="flex items-center gap-1.5">
                    <span className="h-1.5 w-1.5 rounded-full bg-amber-400" />
                    <span>src/Widgets.lua (Plugin okno)</span>
                  </li>
                  <li className="flex items-center gap-1.5">
                    <span className="h-1.5 w-1.5 rounded-full bg-amber-400" />
                    <span>src/Theme.lua (Barvy Studia)</span>
                  </li>
                </ul>
              </div>

              <div className="bg-slate-950 border border-slate-800 rounded-2xl p-5 space-y-3">
                <div className="flex items-center gap-2">
                  <div className="h-7 w-7 rounded bg-sky-500/10 border border-sky-400/20 flex items-center justify-center">
                    <Cpu className="h-4 w-4 text-sky-400" />
                  </div>
                  <h4 className="font-bold text-white text-sm">Aplikační vrstva (Service)</h4>
                </div>
                <p className="text-xs text-slate-400 leading-relaxed">
                  Orchestrátor komunikace a aplikační logiky. Připravují dotazy, odesílají payloady, spravují perzistentní nastavení.
                </p>
                <ul className="text-xs space-y-2 text-slate-300 font-mono bg-slate-900 p-3 rounded-xl border border-slate-800/80">
                  <li className="flex items-center gap-1.5">
                    <span className="h-1.5 w-1.5 rounded-full bg-sky-400" />
                    <span>src/Api.lua (HTTP klient)</span>
                  </li>
                  <li className="flex items-center gap-1.5">
                    <span className="h-1.5 w-1.5 rounded-full bg-sky-400" />
                    <span>src/Settings.lua (Konfigurace)</span>
                  </li>
                  <li className="flex items-center gap-1.5">
                    <span className="h-1.5 w-1.5 rounded-full bg-sky-400" />
                    <span>src/Main.server.lua (Entrypoint)</span>
                  </li>
                </ul>
              </div>

              <div className="bg-slate-950 border border-slate-800 rounded-2xl p-5 space-y-3">
                <div className="flex items-center gap-2">
                  <div className="h-7 w-7 rounded bg-emerald-500/10 border border-emerald-400/20 flex items-center justify-center">
                    <Code className="h-4 w-4 text-emerald-400" />
                  </div>
                  <h4 className="font-bold text-white text-sm">Výměna kódu a Workspace</h4>
                </div>
                <p className="text-xs text-slate-400 leading-relaxed">
                  Moduly provádějící zápisy a čtení z Roblox Studio instancí (Explorer). Využívají historii změn pro zpětnou kompatibilitu.
                </p>
                <ul className="text-xs space-y-2 text-slate-300 font-mono bg-slate-900 p-3 rounded-xl border border-slate-800/80">
                  <li className="flex items-center gap-1.5">
                    <span className="h-1.5 w-1.5 rounded-full bg-emerald-400" />
                    <span>src/Insert.lua (Zápis s Undo)</span>
                  </li>
                  <li className="flex items-center gap-1.5">
                    <span className="h-1.5 w-1.5 rounded-full bg-emerald-400" />
                    <span>src/Fix.lua (Opravné promptování)</span>
                  </li>
                  <li className="flex items-center gap-1.5">
                    <span className="h-1.5 w-1.5 rounded-full bg-emerald-400" />
                    <span>src/Explain.lua (Krok-za-krokem analýza)</span>
                  </li>
                </ul>
              </div>

            </div>

          </div>
        )}

      </main>

      {/* Spodní zápatí */}
      <footer className="border-t border-slate-800 bg-slate-950/40 py-6 text-center text-xs text-slate-500">
        <div className="max-w-7xl mx-auto px-4 flex flex-col sm:flex-row items-center justify-between gap-4">
          <span>&copy; 2026 Roblox AI Assistant - Kompletní open-source projekt. Všechna práva vyhrazena.</span>
          <div className="flex items-center gap-4">
            <span className="bg-emerald-500/10 text-emerald-400 px-2.5 py-0.5 rounded-full border border-emerald-400/10 text-[10px] font-bold">LOKÁLNÍ OLLAMA API</span>
            <span className="bg-sky-500/10 text-sky-400 px-2.5 py-0.5 rounded-full border border-sky-400/10 text-[10px] font-bold">ROJO SYNC COMPATIBLE</span>
          </div>
        </div>
      </footer>

    </div>
  );
}

// Chybějící pomocná ikona "Wrench" z lucide-react pro "Opravit"
function WrenchIcon(props: React.SVGProps<SVGSVGElement>) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      {...props}
    >
      <path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z" />
    </svg>
  );
}
