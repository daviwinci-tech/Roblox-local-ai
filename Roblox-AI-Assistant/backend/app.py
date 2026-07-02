import json
import os
import requests
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Povolení CORS pro případné externí webové nástroje

CONFIG_PATH = os.path.join(os.path.dirname(__file__), "config.json")

def load_config():
    default_config = {
        "ollama_base_url": "http://127.0.0.1:11434",
        "default_model": "qwen2.5-coder:14b",
        "host": "127.0.0.1",
        "port": 5000
    }
    if not os.path.exists(CONFIG_PATH):
        try:
            with open(CONFIG_PATH, "w", encoding="utf-8") as f:
                json.dump(default_config, f, indent=4, ensure_ascii=False)
            return default_config
        except Exception as e:
            print(f"Chyba při vytváření config.json: {e}")
            return default_config
            
    try:
        with open(CONFIG_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        print(f"Chyba při čtení config.json: {e}")
        return default_config

config = load_config()

def get_ollama_url(endpoint):
    base_url = config.get("ollama_base_url", "http://127.0.0.1:11434").rstrip("/")
    return f"{base_url}{endpoint}"

@app.route("/health", methods=["GET"])
def health():
    """
    Endpoint pro kontrolu stavu spojení s backendem a Ollamou.
    Ověří, zda Ollama běží, a vrátí seznam stažených modelů.
    """
    ollama_url = get_ollama_url("/api/tags")
    ollama_connected = False
    available_models = []
    
    try:
        response = requests.get(ollama_url, timeout=5)
        if response.status_code == 200:
            ollama_connected = True
            models_data = response.json()
            available_models = [m.get("name") for m in models_data.get("models", [])]
    except Exception as e:
        print(f"[Health] Nelze se připojit k Ollamě: {e}")
        
    return jsonify({
        "status": "ok",
        "backend_connected": True,
        "ollama_connected": ollama_connected,
        "available_models": available_models,
        "configured_default_model": config.get("default_model", "qwen2.5-coder:14b")
    })

@app.route("/chat", methods=["POST"])
def chat():
    """
    Endpoint pro konverzační chat s historií.
    Přijímá seznam zpráv (messages) a model.
    """
    try:
        data = request.get_json() or {}
        messages = data.get("messages", [])
        model = data.get("model", config.get("default_model", "qwen2.5-coder:14b"))
        
        if not messages:
            return jsonify({"error": "Nebyla poskytnuta žádná historie zpráv (messages)."}), 400
            
        ollama_url = get_ollama_url("/api/chat")
        
        payload = {
            "model": model,
            "messages": messages,
            "stream": False,
            "options": {
                "temperature": 0.5,
                "top_p": 0.9
            }
        }
        
        print(f"[Chat] Odesílám historii chat konverzace do Ollamy ({model})...")
        response = requests.post(ollama_url, json=payload, timeout=90)
        
        if response.status_code != 200:
            return jsonify({
                "error": f"Ollama vrátila chybu: {response.status_code}",
                "response": "Chyba Ollamy při zpracování chatu."
            }), 500
            
        result = response.json()
        ai_message = result.get("message", {}).get("content", "")
        
        return jsonify({
            "response": ai_message
        })
        
    except requests.exceptions.ConnectionError:
        return jsonify({
            "error": "Ollama offline",
            "response": "Chyba připojení k Ollamě. Ujistěte se, že Ollama běží lokálně na portu 11434."
        }), 503
    except Exception as e:
        return jsonify({
            "error": str(e),
            "response": f"Chyba serveru při zpracování chatu: {str(e)}"
        }), 500

@app.route("/generate", methods=["POST"])
def generate():
    """
    Endpoint pro generování Luau kódu na základě promptu.
    """
    try:
        data = request.get_json() or {}
        prompt = data.get("prompt", "")
        model = data.get("model", config.get("default_model", "qwen2.5-coder:14b"))
        
        if not prompt:
            return jsonify({"error": "Nebyl poskytnut žádný prompt."}), 400
            
        system_prompt = (
            "Jsi seniorní vývojář a softwarový architekt pro Roblox Studio. Tvým úkolem je generovat "
            "čistý, optimalizovaný a moderní kód v Luau (Roblox Lua 2025+). Nepoužívej deprecated funkce.\n"
            "Odpověď strukturuj tak, aby kód byl v přehledném markdown bloku ```lua ... ```."
        )
        
        ollama_url = get_ollama_url("/api/chat")
        
        # Použijeme chat API pro lepší dodržení systémového promptu
        payload = {
            "model": model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": prompt}
            ],
            "stream": False,
            "options": {
                "temperature": 0.2,
                "top_p": 0.95
            }
        }
        
        print(f"[Generate] Odesílám požadavek generování do Ollamy ({model})...")
        response = requests.post(ollama_url, json=payload, timeout=90)
        
        if response.status_code != 200:
            return jsonify({
                "error": f"Ollama vrátila chybu: {response.status_code}",
                "response": "Chyba Ollamy při generování kódu."
            }), 500
            
        result = response.json()
        ai_response = result.get("message", {}).get("content", "")
        
        return jsonify({
            "response": ai_response
        })
        
    except requests.exceptions.ConnectionError:
        return jsonify({
            "error": "Ollama offline",
            "response": "Chyba připojení k Ollamě. Ujistěte se, že Ollama běží lokálně."
        }), 503
    except Exception as e:
        return jsonify({
            "error": str(e),
            "response": f"Chyba serveru při generování kódu: {str(e)}"
        }), 500

@app.route("/fix", methods=["POST"])
def fix():
    """
    Endpoint pro opravování Luau skriptů.
    """
    try:
        data = request.get_json() or {}
        code = data.get("code", "")
        model = data.get("model", config.get("default_model", "qwen2.5-coder:14b"))
        
        if not code:
            return jsonify({"error": "Nebyl poskytnut žádný kód k opravě."}), 400
            
        system_prompt = (
            "Jsi expertní debugger a linter pro Roblox Luau (Roblox Studio 2025+). Analyzuj zadaný kód, "
            "najdi syntaktické a logické chyby, oprav je a kód optimalizuj.\n"
            "Vrať opravený kód v markdown bloku ```lua ... ``` a pod kód přidej stručný seznam provedených změn (v češtině)."
        )
        
        ollama_url = get_ollama_url("/api/chat")
        
        payload = {
            "model": model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"Oprav tento kód:\n\n{code}"}
            ],
            "stream": False,
            "options": {
                "temperature": 0.1,
                "top_p": 0.9
            }
        }
        
        print(f"[Fix] Odesílám kód k opravě do Ollamy ({model})...")
        response = requests.post(ollama_url, json=payload, timeout=90)
        
        if response.status_code != 200:
            return jsonify({
                "error": f"Ollama vrátila chybu: {response.status_code}",
                "response": "Chyba Ollamy při opravování kódu."
            }), 500
            
        result = response.json()
        ai_response = result.get("message", {}).get("content", "")
        
        return jsonify({
            "response": ai_response
        })
        
    except requests.exceptions.ConnectionError:
        return jsonify({
            "error": "Ollama offline",
            "response": "Chyba připojení k Ollamě."
        }), 503
    except Exception as e:
        return jsonify({
            "error": str(e),
            "response": f"Chyba serveru při opravování kódu: {str(e)}"
        }), 500

@app.route("/explain", methods=["POST"])
def explain():
    """
    Endpoint pro podrobný rozbor a vysvětlení Luau kódu.
    """
    try:
        data = request.get_json() or {}
        code = data.get("code", "")
        model = data.get("model", config.get("default_model", "qwen2.5-coder:14b"))
        
        if not code:
            return jsonify({"error": "Nebyl poskytnut žádný kód k vysvětlení."}), 400
            
        system_prompt = (
            "Jsi excelentní učitel a softwarový architekt pro Roblox Studio. Podrobně a srozumitelně "
            "vysvětli zadaný Luau kód krok za krokem v českém jazyce. Popiš herní služby, události, "
            "proměnné a optimalizaci kódu."
        )
        
        ollama_url = get_ollama_url("/api/chat")
        
        payload = {
            "model": model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"Vysvětli tento kód:\n\n{code}"}
            ],
            "stream": False,
            "options": {
                "temperature": 0.3,
                "top_p": 0.95
            }
        }
        
        print(f"[Explain] Odesílám kód k vysvětlení do Ollamy ({model})...")
        response = requests.post(ollama_url, json=payload, timeout=90)
        
        if response.status_code != 200:
            return jsonify({
                "error": f"Ollama vrátila chybu: {response.status_code}",
                "response": "Chyba Ollamy při analýze kódu."
            }), 500
            
        result = response.json()
        ai_response = result.get("message", {}).get("content", "")
        
        return jsonify({
            "response": ai_response
        })
        
    except requests.exceptions.ConnectionError:
        return jsonify({
            "error": "Ollama offline",
            "response": "Chyba připojení k Ollamě."
        }), 503
    except Exception as e:
        return jsonify({
            "error": str(e),
            "response": f"Chyba serveru při analýze kódu: {str(e)}"
        }), 500

if __name__ == "__main__":
    host = config.get("host", "127.0.0.1")
    port = config.get("port", 5000)
    print(f"==========================================")
    print(f"🚀 ROBLOX AI ASSISTANT BACKEND (FLASK)")
    print(f"Běží na adrese: http://{host}:{port}")
    print(f"Ollama base URL: {config.get('ollama_base_url')}")
    print(f"Výchozí model: {config.get('default_model')}")
    print(f"==========================================")
    app.run(host=host, port=port, debug=False)
