# Roblox AI Assistant 🤖🎮
Author : David Windšedl 


[Česká verze níže / Czech version below]

### 🇺🇸 English Version

Welcome to the **Roblox AI Assistant** repository!

This project is a fully local and highly secure AI coding assistant integrated directly into **Roblox Studio** (2025+). It runs entirely offline, meaning **your game code never leaves your computer**. It uses **Ollama** on your local machine to run powerful LLM models (such as `qwen2.5-coder:14b`) and a lightweight **Python Flask backend** acting as a secure bridge.

---

### 📂 Repository Structure & Application Location
> [!IMPORTANT]
> **The entire Roblox AI Assistant application** (including the Roblox Plugin Luau source code, the Python Flask backend server, and setup configurations) **is located inside the [`Roblox-AI-Assistant`](./Roblox-AI-Assistant) folder.**
>
> - **[`Roblox-AI-Assistant/src/`](./Roblox-AI-Assistant/src/)**: Contains the Luau source code modules for the Roblox Studio Plugin (`Main.server.lua`, `UI.lua`, `Api.lua`, `Theme.lua`, `Settings.lua`, etc.).
> - **[`Roblox-AI-Assistant/backend/`](./Roblox-AI-Assistant/backend/)**: Contains the Python Flask bridge server (`app.py`).
> - **[`Roblox-AI-Assistant/default.project.json`](./Roblox-AI-Assistant/default.project.json)**: Rojo configuration file for compilation and syncing.
> - **[`src/`](./src/) / [`server.ts`](./server.ts)**: This root directory contains a lightweight web-based companion page designed to guide you through installation, explain configuration steps, and run local connectivity diagnostics directly from your browser.

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
Navigate to the plugin directory and launch the Flask server:
```bash
cd Roblox-AI-Assistant
pip install -r requirements.txt
python backend/app.py
```
The server will start at `http://127.0.0.1:5000`.

### 3. Sync to Roblox Studio via Rojo
Build and serve the plugin using Rojo:
```bash
cd Roblox-AI-Assistant
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

Vítejte v repozitáři **Roblox AI Assistant**!

Tento projekt je plně lokální a vysoce zabezpečený AI programovací asistent integrovaný přímo do **Roblox Studio** (2025+). Funguje jako integrovaný plugin s moderním rozhraním, který komunikuje s lokálně běžícím LLM modelem (především `qwen2.5-coder:14b`) skrze nástroj **Ollama** a lehký **Python Flask backend**.

Celý projekt běží offline – **žádný váš kód neopustí váš počítač!**

---

### 📂 Struktura repozitáře a umístění aplikace
> [!IMPORTANT]
> **Celá aplikace Roblox AI Assistant** (včetně zdrojových kódů Roblox pluginu v Luau, Python Flask backend serveru a konfiguračních souborů) **se nachází uvnitř složky [`Roblox-AI-Assistant`](./Roblox-AI-Assistant).**
>
> - **[`Roblox-AI-Assistant/src/`](./Roblox-AI-Assistant/src/)**: Obsahuje zdrojové kódy v Luau pro Roblox Studio Plugin (`Main.server.lua`, `UI.lua`, `Api.lua`, `Theme.lua`, `Settings.lua`, atd.).
> - **[`Roblox-AI-Assistant/backend/`](./Roblox-AI-Assistant/backend/)**: Obsahuje Python Flask bridge server (`app.py`).
> - **[`Roblox-AI-Assistant/default.project.json`](./Roblox-AI-Assistant/default.project.json)**: Konfigurační soubor Rojo pro synchronizaci a sestavení.
> - **[`src/`](./src/) / [`server.ts`](./server.ts)**: Kořenový adresář obsahuje doprovodnou webovou stránku, která slouží jako interaktivní průvodce instalací a diagnostický nástroj pro ověření funkčnosti lokálního připojení z prohlížeče.

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
Přejděte do složky pluginu a spusťte Flask server:
```bash
cd Roblox-AI-Assistant
pip install -r requirements.txt
python backend/app.py
```
Server se spustí na adrese `http://127.0.0.1:5000`.

### 3. Synchronizace do Roblox Studio přes Rojo
Sestavte a spusťte Rojo server:
```bash
cd Roblox-AI-Assistant
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
