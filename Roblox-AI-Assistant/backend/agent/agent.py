import time
import requests
import uuid
from agent.state import AgentState, AgentStatus
from agent.planner import build_system_prompt, parse_llm_response
from config import load_config

# Repozitář aktivních agentních úloh v paměti backendu
ACTIVE_TASKS = {}

class AgentEngine:
    def __init__(self, http_session: requests.Session):
        self.session = http_session
        self.config = load_config()

    def start_task(self, goal: str) -> AgentState:
        task_id = str(uuid.uuid4())[:8]
        state = AgentState(task_id, goal)
        state.max_iterations = self.config.get("max_agent_iterations", 20)
        
        # Inicializace konverzace
        system_prompt = build_system_prompt()
        state.messages.append({"role": "system", "content": system_prompt})
        state.messages.append({"role": "user", "content": f"Úkol: {goal}\nZapočni analýzu a zvol první výhodný krok/nástroj."})
        
        state.add_log("info", f"Agent zahájil úkol: '{goal}'", details={"task_id": task_id})
        ACTIVE_TASKS[task_id] = state
        return state

    def get_task(self, task_id: str) -> AgentState:
        return ACTIVE_TASKS.get(task_id)

    def execute_next_step(self, task_id: str, tool_result_override=None) -> dict:
        """
        Spustí další iteraci LLM v agentní smyčce.
        Pokud byl předchozí krok voláním nástroje v Roblox Studio, `tool_result_override` obsahuje výsledek.
        """
        state = self.get_task(task_id)
        if not state:
            return {"error": f"Úkol {task_id} nebyl nalezen."}

        if state.status in [AgentStatus.COMPLETED, AgentStatus.FAILED, AgentStatus.STOPPED]:
            return {"status": state.status, "message": "Úkol je již ukončen."}

        if state.status == AgentStatus.WAITING_FOR_APPROVAL:
            return {"status": state.status, "message": "Čekám na schválení uživatele pro navrženou úpravu."}

        if state.iteration >= state.max_iterations:
            state.status = AgentStatus.FAILED
            state.error_message = f"Dosažen maximální limit {state.max_iterations} iterací."
            state.add_log("error", state.error_message)
            return state.to_dict()

        state.iteration += 1

        # Pokud jsme dostali výsledek nástroje od Roblox Studio
        if tool_result_override is not None:
            tool_msg = f"Výsledek nástroje (Tool Output):\n{tool_result_override}"
            state.messages.append({"role": "user", "content": tool_msg})
            state.add_log("info", "Obdržen výsledek z Roblox Studio pluginu.")

        # Odeslání dotazu do Ollamy
        ollama_base = self.config.get("ollama_base_url", "http://127.0.0.1:11434").rstrip("/")
        model = self.config.get("default_model", "qwen2.5-coder:14b")
        
        payload = {
            "model": model,
            "messages": state.messages,
            "stream": False,
            "options": {
                "temperature": self.config.get("temperature", 0.2)
            }
        }

        try:
            state.add_log("info", f"Uvažuji... (Iterace {state.iteration}/{state.max_iterations})")
            resp = self.session.post(f"{ollama_base}/api/chat", json=payload, timeout=self.config.get("timeout", 90))
            
            if resp.status_code != 200:
                # Zkusíme fallback model
                fallback = self.config.get("fallback_model", "qwen2.5-coder:7b")
                state.add_log("warning", f"Hlavní model selhal ({resp.status_code}). Zkouším fallback model: {fallback}")
                payload["model"] = fallback
                resp = self.session.post(f"{ollama_base}/api/chat", json=payload, timeout=self.config.get("timeout", 90))
                
            if resp.status_code != 200:
                raise Exception(f"Ollama vrátila status kód {resp.status_code}")

            res_json = resp.json()
            ai_content = res_json.get("message", {}).get("content", "")
            
            # Uložíme AI odpověď do konverzace
            state.messages.append({"role": "assistant", "content": ai_content})
            
            # Analyzujeme akci
            parsed = parse_llm_response(ai_content)
            thought = parsed.get("thought", "")
            action = parsed.get("action")
            action_input = parsed.get("action_input", {})

            if thought:
                state.add_log("info", f"💡 Myšlenka agenta: {thought}")

            if not action:
                # Pokud model nevrátil akci, vyzveme ho k volání nástroje
                state.messages.append({
                    "role": "user",
                    "content": "Aktivně zvol konkrétní nástroj (action) ve výše určeném JSON formátu nebo dokonči úkol přes `finish_task`."
                })
                return state.to_dict()

            state.add_log("tool", f"🛠️ Požadavek na spuštění toolu: `{action}`", details=action_input)

            # Vyhodnocení typu akce
            if action == "finish_task":
                summary = action_input.get("summary", "Úkol byl dokončen.")
                state.status = AgentStatus.COMPLETED
                state.add_log("success", f"🎉 Úkol úspěšně dokončen: {summary}")
                return state.to_dict()

            elif action == "edit_script":
                path = action_input.get("path")
                new_source = action_input.get("new_source", "")
                reason = action_input.get("reason", "Úprava kódu podle požadavku.")
                
                # Vyžaduje spuštění read_script pro získání původního kódu, pokud ho ještě nemáme
                state.status = AgentStatus.EDITING
                
                # Zaznamenáme požadavek na úpravu k potvrzení uživatelem
                state.add_pending_diff(
                    path=path,
                    old_source="-- Zjišťuji původní stav...",
                    new_source=new_source,
                    description=reason
                )
                return state.to_dict()

            elif action == "create_script":
                parent_path = action_input.get("parent_path", "ServerScriptService")
                name = action_input.get("name", "NewScript")
                script_type = action_input.get("script_type", "Script")
                source = action_input.get("source", "")
                
                full_path = f"{parent_path}.{name}"
                state.status = AgentStatus.EDITING
                state.add_pending_diff(
                    path=full_path,
                    old_source="-- (Nový skript)",
                    new_source=source,
                    description=f"Vytvoření nového {script_type} skriptu v {parent_path}"
                )
                return state.to_dict()

            else:
                # Ostatní nástroje (get_explorer_tree, read_script, search_scripts, grep_scripts, get_properties, get_output_logs)
                # Tyto nástroje musí vykonat Roblox Studio Plugin!
                state.status = AgentStatus.INVESTIGATING
                return {
                    "action_required": "execute_in_roblox",
                    "action": action,
                    "action_input": action_input,
                    "state": state.to_dict()
                }

        except requests.exceptions.Timeout:
            state.add_log("error", "Časový limit pro odpověď modelu vypršel (Timeout).")
            state.status = AgentStatus.FAILED
            return state.to_dict()
        except requests.exceptions.ConnectionError:
            state.add_log("error", "Ollama server není dostupný na 127.0.0.1:11434.")
            state.status = AgentStatus.FAILED
            return state.to_dict()
        except Exception as e:
            state.add_log("error", f"Neočekávaná chyba agenta: {str(e)}")
            state.status = AgentStatus.FAILED
            return state.to_dict()

    def approve_diff(self, task_id: str, diff_id: str) -> dict:
        state = self.get_task(task_id)
        if not state:
            return {"error": "Úkol nenalezen"}

        for diff in state.pending_diffs:
            if diff["id"] == diff_id or diff_id == "all":
                diff["approved"] = True
                state.files_modified.append(diff["path"])
                state.add_log("success", f"Uživatel SCHVÁLIL úpravu pro: {diff['path']}")

        state.pending_diffs = [d for d in state.pending_diffs if not d.get("approved")]
        if not state.pending_diffs:
            state.status = AgentStatus.INVESTIGATING
            state.add_log("info", "Všechny úpravy schváleny. Pokračuji v ověřování...")

        return state.to_dict()

    def reject_diff(self, task_id: str, diff_id: str) -> dict:
        state = self.get_task(task_id)
        if not state:
            return {"error": "Úkol nenalezen"}

        for diff in state.pending_diffs:
            if diff["id"] == diff_id or diff_id == "all":
                diff["approved"] = False
                state.add_log("warning", f"Uživatel ZAMÍTL úpravu pro: {diff['path']}")

        state.pending_diffs = [d for d in state.pending_diffs if d.get("approved") is None]
        state.status = AgentStatus.INVESTIGATING
        state.messages.append({
            "role": "user",
            "content": f"Uživatel Zamítl navrženou úpravu skriptu. Navrhni jiné řešení nebo se zeptej na upřesnění."
        })
        return state.to_dict()
