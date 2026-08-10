import os
import json
import requests
from flask import Flask, request, jsonify
from flask_cors import CORS

from config import load_config
from agent.agent import AgentEngine, ACTIVE_TASKS

app = Flask(__name__)

# Načtení konfigurace
config = load_config()

# Zabezpečený CORS - povoluje pouze lokální požadavky z Roblox Studia a lokálního dev serveru
allowed_origins = config.get("allowed_origins", ["http://127.0.0.1:5000", "http://localhost:5000", "http://localhost:3000"])
CORS(app, resources={r"/*": {"origins": "*"}}) # Pro Roblox Studio HTTP API je potřeba akceptovat lokální spojení

# Globální HTTP Session pro Re-use TCP spojení s Ollamou
http_session = requests.Session()

# Inicializace Agent Engine
agent_engine = AgentEngine(http_session)

def get_ollama_url(endpoint):
    base_url = config.get("ollama_base_url", "http://127.0.0.1:11434").strip().rstrip("/")
    if not base_url.startswith("http://") and not base_url.startswith("https://"):
        base_url = f"http://{base_url}"
    return f"{base_url}{endpoint}"

def truncate_messages(messages, max_count=10):
    if not messages:
        return []
    system_msgs = [m for m in messages if m.get("role") == "system"]
    other_msgs = [m for m in messages if m.get("role") != "system"]
    if len(other_msgs) > max_count:
        other_msgs = other_msgs[-max_count:]
    return system_msgs + other_msgs

# ==========================================
# STÁVAJÍCÍ COMPATIBILITY ENDPOINTY
# ==========================================

@app.route("/health", methods=["GET"])
def health():
    ollama_url = get_ollama_url("/api/tags")
    ollama_connected = False
    current_model = config.get("default_model", "qwen2.5-coder:14b")
    available_models = []
    
    try:
        response = http_session.get(ollama_url, timeout=5)
        if response.status_code == 200:
            ollama_connected = True
            models_data = response.json()
            available_models = [m["name"] for m in models_data.get("models", [])]
    except Exception as e:
        print(f"[Health] Nelze se spojit s Ollamou: {e}")

    return jsonify({
        "status": "ok",
        "backend_connected": True,
        "ollama_connected": ollama_connected,
        "model": current_model,
        "available_models": available_models,
        "message": "Roblox AI Agent Backend běží lokálně."
    })

@app.route("/chat", methods=["POST"])
def chat():
    data = request.json or {}
    messages = data.get("messages", [])
    model = data.get("model") or config.get("default_model", "qwen2.5-coder:14b")
    
    if not messages:
        return jsonify({"error": "Nebyla poskytnuta žádná historie zpráv."}), 400

    max_msgs = config.get("max_history_messages", 10)
    messages = truncate_messages(messages, max_count=max_msgs)
    ollama_url = get_ollama_url("/api/chat")
    
    payload = {
        "model": model,
        "messages": messages,
        "stream": False,
        "options": {"temperature": config.get("temperature", 0.2)}
    }
    
    try:
        response = http_session.post(ollama_url, json=payload, timeout=90)
        if response.status_code != 200:
            return jsonify({"error": f"Ollama vrátila status {response.status_code}"}), 500
        res_json = response.json()
        return jsonify({
            "status": "ok",
            "response": res_json.get("message", {}).get("content", "")
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/generate", methods=["POST"])
def generate():
    data = request.json or {}
    prompt = data.get("prompt", "")
    context = data.get("context", "")
    model = data.get("model") or config.get("default_model", "qwen2.5-coder:14b")
    
    sys_prompt = "Jsi expert na Roblox Luau skriptování. Generuj pouze platný kód Luau bez omáčky okolo."
    user_msg = f"Kontext skriptu:\n{context}\n\nPožadavek:\n{prompt}"
    
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": sys_prompt},
            {"role": "user", "content": user_msg}
        ],
        "stream": False
    }
    
    try:
        response = http_session.post(get_ollama_url("/api/chat"), json=payload, timeout=90)
        res_json = response.json()
        return jsonify({
            "status": "ok",
            "response": res_json.get("message", {}).get("content", "")
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/fix", methods=["POST"])
def fix():
    data = request.json or {}
    code = data.get("code", "")
    error_message = data.get("error_message", "")
    model = data.get("model") or config.get("default_model", "qwen2.5-coder:14b")
    
    sys_prompt = "Jsi expert na opravování chyb v Roblox Luau kódů. Oprav zadaný skript a stručně vysvětli příčinu."
    user_msg = f"Chybová zpráva: {error_message}\n\nKód ke korekci:\n```luau\n{code}\n```"
    
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": sys_prompt},
            {"role": "user", "content": user_msg}
        ],
        "stream": False
    }
    
    try:
        response = http_session.post(get_ollama_url("/api/chat"), json=payload, timeout=90)
        res_json = response.json()
        return jsonify({
            "status": "ok",
            "response": res_json.get("message", {}).get("content", "")
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/explain", methods=["POST"])
def explain():
    data = request.json or {}
    code = data.get("code", "")
    model = data.get("model") or config.get("default_model", "qwen2.5-coder:14b")
    
    sys_prompt = "Jsi učitel Roblox vývoje. Vysvětli krok za krokem zadaný Luau kód česky a srozumitelně."
    
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": sys_prompt},
            {"role": "user", "content": f"Kód k vysvětlení:\n```luau\n{code}\n```"}
        ],
        "stream": False
    }
    
    try:
        response = http_session.post(get_ollama_url("/api/chat"), json=payload, timeout=90)
        res_json = response.json()
        return jsonify({
            "status": "ok",
            "response": res_json.get("message", {}).get("content", "")
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ==========================================
# NOVÉ AGENTNÍ API ENDPOINTY
# ==========================================

@app.route("/agent/start", methods=["POST"])
def agent_start():
    data = request.json or {}
    goal = data.get("goal", "").strip()
    if not goal:
        return jsonify({"error": "Nebylo zadáno cílové zadání (goal)."}), 400

    state = agent_engine.start_task(goal)
    return jsonify({
        "status": "ok",
        "task_id": state.task_id,
        "state": state.to_dict()
    })

@app.route("/agent/step", methods=["POST"])
def agent_step():
    data = request.json or {}
    task_id = data.get("task_id")
    tool_result = data.get("tool_result")
    
    if not task_id:
        return jsonify({"error": "Chybí ID úkolu (task_id)."}), 400

    res = agent_engine.execute_next_step(task_id, tool_result_override=tool_result)
    return jsonify(res)

@app.route("/agent/approve", methods=["POST"])
def agent_approve():
    data = request.json or {}
    task_id = data.get("task_id")
    diff_id = data.get("diff_id", "all")
    
    if not task_id:
        return jsonify({"error": "Chybí ID úkolu (task_id)."}), 400

    res = agent_engine.approve_diff(task_id, diff_id)
    return jsonify(res)

@app.route("/agent/reject", methods=["POST"])
def agent_reject():
    data = request.json or {}
    task_id = data.get("task_id")
    diff_id = data.get("diff_id", "all")
    
    if not task_id:
        return jsonify({"error": "Chybí ID úkolu (task_id)."}), 400

    res = agent_engine.reject_diff(task_id, diff_id)
    return jsonify(res)

@app.route("/agent/status/<task_id>", methods=["GET"])
def agent_status(task_id):
    state = agent_engine.get_task(task_id)
    if not state:
        return jsonify({"error": f"Úkol {task_id} nebyl nalezen."}), 404
    return jsonify({"status": "ok", "state": state.to_dict()})

if __name__ == "__main__":
    host = config.get("host", "127.0.0.1")
    port = config.get("port", 5000)
    print(f"==========================================")
    print(f"🤖 Roblox AI Local Agent Backend Spuštěn!")
    print(f"Adresa backendu: http://{host}:{port}")
    print(f"Ollama base URL: {config.get('ollama_base_url')}")
    print(f"Výchozí model: {config.get('default_model')}")
    print(f"==========================================")
    app.run(host=host, port=port, debug=False, threaded=True)
