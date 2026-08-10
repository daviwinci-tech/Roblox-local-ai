import os
import json

CONFIG_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "backend", "config.json")

DEFAULT_CONFIG = {
    "ollama_base_url": "http://127.0.0.1:11434",
    "default_model": "qwen2.5-coder:14b",
    "fallback_model": "qwen2.5-coder:7b",
    "host": "127.0.0.1",
    "port": 5000,
    "max_history_messages": 10,
    "max_agent_iterations": 20,
    "temperature": 0.2,
    "timeout": 90,
    "debug_logging": True,
    "allowed_origins": ["http://127.0.0.1:5000", "http://localhost:5000", "http://localhost:3000"]
}

def load_config():
    if not os.path.exists(CONFIG_PATH):
        try:
            with open(CONFIG_PATH, "w", encoding="utf-8") as f:
                json.dump(DEFAULT_CONFIG, f, indent=4)
        except Exception as e:
            print(f"[Config] Chyba při vytváření výchozího config.json: {e}")
        return DEFAULT_CONFIG.copy()

    try:
        with open(CONFIG_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
            # Doplňující klíče pokud chybí
            for k, v in DEFAULT_CONFIG.items():
                if k not in data:
                    data[k] = v
            return data
    except Exception as e:
        print(f"[Config] Chyba při načítání config.json: {e}")
        return DEFAULT_CONFIG.copy()

def save_config(new_config):
    try:
        with open(CONFIG_PATH, "w", encoding="utf-8") as f:
            json.dump(new_config, f, indent=4)
        return True
    except Exception as e:
        print(f"[Config] Uložení konfigurace selhalo: {e}")
        return False
