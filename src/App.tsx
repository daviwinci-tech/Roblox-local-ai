import React, { useState, useEffect } from "react";
import {
  Terminal,
  Settings,
  Check,
  Copy,
  ArrowRight,
  BookOpen,
  Cpu,
  Layers,
  AlertTriangle,
  RefreshCw,
  Download,
  Code,
  Sparkles,
  CheckCircle,
  HelpCircle,
  ExternalLink,
  Lock,
  Play
} from "lucide-react";

interface ProjectFile {
  name: string;
  path: string;
  content: string;
}

interface LocalHealthStatus {
  success: boolean;
  backend_connected: boolean;
  ollama_connected: boolean;
  model?: string;
  available_models?: string[];
  message?: string;
}

export default function App() {
  const [projectFiles, setProjectFiles] = useState<ProjectFile[]>([]);
  const [selectedFile, setSelectedFile] = useState<ProjectFile | null>(null);
  const [loadingFiles, setLoadingFiles] = useState(true);
  const [copied, setCopied] = useState<string | null>(null);
  
  // Stavy diagnostiky lokálního připojení
  const [diagnosing, setDiagnosing] = useState(false);
  const [localStatus, setLocalStatus] = useState<LocalHealthStatus | null>(null);
  const [diagnosticRun, setDiagnosticRun] = useState(false);

  // Načtení souborů z backendu pro prohlížeč kódu
  useEffect(() => {
    fetch("/api/project-files")
      .then((res) => {
        if (!res.ok) throw new Error("Chyba při načítání souborů");
        return res.json();
      })
      .then((data: ProjectFile[]) => {
        setProjectFiles(data);
        if (data.length > 0) {
          setSelectedFile(data[0]);
        }
        setLoadingFiles(false);
      })
      .catch((err) => {
        console.error(err);
        setLoadingFiles(false);
      });
  }, []);

  // Funkce pro spuštění diagnostiky lokálního připojení na portu 5000
  const runLocalDiagnostic = async () => {
    setDiagnosing(true);
    setDiagnosticRun(true);
    setLocalStatus(null);

    try {
      // Zkusíme se z prohlížeče dotázat přímo na lokální Flask běžící u uživatele na 127.0.0.1:5000
      const response = await fetch("http://127.0.0.1:5000/health", {
        method: "GET",
        mode: "cors",
        headers: { "Accept": "application/json" }
      });

      if (response.ok) {
        const data = await response.json();
        setLocalStatus({
          success: true,
          backend_connected: true,
          ollama_connected: data.ollama_connected ?? false,
          model: data.model ?? "Neznámý",
          available_models: data.available_models ?? [],
          message: data.message ?? "Lokální Flask server je plně dostupný!"
        });
      } else {
        setLocalStatus({
          success: false,
          backend_connected: true,
          ollama_connected: false,
          message: "Flask server sice odpověděl, ale vrátil chybový stav (CORS nebo interní chyba)."
        });
      }
    } catch (err: any) {
      console.warn("Chyba diagnostiky lokálního připojení:", err);
      setLocalStatus({
        success: false,
        backend_connected: false,
        ollama_connected: false,
        message: "Nelze se spojit s lokálním serverem http://127.0.0.1:5000. Ujistěte se, že běží."
      });
    } finally {
      setDiagnosing(false);
    }
  };

  const handleCopy = (text: string, label: string) => {
    navigator.clipboard.writeText(text);
    setCopied(label);
    setTimeout(() => setCopied(null), 2000);
  };

  const handleDownloadFile = (file: ProjectFile) => {
    const blob = new Blob([file.content], { type: "text/plain;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = file.name;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  };

  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100 font-sans antialiased selection:bg-teal-500/30 selection:text-teal-200">
      
      {/* Horní dekorační linka */}
      <div className="h-1 bg-gradient-to-r from-teal-500 via-emerald-500 to-cyan-500 w-full" />

      {/* Navigační panel */}
      <header className="border-b border-zinc-900 bg-zinc-950/70 backdrop-blur-md sticky top-0 z-30">
        <div className="max-w-6xl mx-auto px-4 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-gradient-to-br from-teal-500/20 to-emerald-500/20 rounded-xl border border-teal-500/30 text-teal-400">
              <Cpu className="w-6 h-6 animate-pulse" />
            </div>
            <div>
              <h1 className="font-semibold text-lg tracking-tight text-white flex items-center gap-2">
                Roblox AI Assistant
                <span className="text-xs font-normal text-teal-400 px-2 py-0.5 bg-teal-950/60 border border-teal-500/30 rounded-full">
                  Offline & Lokální
                </span>
              </h1>
              <p className="text-xs text-zinc-400">Průvodce instalací a správa pluginu</p>
            </div>
          </div>
          
          <div className="flex items-center gap-4">
            <div className="hidden sm:flex items-center gap-2 px-3 py-1 bg-zinc-900 border border-zinc-800 rounded-lg text-xs">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-ping" />
              <span className="text-zinc-400">Companion Server:</span>
              <span className="font-mono text-zinc-200 font-semibold">ONLINE</span>
            </div>
          </div>
        </div>
      </header>

      {/* Hlavní obsah */}
      <main className="max-w-6xl mx-auto px-4 py-8 space-y-8">
        
        {/* Úvodní sekce */}
        <section className="relative overflow-hidden rounded-2xl border border-zinc-900 bg-zinc-900/20 p-8 sm:p-10">
          <div className="absolute top-0 right-0 -mt-8 -mr-8 w-48 h-48 bg-teal-500/10 rounded-full blur-3xl pointer-events-none" />
          <div className="absolute bottom-0 left-0 -mb-8 -ml-8 w-48 h-48 bg-emerald-500/10 rounded-full blur-3xl pointer-events-none" />
          
          <div className="relative z-10 max-w-3xl space-y-4">
            <div className="inline-flex items-center gap-2 px-3 py-1 bg-zinc-900 border border-zinc-800 rounded-full text-xs text-teal-400 font-mono font-medium">
              <Lock className="w-3.5 h-3.5" /> 100% Soukromí & Bezpečnost
            </div>
            <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight text-white leading-tight">
              Tvůj kód nikdy neopustí tvůj počítač.
            </h2>
            <p className="text-zinc-400 text-base sm:text-lg leading-relaxed">
              Tento moderní AI programovací asistent je integrován přímo do <strong>Roblox Studio</strong> (2025+). 
              Komunikuje výhradně s lokálním LLM modelem skrze nástroj <strong>Ollama</strong> a lehký 
              <strong> Python Flask backend</strong>, který slouží jako zabezpečený bridge.
            </p>
          </div>
        </section>

        {/* Dvou sloupcový layout: Návod vs Diagnostika */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
          
          {/* LEVÝ SLOUPEC: Návod k instalaci (7/12) */}
          <div className="lg:col-span-7 space-y-6">
            <h3 className="text-xl font-bold text-white flex items-center gap-2">
              <BookOpen className="w-5 h-5 text-teal-400" />
              Návod na zprovoznění v Roblox Studiu
            </h3>
            
            <div className="space-y-4">
              
              {/* Krok 1 */}
              <div className="bg-zinc-900/30 border border-zinc-900 rounded-xl p-5 relative overflow-hidden group">
                <div className="absolute top-4 right-4 text-xs font-mono font-bold text-zinc-700 group-hover:text-teal-500/30 transition-colors">KROK 1</div>
                <h4 className="font-semibold text-white flex items-center gap-2.5">
                  <span className="w-6 h-6 rounded-full bg-teal-950 text-teal-400 flex items-center justify-center text-xs border border-teal-500/20 font-bold">1</span>
                  Příprava Ollamy a stažení modelu
                </h4>
                <div className="mt-3 pl-8 text-sm text-zinc-400 space-y-3">
                  <p>
                    Stáhněte a nainstalujte si <a href="https://ollama.com/" target="_blank" rel="noreferrer" className="text-teal-400 hover:underline inline-flex items-center gap-1">Ollamu <ExternalLink className="w-3 h-3" /></a> pro váš operační systém.
                  </p>
                  <p>Spusťte terminál a stáhněte doporučený kódový model:</p>
                  <div className="bg-zinc-950 border border-zinc-800 rounded-lg p-3 font-mono text-xs text-zinc-300 flex items-center justify-between gap-4">
                    <span>ollama run qwen2.5-coder:14b</span>
                    <button
                      onClick={() => handleCopy("ollama run qwen2.5-coder:14b", "step1")}
                      className="p-1 hover:bg-zinc-900 rounded text-zinc-400 hover:text-white transition-colors"
                      title="Kopírovat příkaz"
                    >
                      {copied === "step1" ? <Check className="w-4 h-4 text-emerald-500" /> : <Copy className="w-4 h-4" />}
                    </button>
                  </div>
                  <p className="text-xs text-zinc-500">
                    * Pro méně výkonné počítače s menší VRAM/RAM můžete použít odlehčený model <code className="text-zinc-400">qwen2.5-coder:7b</code> nebo <code className="text-zinc-400">1.5b</code>.
                  </p>
                </div>
              </div>

              {/* Krok 2 */}
              <div className="bg-zinc-900/30 border border-zinc-900 rounded-xl p-5 relative overflow-hidden group">
                <div className="absolute top-4 right-4 text-xs font-mono font-bold text-zinc-700 group-hover:text-teal-500/30 transition-colors">KROK 2</div>
                <h4 className="font-semibold text-white flex items-center gap-2.5">
                  <span className="w-6 h-6 rounded-full bg-teal-950 text-teal-400 flex items-center justify-center text-xs border border-teal-500/20 font-bold">2</span>
                  Spuštění Python Backend serveru
                </h4>
                <div className="mt-3 pl-8 text-sm text-zinc-400 space-y-3">
                  <p>
                    Tento lehký Python skript běží na pozadí a zprostředkovává bezpečnou komunikaci na portu <code className="text-teal-400 font-mono">5000</code>.
                  </p>
                  <p>Nainstalujte závislosti a spusťte server v kořeni projektu:</p>
                  <div className="bg-zinc-950 border border-zinc-800 rounded-lg p-3 font-mono text-xs text-zinc-300 space-y-2">
                    <div className="flex items-center justify-between gap-4 border-b border-zinc-900 pb-2">
                      <span>pip install -r requirements.txt</span>
                      <button
                        onClick={() => handleCopy("pip install -r requirements.txt", "step2_pip")}
                        className="p-1 hover:bg-zinc-900 rounded text-zinc-400 hover:text-white transition-colors"
                      >
                        {copied === "step2_pip" ? <Check className="w-4 h-4 text-emerald-500" /> : <Copy className="w-4 h-4" />}
                      </button>
                    </div>
                    <div className="flex items-center justify-between gap-4 pt-1">
                      <span>python backend/app.py</span>
                      <button
                        onClick={() => handleCopy("python backend/app.py", "step2_run")}
                        className="p-1 hover:bg-zinc-900 rounded text-zinc-400 hover:text-white transition-colors"
                      >
                        {copied === "step2_run" ? <Check className="w-4 h-4 text-emerald-500" /> : <Copy className="w-4 h-4" />}
                      </button>
                    </div>
                  </div>
                </div>
              </div>

              {/* Krok 3 */}
              <div className="bg-zinc-900/30 border border-zinc-900 rounded-xl p-5 relative overflow-hidden group">
                <div className="absolute top-4 right-4 text-xs font-mono font-bold text-zinc-700 group-hover:text-teal-500/30 transition-colors">KROK 3</div>
                <h4 className="font-semibold text-white flex items-center gap-2.5">
                  <span className="w-6 h-6 rounded-full bg-teal-950 text-teal-400 flex items-center justify-center text-xs border border-teal-500/20 font-bold">3</span>
                  Synchronizace do Roblox Studio přes Rojo
                </h4>
                <div className="mt-3 pl-8 text-sm text-zinc-400 space-y-3">
                  <p>
                    Využijte nástroj <strong>Rojo</strong> pro rychlé sestavení a nahrání pluginu do otevřeného Roblox projektu:
                  </p>
                  <div className="bg-zinc-950 border border-zinc-800 rounded-lg p-3 font-mono text-xs text-zinc-300 space-y-2">
                    <div className="flex items-center justify-between gap-4 border-b border-zinc-900 pb-2">
                      <span>rojo plugin install</span>
                      <button
                        onClick={() => handleCopy("rojo plugin install", "step3_install")}
                        className="p-1 hover:bg-zinc-900 rounded text-zinc-400 hover:text-white transition-colors"
                      >
                        {copied === "step3_install" ? <Check className="w-4 h-4 text-emerald-500" /> : <Copy className="w-4 h-4" />}
                      </button>
                    </div>
                    <div className="flex items-center justify-between gap-4 pt-1">
                      <span>rojo serve</span>
                      <button
                        onClick={() => handleCopy("rojo serve", "step3_serve")}
                        className="p-1 hover:bg-zinc-900 rounded text-zinc-400 hover:text-white transition-colors"
                      >
                        {copied === "step3_serve" ? <Check className="w-4 h-4 text-emerald-500" /> : <Copy className="w-4 h-4" />}
                      </button>
                    </div>
                  </div>
                  <p>
                    V Roblox Studio klikněte na Rojo plugin, dejte <strong>Connect</strong> a plugin se ihned načte. 
                    Můžete ho pak uložit jako trvalý lokální plugin (kliknout pravým v Exploreru na plugin složku a dát <em>Save as Local Plugin...</em>).
                  </p>
                </div>
              </div>

            </div>
          </div>

          {/* PRAVÝ SLOUPEC: Diagnostika připojení (5/12) */}
          <div className="lg:col-span-5 space-y-6">
            <h3 className="text-xl font-bold text-white flex items-center gap-2">
              <Settings className="w-5 h-5 text-emerald-400" />
              Lokální diagnostika
            </h3>

            <div className="bg-zinc-900/40 border border-zinc-900 rounded-2xl p-6 space-y-6">
              <p className="text-sm text-zinc-400 leading-relaxed">
                Protože celý plugin komunikuje lokálně, můžete si přímo z tohoto prohlížeče vyzkoušet, zda váš běžící Python server na adrese <code className="text-zinc-300">127.0.0.1:5000</code> správně reaguje.
              </p>

              <button
                onClick={runLocalDiagnostic}
                disabled={diagnosing}
                className="w-full py-3 px-4 bg-gradient-to-r from-teal-500 to-emerald-500 hover:from-teal-600 hover:to-emerald-600 active:scale-[0.98] disabled:opacity-50 text-black font-semibold rounded-xl flex items-center justify-center gap-2 transition-all cursor-pointer shadow-lg shadow-teal-500/10"
              >
                {diagnosing ? (
                  <>
                    <RefreshCw className="w-4 h-4 animate-spin" />
                    Vyšetřování spojení...
                  </>
                ) : (
                  <>
                    <Play className="w-4 h-4 fill-current" />
                    Testovat lokální spojení
                  </>
                )}
              </button>

              {/* Výsledek diagnostiky */}
              {diagnosticRun && (
                <div className={`rounded-xl border p-4 space-y-3 animate-fadeIn ${
                  localStatus?.success 
                    ? "bg-emerald-950/20 border-emerald-500/30" 
                    : "bg-red-950/20 border-red-500/30"
                }`}>
                  <div className="flex items-center gap-2">
                    {localStatus?.success ? (
                      <CheckCircle className="w-5 h-5 text-emerald-400 shrink-0" />
                    ) : (
                      <AlertTriangle className="w-5 h-5 text-red-400 shrink-0" />
                    )}
                    <h5 className="font-semibold text-white text-sm">
                      {localStatus?.success ? "Flask backend je online!" : "Nelze se připojit"}
                    </h5>
                  </div>
                  
                  <p className="text-xs text-zinc-400 leading-relaxed">
                    {localStatus?.message}
                  </p>

                  {localStatus?.success && (
                    <div className="border-t border-zinc-900 pt-3 space-y-1.5 text-xs">
                      <div className="flex justify-between">
                        <span className="text-zinc-500">Stav spojení s Ollama:</span>
                        <span className={localStatus.ollama_connected ? "text-emerald-400 font-semibold" : "text-amber-400 font-semibold"}>
                          {localStatus.ollama_connected ? "PŘIPOJENO" : "ODPOJENO (Zkontrolujte Ollamu)"}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-zinc-500">Aktuální model:</span>
                        <span className="text-zinc-200 font-mono font-medium">{localStatus.model}</span>
                      </div>
                      {localStatus.available_models && localStatus.available_models.length > 0 && (
                        <div className="pt-1">
                          <span className="text-zinc-500 block mb-1">Dostupné lokální modely:</span>
                          <div className="flex flex-wrap gap-1">
                            {localStatus.available_models.map((m, idx) => (
                              <span key={idx} className="bg-zinc-900 border border-zinc-800 text-zinc-300 px-1.5 py-0.5 rounded text-[10px] font-mono">
                                {m}
                              </span>
                            ))}
                          </div>
                        </div>
                      )}
                    </div>
                  )}
                </div>
              )}

              {/* Informační blok */}
              <div className="flex gap-3 bg-zinc-950/50 p-4 rounded-xl border border-zinc-900">
                <AlertTriangle className="w-5 h-5 text-teal-400 shrink-0 mt-0.5" />
                <div className="space-y-1 text-xs">
                  <h6 className="font-semibold text-zinc-200">Bezpečnost a oprávnění HTTP</h6>
                  <p className="text-zinc-500 leading-relaxed">
                    Roblox Studio vyžaduje povolení HTTP požadavků. Povolte je v nastavení hry:
                    <br />
                    <strong className="text-zinc-400">Game Settings &gt; Security &gt; Allow HTTP Requests</strong>.
                  </p>
                </div>
              </div>

            </div>
          </div>

        </div>

        {/* KNIHOVNA SOUBORŮ (ZDROJOVÉ KÓDY) */}
        <section className="space-y-4 pt-4">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <h3 className="text-xl font-bold text-white flex items-center gap-2">
                <Code className="w-5 h-5 text-cyan-400" />
                Zdrojové soubory k nahlédnutí a instalaci
              </h3>
              <p className="text-xs text-zinc-400">Zde naleznete nejdůležitější části celého kódu pro případný manuální import.</p>
            </div>
          </div>

          <div className="border border-zinc-900 rounded-2xl overflow-hidden bg-zinc-900/10 grid grid-cols-1 md:grid-cols-4">
            
            {/* Boční výběr souborů */}
            <div className="border-r border-zinc-900 p-4 space-y-1 md:col-span-1 bg-zinc-950/40">
              <span className="text-[10px] font-bold text-zinc-500 uppercase tracking-wider block px-2 mb-2">SOUBORY PLUGINU</span>
              {loadingFiles ? (
                <div className="text-sm text-zinc-500 p-2">Načítání seznamu...</div>
              ) : (
                projectFiles.map((file) => (
                  <button
                    key={file.name}
                    onClick={() => setSelectedFile(file)}
                    className={`w-full text-left px-3 py-2 rounded-lg text-xs font-mono transition-all flex items-center gap-2 border cursor-pointer ${
                      selectedFile?.name === file.name
                        ? "bg-teal-500/10 border-teal-500/30 text-teal-400"
                        : "bg-transparent border-transparent text-zinc-400 hover:bg-zinc-900 hover:text-zinc-200"
                    }`}
                  >
                    <span className={file.name.endsWith(".py") ? "text-amber-500" : file.name.endsWith(".json") ? "text-purple-400" : "text-blue-400"}>
                      📄
                    </span>
                    <div className="truncate">
                      <span className="block font-medium">{file.name}</span>
                      <span className="block text-[9px] text-zinc-600 truncate">{file.path}</span>
                    </div>
                  </button>
                ))
              )}
            </div>

            {/* Náhled kódu */}
            <div className="md:col-span-3 p-6 flex flex-col h-[520px] bg-zinc-950/20 relative">
              {selectedFile ? (
                <>
                  <div className="flex items-center justify-between pb-4 border-b border-zinc-900 mb-4 shrink-0">
                    <div>
                      <h4 className="font-semibold text-white text-sm font-mono flex items-center gap-2">
                        {selectedFile.name}
                        <span className="text-[10px] text-zinc-500 font-normal">({selectedFile.path})</span>
                      </h4>
                    </div>
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => handleCopy(selectedFile.content, "viewer")}
                        className="p-1.5 px-3 bg-zinc-900 border border-zinc-800 hover:bg-zinc-800 rounded-lg text-xs text-zinc-300 hover:text-white flex items-center gap-1.5 transition-all cursor-pointer"
                        title="Kopírovat celý soubor"
                      >
                        {copied === "viewer" ? (
                          <>
                            <Check className="w-3.5 h-3.5 text-emerald-400" />
                            <span>Kopírováno</span>
                          </>
                        ) : (
                          <>
                            <Copy className="w-3.5 h-3.5" />
                            <span>Kopírovat</span>
                          </>
                        )}
                      </button>
                      
                      <button
                        onClick={() => handleDownloadFile(selectedFile)}
                        className="p-1.5 px-3 bg-zinc-900 border border-zinc-800 hover:bg-zinc-800 rounded-lg text-xs text-zinc-300 hover:text-white flex items-center gap-1.5 transition-all cursor-pointer"
                        title="Stáhnout jako soubor"
                      >
                        <Download className="w-3.5 h-3.5" />
                        <span>Stáhnout</span>
                      </button>
                    </div>
                  </div>

                  <div className="flex-1 overflow-auto rounded-xl border border-zinc-900 bg-zinc-950 p-4 font-mono text-xs leading-relaxed text-zinc-300 select-text">
                    <pre className="whitespace-pre">{selectedFile.content || "-- Soubor je prázdný"}</pre>
                  </div>
                </>
              ) : (
                <div className="flex-1 flex flex-col items-center justify-center text-zinc-500 gap-2">
                  <Terminal className="w-12 h-12 text-zinc-700" />
                  <p className="text-sm">Vyberte soubor ze seznamu k zobrazení kódu</p>
                </div>
              )}
            </div>

          </div>
        </section>

      </main>

      {/* Patička */}
      <footer className="border-t border-zinc-900 py-8 mt-12 bg-zinc-950">
        <div className="max-w-6xl mx-auto px-4 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-zinc-500">
          <p>© 2026 Roblox AI Assistant. Všechna práva vyhrazena. 100% lokální řešení.</p>
          <div className="flex items-center gap-4">
            <span className="px-2 py-0.5 bg-zinc-900 rounded border border-zinc-800 font-mono text-[10px]">v2.1</span>
            <span className="text-zinc-600">|</span>
            <span>MIT Licence</span>
          </div>
        </div>
      </footer>

    </div>
  );
}
