import express from "express";
import path from "path";
import fs from "fs";
import { createServer as createViteServer } from "vite";
import { GoogleGenAI } from "@google/genai";
import dotenv from "dotenv";

dotenv.config();

const app = express();
const PORT = 3000;

// Inicializace Gemini API s telemetrií 'aistudio-build'
const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
  httpOptions: {
    headers: {
      'User-Agent': 'aistudio-build',
    }
  }
});

app.use(express.json());

// API pro simulaci generování kódu Roblox AI Assistant
app.post("/api/generate", async (req, res) => {
  try {
    const { prompt, model } = req.body;
    
    if (!prompt) {
      return res.status(400).json({ error: "Chybí prompt" });
    }

    const selectedModel = "gemini-3.5-flash";
    const systemInstruction = 
      "Jsi zkušený seniorní vývojář se specializací na Roblox Studio, Luau herní vývoj a skriptování. " +
      "Uživatel ti zadal dotaz nebo tě požádal o vytvoření skriptu. " +
      "Odpověz v češtině, srozumitelně a profesionálně. " +
      "Pokud po tobě chce kód, napiš ho v čistém Roblox Luau, s řádným typováním a v komentářích popiš, " +
      "jak kód funguje. Kód zabal do markdown bloku ```lua ... ```.";

    console.log(`[Server] Volám Gemini (${selectedModel}) pro prompt: "${prompt}"`);
    
    const response = await ai.models.generateContent({
      model: selectedModel,
      contents: prompt,
      config: {
        systemInstruction,
        temperature: 0.3
      }
    });

    const text = response.text || "Omlouvám se, nepodařilo se mi vygenerovat žádnou odpověď.";
    res.json({ response: text });
  } catch (error: any) {
    console.error("[Server] Chyba Gemini API:", error);
    res.status(500).json({ 
      error: "Nepodařilo se kontaktovat umělou inteligenci. Zkontrolujte prosím konfiguraci klíče.",
      details: error.message 
    });
  }
});

// API pro simulaci opravy kódu (Fix)
app.post("/api/fix", async (req, res) => {
  try {
    const { code } = req.body;
    
    if (!code) {
      return res.status(400).json({ error: "Chybí zdrojový kód" });
    }

    const selectedModel = "gemini-3.5-flash";
    const systemInstruction = 
      "Jsi expertní linter a debugger pro Roblox Luau. " +
      "Tvým úkolem je opravit předložený Roblox Lua kód. " +
      "Odstraň chyby, zkontroluj logické neshody a optimalizuj výkon. " +
      "Odpověz v češtině. Nejprve uveď opravený kód v bloku ```lua ... ```. " +
      "Poté stručně v bodech vysvětli, co bylo opraveno a proč.";

    console.log(`[Server] Volám Gemini pro opravu kódu.`);
    
    const response = await ai.models.generateContent({
      model: selectedModel,
      contents: `Oprav tento Roblox Lua kód:\n\n${code}`,
      config: {
        systemInstruction,
        temperature: 0.2
      }
    });

    const text = response.text || "Omlouvám se, nepodařilo se mi vygenerovat žádnou odpověď.";
    res.json({ response: text });
  } catch (error: any) {
    console.error("[Server] Chyba Gemini API:", error);
    res.status(500).json({ error: error.message });
  }
});

// API pro simulaci vysvětlení kódu (Explain)
app.post("/api/explain", async (req, res) => {
  try {
    const { code } = req.body;
    
    if (!code) {
      return res.status(400).json({ error: "Chybí zdrojový kód" });
    }

    const selectedModel = "gemini-3.5-flash";
    const systemInstruction = 
      "Jsi trpělivý seniorní učitel programování v Robloxu. " +
      "Tvým úkolem je podrobně, krok za krokem vysvětlit, jak funguje předložený Roblox Lua kód. " +
      "Popiš herní služby (Services), události (Events), logická větvení a herní cykly. " +
      "Odpověz strukturovaně v češtině, s elegantním formátováním.";

    console.log(`[Server] Volám Gemini pro vysvětlení kódu.`);
    
    const response = await ai.models.generateContent({
      model: selectedModel,
      contents: `Vysvětli tento Roblox Lua kód:\n\n${code}`,
      config: {
        systemInstruction,
        temperature: 0.4
      }
    });

    const text = response.text || "Omlouvám se, nepodařilo se mi vygenerovat žádnou odpověď.";
    res.json({ response: text });
  } catch (error: any) {
    console.error("[Server] Chyba Gemini API:", error);
    res.status(500).json({ error: error.message });
  }
});

// Zpřístupnění zdrojových souborů Roblox-AI-Assistant pro dokumentaci a kopírování
app.get("/api/project-files", async (req, res) => {
  try {
    const basePath = path.join(process.cwd(), "Roblox-AI-Assistant");
    const filesToRead = [
      { name: "Main.server.lua", path: "src/Main.server.lua" },
      { name: "UI.lua", path: "src/UI.lua" },
      { name: "Api.lua", path: "src/Api.lua" },
      { name: "Explain.lua", path: "src/Explain.lua" },
      { name: "Fix.lua", path: "src/Fix.lua" },
      { name: "Insert.lua", path: "src/Insert.lua" },
      { name: "Settings.lua", path: "src/Settings.lua" },
      { name: "Theme.lua", path: "src/Theme.lua" },
      { name: "Widgets.lua", path: "src/Widgets.lua" },
      { name: "app.py", path: "backend/app.py" },
      { name: "requirements.txt", path: "requirements.txt" },
      { name: "default.project.json", path: "default.project.json" }
    ];
    
    const results = filesToRead.map(f => {
      const fullPath = path.join(basePath, f.path);
      let content = "";
      if (fs.existsSync(fullPath)) {
        content = fs.readFileSync(fullPath, "utf-8");
      }
      return {
        name: f.name,
        path: f.path,
        content: content
      };
    });
    
    res.json(results);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Nastavení Vite middleware pro vývoj, nebo statických souborů pro produkci
async function startServer() {
  if (process.env.NODE_ENV !== "production") {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), "dist");
    app.use(express.static(distPath));
    app.get("*", (req, res) => {
      res.sendFile(path.join(distPath, "index.html"));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`[Server] Roblox AI Companion běží na http://localhost:${PORT}`);
  });
}

startServer();
