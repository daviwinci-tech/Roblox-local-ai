# Roblox AI Assistant 🤖🎮

[Česká verze níže / Czech version below]

### 🇺🇸 English Version

Welcome to the **Roblox AI Assistant** plugin folder! This directory contains the complete source code, configurations, and backend bridge scripts to run the local AI Coding Assistant inside Roblox Studio.

This project is a fully local and highly secure AI coding assistant integrated directly into **Roblox Studio** (2025+). It runs entirely offline, meaning **your game code never leaves your computer**. It uses **Ollama** on your local machine to run powerful LLM models (such as `qwen2.5-coder:14b`) and a lightweight **Python Flask backend** acting as a secure bridge.

---

## 📂 Repository Structure & Folder Contents
You are currently inside the `Roblox-AI-Assistant` folder. This is the main package folder containing the plugin:
- **`src/`**: Contains the Luau source code modules for the Roblox Studio Plugin (`Main.server.lua`, `UI.lua`, `Api.lua`, `Theme.lua`, `Settings.lua`, etc.).
- **`backend/`**: Contains the Python Flask bridge server (`app.py`).
- **`default.project.json`**: Rojo configuration file for compilation and syncing.
- **`requirements.txt`**: Python dependencies list.

---

## 🛠️ Quick Start Guide (English)

### 1. Install Ollama and Download a Model
1. Download and install [Ollama](https://ollama.com/) for your OS.
2. Open your terminal and pull the recommended coding model:
   ```bash
   ollama run qwen2.5-coder:14b
   ```
   *(For PCs with less RAM/VRAM, you can use smaller variants like `qwen2.5-coder:7b` or `qwen2.5-coder:1.5b`.)*

### 2. Run the Python Backend Bridge
Navigate to this folder in your terminal and launch the Flask server:
```bash
pip install -r requirements.txt
python backend/app.py
```
The server will start at `http://127.0.0.1:5000`.

### 3. Sync to Roblox Studio via Rojo
Build and serve the plugin using Rojo from this folder:
```bash
rojo plugin install
rojo serve
```

### 4. Connect in Roblox Studio
1. Open your Roblox Studio place.
2. Open the **Rojo** plugin panel and click **Connect**.
3. The plugin will immediately load into your project. An AI Assistant button will appear in your top bar.
4. Save it as a permanent local plugin by right-clicking on the loaded folder in your Explorer and selecting **Save as Local Plugin...**.

---

### 🇨🇿 Česká verze

Vítejte v adresáři **Roblox AI Assistant**! Tato složka obsahuje kompletní zdrojové kódy, konfigurace a skripty backendového bridge pro spuštění lokálního AI pomocníka přímo v Roblox Studio.

Tento projekt je plně lokální a vysoce zabezpečený AI programovací asistent integrovaný přímo do **Roblox Studio** (2025+). Funguje jako integrovaný plugin s moderním rozhraním, který komunikuje s lokálně běžícím LLM modelem (především `qwen2.5-coder:14b`) skrze nástroj **Ollama** a lehký **Python Flask backend**.

Celý projekt běží offline – **žádný váš kód neopustí váš počítač!**

---

## 📂 Obsah této složky
Právě se nacházíte ve složce `Roblox-AI-Assistant`, která je hlavním balíčkem projektu:
- **`src/`**: Obsahuje zdrojové kódy v Luau pro Roblox Studio Plugin (`Main.server.lua`, `UI.lua`, `Api.lua`, `Theme.lua`, `Settings.lua`, atd.).
- **`backend/`**: Obsahuje Python Flask bridge server (`app.py`).
- **`default.project.json`**: Konfigurační soubor Rojo pro synchronizaci a sestavení.
- **`requirements.txt`**: Seznam Python závislostí.

---

## 🛠️ Rychlý návod k instalaci (Čeština)

### 1. Příprava Ollamy a stažení modelu
1. Stáhněte a nainstalujte si [Ollamu](https://ollama.com/).
2. Spusťte terminál a stáhněte doporučený model:
   ```bash
   ollama run qwen2.5-coder:14b
   ```
   *(Pro méně výkonné počítače s menší RAM/VRAM můžete použít `qwen2.5-coder:7b` nebo `qwen2.5-coder:1.5b`.)*

### 2. Spuštění Python Backend serveru
Přejděte v terminálu do této složky a spusťte Flask server:
```bash
pip install -r requirements.txt
python backend/app.py
```
Server se spustí na adrese `http://127.0.0.1:5000`.

### 3. Synchronizace do Roblox Studio přes Rojo
Sestavte a spusťte Rojo server z této složky:
```bash
rojo plugin install
rojo serve
```

### 4. Propojení v Roblox Studiu
1. Otevřete **Roblox Studio** a váš projekt.
2. V panelu pluginu **Rojo** stiskněte **Connect**.
3. Plugin se okamžitě nahraje a v horní liště se objeví tlačítko **AI Assistant**.
4. Uložte ho jako trvalý lokální plugin kliknutím pravým tlačítkem na složku v Exploreru a zvolením **Save as Local Plugin...**.

---

## 💡 Features / Funkce
* **Interactive Chat / Interaktivní Chat**: Context-aware chat with direct code insertion into open scripts / Kontextový chat s přímým vkládáním kódu do otevřených skriptů.
* **Auto-Fix / Automatická oprava**: Analyze and fix syntax or logical bugs in selected explorer scripts / Analyzuje a opravuje syntaktické i logické chyby ve vybraných skriptech.
* **Explain Code / Vysvětlení kódu**: Explain complex Luau logic, events, and services step-by-step / Krok za krokem vysvětluje složitou Luau logiku, události a služby.
* **Smart Context / Kontext výběru**: The assistant automatically detects which object is selected in Roblox Studio Explorer / Asistent automaticky rozpozná, jaký objekt máte označený v Roblox Studio Exploreru.
* **Connection Health / Diagnostika**: Validate connections with Ollama and list active local models directly from Settings / Ověření spojení s Ollamou a výpis aktivních lokálních modelů přímo v Nastavení.

---

## 📄 License / Licence
MIT License. Feel free to modify and build upon this project! / MIT Licence. Projekt můžete volně upravovat a stavět na něm!
