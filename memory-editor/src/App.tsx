import { invoke } from "@tauri-apps/api/core";
import { useEffect, useState } from "react";
import { ProcessList } from "./components/ProcessList";
import { Scanner } from "./components/Scanner";
import { AddressList } from "./components/AddressList";
import { MemoryViewer } from "./components/MemoryViewer";
import { Button } from "./components/ui/button";
import { useToast } from "./hooks/useToast";
import { RefreshCw } from "lucide-react";
import "./index.css";

function App() {
  const [attachedPid, setAttachedPid] = useState<number | null>(null);
  const [selectedAddress, setSelectedAddress] = useState<bigint | null>(null);
  const [scanResults, setScanResults] = useState<{ address: bigint; valueStr: string; rawBytes: number[] }[]>([]);
  const [addressList, setAddressList] = useState<
    { id: string; description: string; address: bigint; valueStr: string; type: string; frozen: boolean; frozenValue?: number[] }[]
  >([]);
  const { toast } = useToast();

  const refreshAttached = async () => {
    try {
      const pid = await invoke<number | null>("get_attached_pid");
      setAttachedPid(pid ?? null);
    } catch {
      setAttachedPid(null);
    }
  };

  useEffect(() => {
    refreshAttached();
  }, []);

  const handleAttach = (pid: number) => {
    invoke("attach", { pid })
      .then(() => {
        setAttachedPid(pid);
        toast({ title: "Attached", description: `Attached to PID ${pid}` });
      })
      .catch((e: string) => {
        toast({
          variant: "destructive",
          title: "Attach failed",
          description: e || "Check permissions (e.g. ptrace_scope, run as root)",
        });
      });
  };

  const handleDetach = () => {
    if (attachedPid == null) return;
    invoke("detach", { pid: attachedPid })
      .then(() => {
        setAttachedPid(null);
        toast({ title: "Detached", description: `Detached from PID ${attachedPid}` });
      })
      .catch((e: string) => {
        toast({ variant: "destructive", title: "Detach failed", description: e });
      });
  };

  return (
    <div className="flex h-screen flex-col bg-background text-foreground">
      <header className="flex h-12 shrink-0 items-center gap-2 border-b border-border px-3">
        <span className="font-semibold text-primary">Memory Editor</span>
        {attachedPid != null && (
          <>
            <span className="text-muted-foreground">PID: {attachedPid}</span>
            <Button variant="outline" size="sm" onClick={handleDetach}>
              Detach
            </Button>
          </>
        )}
        <div className="flex-1" />
        <Button variant="ghost" size="icon" onClick={refreshAttached} title="Refresh">
          <RefreshCw className="h-4 w-4" />
        </Button>
      </header>

      <div className="flex flex-1 min-h-0">
        <aside className="w-64 shrink-0 border-r border-border flex flex-col overflow-hidden">
          <ProcessList
            attachedPid={attachedPid}
            onAttach={handleAttach}
            onAttachedPidChange={setAttachedPid}
          />
        </aside>

        <main className="flex flex-1 flex-col min-h-0 overflow-hidden">
          <div className="flex flex-1 min-h-0 border-b border-border">
            <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
              <Scanner
                pid={attachedPid}
                onScanResults={setScanResults}
                scanResults={scanResults}
                onAddToAddressList={(items) =>
                  setAddressList((prev) => [
                    ...prev,
                    ...items.map((r, i) => ({
                      id: `addr-${Date.now()}-${i}`,
                      description: "",
                      address: r.address,
                      valueStr: r.valueStr,
                      type: "int32",
                      frozen: false,
                      frozenValue: r.rawBytes,
                    })),
                  ])
                }
              />
              <AddressList
                pid={attachedPid}
                addressList={addressList}
                setAddressList={setAddressList}
                onSelectAddress={setSelectedAddress}
              />
            </div>
          </div>

          <div className="h-48 shrink-0 overflow-hidden border-t border-border">
            <MemoryViewer
              pid={attachedPid}
              selectedAddress={selectedAddress}
              onSelectAddress={setSelectedAddress}
            />
          </div>
        </main>
      </div>

    </div>
  );
}

export default App;
