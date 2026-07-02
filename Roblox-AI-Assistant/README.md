# Roblox AI Assistant 🤖🎮

**Roblox AI Assistant** je plně lokální a vysoce zabezpečený AI programovací asistent integrovaný přímo do **Roblox Studio** (2025+). Funguje jako integrovaný plugin s moderním rozhraním ve stylu ChatGPT, který komunikuje s lokálně běžícím LLM modelem (především `qwen2.5-coder:14b`) skrze nástroj **Ollama** a lehký **Python Flask backend**.

Tento projekt je open-source a navržen pro plný offline provoz – **žádný váš kód neopustí váš počítač!**

---

## 🏗️ Architektura projektu

Projekt se skládá ze dvou hlavních částí:
1. **Python Backend (Flask):** Běží na pozadí na portu `5000` a slouží jako překladač mezi HttpService požadavky z Roblox Studia a lokálním API rozhraním Ollamy běžící na portu `11434`. Implementuje endpointy `/health`, `/chat`, `/generate`, `/fix` a `/explain`.
2. **Roblox Plugin (Luau):** Samotný plugin nainstalovaný do vašeho Roblox Studia. Obsahuje moderní GUI okno, které se plně integruje do designu Studia (podpora Dark/Light módu), podporuje historii konverzace, typewriter efekt pro plynulé psaní, a umožňuje vkládání kódu přímo do skriptů na jedno kliknutí.

---

## 🛠️ Rychlé spuštění krok za krokem

### 1. Krok: Příprava Ollamy a stažení modelu
1. Stáhněte a nainstalujte si [Ollamu](https://ollama.com/) (pro Windows, macOS nebo Linux).
2. Spusťte terminál (PowerShell / CMD) a stáhněte si doporučený model optimalizovaný pro kód:
   ```bash
   ollama run qwen2.5-coder:14b
   ```
   *(Pokud máte méně paměti RAM/VRAM, můžete použít menší verzi `qwen2.5-coder:7b` nebo `qwen2.5-coder:1.5b`.)*
3. Nechte Ollamu běžet na pozadí.

### 2. Krok: Spuštění Python Backend serveru
V kořenovém adresáři projektu spusťte následující příkazy:
```bash
pip install -r requirements.txt
python backend/app.py
```
Backend se úspěšně spustí na adrese `http://127.0.0.1:5000`.

### 3. Krok: Instalace a spuštění Rojo serveru
Rojo zajišťuje přímou synchronizaci kódu do Roblox Studia. V kořeni projektu spusťte:
```bash
rojo plugin install
rojo serve
```

### 4. Krok: Propojení v Roblox Studiu
1. Otevřete **Roblox Studio** a váš projekt.
2. Klikněte na panel **Rojo** pluginu a stiskněte **Connect**.
3. Plugin se okamžitě nahraje do vašeho projektu a v horní liště se objeví záložka **Roblox AI Assistant** s ikonou.
4. Nyní můžete plugin uložit jako lokální plugin kliknutím pravým tlačítkem na složku pluginu v Exploreru a zvolením **Save as Local Plugin...**.

---

## 💡 Hlavní funkce a jak je používat

1. **Chat s AI (Generovat):**
   Napište do textového pole, co má skript dělat, a stiskněte **Generovat**. AI vygeneruje kód, který si můžete přečíst v chatu. Chat plně podporuje historii konverzace – asistent si pamatuje předchozí zprávy!

2. **Přímé vložení (Vložit do Scriptu):**
   Po vygenerování kódu stačí kliknout na tlačítko **Vložit do Scriptu**. Pokud máte otevřený a vybraný nějaký skript v Exploreru, kód se vloží přímo do něj. Pokud vybraný skript nemáte, plugin automaticky vytvoří nový skript v `ServerScriptService`.

3. **Opravit skript:**
   Vyberte libovolný skript v Exploreru a klikněte na **Opravit skript**. AI asistent zanalyzuje váš kód, opraví syntaktické i logické chyby, optimalizuje ho a vloží opravenou verzi zpět s vysvětlujícími komentáři v češtině.

4. **Vysvětlit skript:**
   Vyberte libovolný skript v Exploreru a klikněte na tlačítko **Vysvětlit**. Asistent vám v chatu krok za krokem rozepíše logiku skriptu, popíše použité herní služby a události.

5. **Nastavení a kontrola připojení:**
   V záložce **Nastavení** můžete změnit název používaného modelu, port/adresu backend serveru a jedním kliknutím na **Test připojení** ověřit stav spojení s backendem i Ollamou. Všechna nastavení se automaticky perzistentně ukládají.

---

## 🔒 Bezpečnost a SOLID design

* **100% Soukromí:** Veškerá data jsou zpracovávána lokálně na vašem PC. Žádné zdrojové kódy vaší hry se neposílají na servery třetích stran.
* **SOLID design:** Kód pluginu je rozdělen do modulárních `ModuleScriptů` (každý plní pouze jednu zodpovědnost):
  * `Api.lua` se stará pouze o síťovou komunikaci.
  * `Theme.lua` spravuje design a integraci vzhledu.
  * `Insert.lua` zajišťuje bezpečné zápisy do instancí s waypointy pro historii.
  * `UI.lua` vykresluje a spravuje stavy prvků.
  * `Settings.lua` spravuje perzistentní ukládání přes plugin API.

---

## 📄 Licence
Tento projekt je uvolněn pod svobodnou licencí **MIT**. Podrobnosti naleznete v souboru `LICENSE`.
