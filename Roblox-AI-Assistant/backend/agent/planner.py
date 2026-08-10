import json
import re
from agent.tools import format_tools_for_system_prompt

SYSTEM_AGENT_PROMPT = """Jsi zkušený seniorní Roblox Studio AI Developer & Architect s 30 lety vývojářské praxe.
Tvým úkolem je autonomně vyřešit zadání uživatele v Roblox projektu.

Postupuj strukturovaně:
1. Nejdříve prozkoumej projekt, vyhledej relevantní skripty, RemoteEvents nebo objekty.
2. Přečti si zdrojové kódy nalezených skriptů.
3. Analyzuj možnou příčinu problému nebo chybějící funkci.
4. Pokud je potřeba upravit nebo vytvořit skript, použij `edit_script` nebo `create_script`.
5. Uživatel uvidí změny jako diff a schválí je.
6. Po provedení změn dokonči úkol nástrojem `finish_task`.

{tools_description}

DŮLEŽITÉ:
- Neodhaduj kód naslepo, vždy nejprve přečti skript přes `read_script` nebo vyhledej přes `search_scripts` / `grep_scripts`.
- Odpovídej VŽDY v validním JSON formátu dle specifikace nahoře!
- Luau kód v `edit_script` musí být kompletní, plně funkční a syntakticky správný.
"""

def build_system_prompt():
    tools_desc = format_tools_for_system_prompt()
    return SYSTEM_AGENT_PROMPT.format(tools_description=tools_desc)

def parse_llm_response(text: str):
    """
    Extrahuje JSON s akcí z odpovědi LLM.
    Zvládá různé formáty zápisu (kódové bloky ```json ... ``` i přímý JSON).
    """
    if not text:
        return {"thought": "Prázdná odpověď od modelu.", "action": None, "action_input": {}}

    # Pokus o vytažení z kódového bloku ```json ... ```
    json_match = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", text, re.DOTALL)
    if json_match:
        raw_json = json_match.group(1)
    else:
        # Vyhledání prvního { a posledního }
        start_idx = text.find("{")
        end_idx = text.rfind("}")
        if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
            raw_json = text[start_idx:end_idx+1]
        else:
            raw_json = text

    try:
        data = json.loads(raw_json)
        thought = data.get("thought", "Analyzuji stav...")
        action = data.get("action")
        action_input = data.get("action_input", {})
        return {
            "thought": thought,
            "action": action,
            "action_input": action_input,
            "raw_text": text
        }
    except Exception as e:
        # Fallback pokud model nevrátil čistý JSON
        return {
            "thought": text,
            "action": None,
            "action_input": {},
            "raw_text": text,
            "parse_error": str(e)
        }
