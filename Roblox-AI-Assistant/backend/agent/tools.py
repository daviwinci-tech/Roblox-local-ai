"""
Definice nástrojů (Tools) pro Roblox AI Agenta.
Každé volání nástroje má unikátní název, popis a schéma parametrů.
"""

AVAILABLE_TOOLS = {
    "get_explorer_tree": {
        "name": "get_explorer_tree",
        "description": "Získá hierarchický strom objektů a skriptů z Roblox DataModelu pro zadanou službu (např. Workspace, ReplicatedStorage, ServerScriptService, StarterPlayer).",
        "parameters": {
            "root_service": {"type": "string", "description": "Název služby, např. 'ServerScriptService', 'ReplicatedStorage', 'Workspace'"},
            "max_depth": {"type": "integer", "description": "Maximální hloubka prohledávání (výchozí 2)"}
        }
    },
    "read_script": {
        "name": "read_script",
        "description": "Přečte kompletní zdrojový kód zadaného skriptu na základě jeho cesty v Roblox Studio (např. 'ServerScriptService.MiningServer').",
        "parameters": {
            "path": {"type": "string", "description": "Celá cesta k objektu v Roblox Studio (např. 'ReplicatedStorage.Modules.MiningConfig')"}
        }
    },
    "search_scripts": {
        "name": "search_scripts",
        "description": "Vyhledá skripty podle názvu nebo typu v celém projektu.",
        "parameters": {
            "query": {"type": "string", "description": "Název skriptu nebo hledaný řetězec v názvu (např. 'Mining')"}
        }
    },
    "grep_scripts": {
        "name": "grep_scripts",
        "description": "Prohledá zdrojové kódy všech skriptů v projektu a vrátí řádky obsahující daný text nebo název události (např. 'MineRockEvent').",
        "parameters": {
            "pattern": {"type": "string", "description": "Hledaný řetězec nebo název RemoteEvent/funkce"}
        }
    },
    "get_properties": {
        "name": "get_properties",
        "description": "Získá klíčové vlastnosti konkrétního objektu (ClassName, Name, Parent, atd.).",
        "parameters": {
            "path": {"type": "string", "description": "Cesta k objektu"}
        }
    },
    "get_selection": {
        "name": "get_selection",
        "description": "Získá aktuálně označené objekty v Roblox Studio Exploreru.",
        "parameters": {}
    },
    "get_output_logs": {
        "name": "get_output_logs",
        "description": "Získá nedávné chyby a zprávy z konzole Roblox Studio Output (posledních N řádků).",
        "parameters": {
            "lines": {"type": "integer", "description": "Počet řádků k přečtení (výchozí 20)"}
        }
    },
    "edit_script": {
        "name": "edit_script",
        "description": "Navrhne úpravu zdrojového kódu skriptu. Uživatel uvidí rozdíl (diff) a bude požádán o schválení.",
        "parameters": {
            "path": {"type": "string", "description": "Cesta ke skriptu ke změně"},
            "new_source": {"type": "string", "description": "Nový kompletní zdrojový kód Luau"},
            "reason": {"type": "string", "description": "Stručný důvod, proč tuto změnu provádíme"}
        }
    },
    "create_script": {
        "name": "create_script",
        "description": "Vytvoří nový skript v zadaném umístění po schválení uživatelem.",
        "parameters": {
            "parent_path": {"type": "string", "description": "Rodičovský objekt (např. 'ServerScriptService')"},
            "name": {"type": "string", "description": "Název nového skriptu"},
            "script_type": {"type": "string", "description": "'Script', 'LocalScript', nebo 'ModuleScript'"},
            "source": {"type": "string", "description": "Výchozí zdrojový kód Luau"}
        }
    },
    "finish_task": {
        "name": "finish_task",
        "description": "Ukončí agentní smyčku a předloží uživateli finální shrnutí vyřešeného úkolu.",
        "parameters": {
            "summary": {"type": "string", "description": "Závěrečná zpráva pro uživatele se shrnutím změn a výsledků"}
        }
    }
}

def format_tools_for_system_prompt():
    """Formátuje nástroje do srozumitelné instrukce pro jakýkoliv lokální LLM."""
    lines = ["Dostupné nástroje (Tools), které můžeš použít pro splnění úkolu:\n"]
    for t_name, tool in AVAILABLE_TOOLS.items():
        lines.append(f"Tool: `{t_name}`")
        lines.append(f"Popis: {tool['description']}")
        lines.append("Parametry (JSON):")
        for p_name, p_info in tool["parameters"].items():
            lines.append(f"  - `{p_name}` ({p_info['type']}): {p_info['description']}")
        lines.append("")
        
    lines.append("POKYNY PRO VOLÁNÍ TOOLU:")
    lines.append("Pokud chceš použít nástroj, odpusť si omáčku a vlož do odpovědi JSON v následujícím formátu:\n")
    lines.append("```json")
    lines.append("{")
    lines.append('  "thought": "Zde napiš své uvažování a co hodláš udělat.",')
    lines.append('  "action": "nazev_toolu",')
    lines.append('  "action_input": { "parametr1": "hodnota1" }')
    lines.append("}")
    lines.append("```\n")
    lines.append("Pokud máš dostatek informací a úkol je hotov, zavolej tool `finish_task` s finálním shrnutím.")
    return "\n".join(lines)
