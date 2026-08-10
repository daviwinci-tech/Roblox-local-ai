import time

class AgentStatus:
    IDLE = "idle"
    PLANNING = "planning"
    INVESTIGATING = "investigating"
    EDITING = "editing"
    WAITING_FOR_APPROVAL = "waiting_for_approval"
    TESTING = "testing"
    VERIFYING = "verifying"
    COMPLETED = "completed"
    FAILED = "failed"
    STOPPED = "stopped"

class AgentState:
    def __init__(self, task_id: str, goal: str):
        self.task_id = task_id
        self.goal = goal
        self.status = AgentStatus.PLANNING
        self.created_at = time.time()
        self.updated_at = time.time()
        
        self.plan = []           # List of step strings e.g. ["Analyze MiningServer script", "Find RemoteEvent calls"]
        self.current_step = 0
        self.iteration = 0
        self.max_iterations = 20
        
        self.files_inspected = [] # List of script paths read
        self.files_modified = []  # List of script paths modified
        self.pending_diffs = []   # List of dicts: {"path": str, "old_source": str, "new_source": str, "description": str}
        
        self.logs = []            # Step execution logs for UI feed
        self.messages = []        # Conversation history for LLM
        self.tool_calls_history = []
        self.error_message = None

    def add_log(self, level: str, message: str, details=None):
        entry = {
            "timestamp": time.time(),
            "level": level, # info, tool, warning, error, success
            "message": message,
            "details": details
        }
        self.logs.append(entry)
        self.updated_at = time.time()
        print(f"[{level.upper()}] {message}")

    def add_pending_diff(self, path: str, old_source: str, new_source: str, description: str):
        diff_entry = {
            "id": f"diff_{len(self.pending_diffs) + 1}",
            "path": path,
            "old_source": old_source,
            "new_source": new_source,
            "description": description,
            "approved": None
        }
        self.pending_diffs.append(diff_entry)
        self.status = AgentStatus.WAITING_FOR_APPROVAL
        self.add_log("warning", f"Vyžadováno schválení úpravy pro skript: {path}", details={"diff_id": diff_entry["id"]})

    def to_dict(self):
        return {
            "task_id": self.task_id,
            "goal": self.goal,
            "status": self.status,
            "iteration": self.iteration,
            "max_iterations": self.max_iterations,
            "plan": self.plan,
            "current_step": self.current_step,
            "files_inspected": self.files_inspected,
            "files_modified": self.files_modified,
            "pending_diffs": self.pending_diffs,
            "logs": self.logs[-30:], # Posledních 30 logů pro přehlednost UI
            "error_message": self.error_message,
            "created_at": self.created_at,
            "updated_at": self.updated_at
        }
