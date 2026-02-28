import { invoke } from "@tauri-apps/api/core";
import { useEffect, useState } from "react";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Loader2, Cpu } from "lucide-react";

export interface ProcessInfo {
  pid: number;
  name: string;
  icon?: string;
}

interface ProcessListProps {
  attachedPid: number | null;
  onAttach: (pid: number) => void;
  onAttachedPidChange?: (pid: number | null) => void;
}

export function ProcessList({ attachedPid, onAttach }: ProcessListProps) {
  const [processes, setProcesses] = useState<ProcessInfo[]>([]);
  const [loading, setLoading] = useState(false);
  const [filter, setFilter] = useState("");

  const load = async () => {
    setLoading(true);
    try {
      const list = await invoke<ProcessInfo[]>("get_process_list");
      setProcesses(list);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const filtered = filter.trim()
    ? processes.filter(
        (p) =>
          p.name.toLowerCase().includes(filter.toLowerCase()) ||
          String(p.pid).includes(filter)
      )
    : processes;

  return (
    <Card className="rounded-none border-0 border-b flex flex-col flex-1 min-h-0">
      <CardHeader className="py-2 px-3 shrink-0">
        <CardTitle className="text-sm flex items-center gap-2">
          <Cpu className="h-4 w-4" />
          Processes
        </CardTitle>
        <div className="flex gap-1 mt-1">
          <Input
            placeholder="Filter..."
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
            className="h-8 text-xs"
          />
          <Button size="sm" variant="outline" onClick={load} disabled={loading}>
            {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : "Refresh"}
          </Button>
        </div>
      </CardHeader>
      <CardContent className="p-0 flex-1 overflow-auto min-h-0">
        <ul className="text-sm">
          {filtered.slice(0, 500).map((p) => (
            <li
              key={p.pid}
              className={`flex items-center gap-2 px-3 py-1.5 cursor-pointer border-b border-border/50 hover:bg-muted/50 ${
                attachedPid === p.pid ? "bg-primary/20 text-primary" : ""
              }`}
              onClick={() => {
                if (attachedPid === p.pid) return;
                onAttach(p.pid);
              }}
            >
              <span className="truncate flex-1" title={p.name}>
                {p.name || `[${p.pid}]`}
              </span>
              <span className="text-muted-foreground shrink-0">{p.pid}</span>
            </li>
          ))}
        </ul>
        {filtered.length > 500 && (
          <p className="text-xs text-muted-foreground px-3 py-1">
            Showing first 500. Use filter to narrow.
          </p>
        )}
      </CardContent>
    </Card>
  );
}
