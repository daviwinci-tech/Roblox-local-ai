# Roblox AI Local Agent 🤖🎮 (david.windsedl.cz)

![Roblox AI Local Agent Preview](/src/assets/images/roblox_agent_preview_1786321753955.jpg)

[Česká verze níže / Czech version below]

### 🇺🇸 English Version

Welcome to the **Roblox AI Local Agent** project! This directory contains the complete source code, agentic engine, tools, and backend bridge scripts to run an autonomous local AI Development Agent inside **Roblox Studio**.

This project is a fully local, privacy-first AI agent integrated directly into **Roblox Studio** (2025+). Unlike basic chat scripts, this agent can inspect your project hierarchy, search scripts across services, analyze dependencies, propose code edits with full Diff previews, and apply modifications safely using `ChangeHistoryService` undo points.

---

## 📂 Repository Structure & Folder Contents
- **`src/`**: Contains the Luau source code modules for the Roblox Studio Plugin:
  - `Main.server.lua`: Plugin entry point & toolbar button.
  - `UI.lua`: Tabbed interface (Chat Mode & Agent Mode) with step logs & diff approval modal.
  - `Api.lua`: Async HTTP client for backend communicate & agent state synchronization.
  - `Tools.lua`: Studio execution layer for tools (`read_script`, `grep_scripts`, `search_scripts`, `get_explorer_tree`, `edit_script`, `create_script`).
  - `Diff.lua`: Luau diff generator for side-by-side code review.
  - `Theme.lua`, `Settings.lua`, `Widgets.lua`, `Insert.lua`, `Fix.lua`, `Explain.lua`.
- **`backend/`**: Python Flask Agent Server:
  - `app.py`: REST API endpoints (`/health`, `/chat`, `/agent/start`, `/agent/step`, `/agent/approve`, `/agent/reject`, `/agent/status`).
  - `config.py`: Local configuration manager.
  - `agent/agent.py`: Agent Engine orchestrating tool calling & execution loops.
  - `agent/planner.py`: System prompt builder & LLM JSON action parser.
  - `agent/state.py`: Structured task state & pending diffs manager.
  - `agent/tools.py`: Tool definitions & schemas.
- **`default.project.json`**: Rojo compilation config.
- **`requirements.txt`**: Python dependencies list (`flask`, `flask-cors`, `requests`).

---

## 🛠️ Quick Start Guide (English)

### 1. Install Ollama and Download a Model
```bash
ollama run qwen2.5-coder:14b
```

### 2. Run the Python Agent Backend
```bash
pip install -r requirements.txt
python backend/app.py
```
The server will start locally at `http://127.0.0.1:5000`.

### 3. Sync to Roblox Studio via Rojo
```bash
rojo plugin install
rojo serve
```

---

### 🇨🇿 Česká verze

Vítejte v projektu **Roblox AI Local Agent**! Tato složka obsahuje kompletní zdrojové kódy, agentní engine, nástroje a backend bridge pro spuštění autonomního lokálního AI vývojového agenta v **Roblox Studio**.

Na rozdíl od obyčejného chatu dokáže tento AI Agent:
1. Prohledat hierarchii vašeho Roblox projektu (`Workspace`, `ServerScriptService`, `ReplicatedStorage`, atd.).
2. Přečíst zdrojové kódy skriptů a vyhledat události (např. `RemoteEvent`).
3. Analyzovat chyby a logy z konzole.
4. Navrhnout úpravu kódu v podrobném náhledu rozdílů (**Diff**).
5. Po vašem schválení úpravu bezpečně zapsat s možností vrátit zpět (Undo přes `ChangeHistoryService`).

---

## 💡 Hlavní Funkce / Core Features
* **🤖 Agent Mód (Autonomous Agent Loop)**: Zadejte úkol např. *"Oprav mining systém a zkontroluj RemoteEvents"* a agent autonomně projde kód, najde chyby a navrhne řešení.
* **🔎 Project Context & Search**: Nástroje `grep_scripts`, `search_scripts` a `get_explorer_tree` umožňují agentovi okamžitě pochopit strukturu hry.
* **🛡️ Safe Editing & Diff Approval**: Žádné destruktivní přepisy bez vašeho vědomí! Každá změna vyžaduje explicitní tlačítko **[Aplikovat Změnu]**.
* **💬 Chat Mód**: Rychlé dotazy k Luau syntaxi a službám Robloxu.
* **🔒 100% Offline & Privacy First**: Vše běžé lokálně přes Ollamu.
