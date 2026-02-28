import { invoke } from "@tauri-apps/api/core";
import { useEffect, useState } from "react";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import { Crosshair } from "lucide-react";

const BYTES_PER_ROW = 16;
const ROWS = 16;
const TOTAL_BYTES = BYTES_PER_ROW * ROWS;

interface MemoryViewerProps {
  pid: number | null;
  selectedAddress: bigint | null;
  onSelectAddress?: (addr: bigint | null) => void;
}

export function MemoryViewer({
  pid,
  selectedAddress,
}: MemoryViewerProps) {
  const [baseAddress, setBaseAddress] = useState<bigint>(BigInt(0));
  const [gotoInput, setGotoInput] = useState("");
  const [bytes, setBytes] = useState<number[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (selectedAddress != null) setBaseAddress(selectedAddress);
  }, [selectedAddress]);

  useEffect(() => {
    if (pid == null) {
      setBytes([]);
      setError(null);
      return;
    }
    setLoading(true);
    setError(null);
    const addr = baseAddress;
    invoke<number[]>("read_mem", {
      pid,
      address: Number(addr),
      size: TOTAL_BYTES,
    })
      .then(setBytes)
      .catch((e) => setError(String(e)))
      .finally(() => setLoading(false));
  }, [pid, baseAddress]);

  const goto = () => {
    const s = gotoInput.trim().replace(/^0x/i, "");
    if (!s) return;
    try {
      const addr = BigInt("0x" + s);
      setBaseAddress(addr);
      setGotoInput("");
    } catch {
      setError("Invalid address");
    }
  };

  return (
    <Card className="rounded-none border-0 h-full flex flex-col">
      <CardHeader className="py-1 px-3 shrink-0 flex flex-row items-center gap-2">
        <CardTitle className="text-sm">Memory Viewer</CardTitle>
        <div className="flex items-center gap-1">
          <Input
            className="w-32 h-7 font-mono text-xs"
            placeholder="0x0"
            value={gotoInput}
            onChange={(e) => setGotoInput(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && goto()}
          />
          <Button size="sm" variant="outline" className="h-7" onClick={goto}>
            <Crosshair className="h-4 w-4" />
            Goto
          </Button>
        </div>
      </CardHeader>
      <CardContent className="p-2 font-mono text-xs overflow-auto flex-1 min-h-0">
        {error && <p className="text-destructive text-xs mb-1">{error}</p>}
        {loading ? (
          <p className="text-muted-foreground">Loading...</p>
        ) : (
          <table className="w-full">
            <tbody>
              {Array.from({ length: ROWS }).map((_, row) => {
                const offset = row * BYTES_PER_ROW;
                const addr = baseAddress + BigInt(offset);
                return (
                  <tr key={row} className="hover:bg-muted/30">
                    <td className="text-muted-foreground w-24 pr-2 select-none">
                      0x{addr.toString(16).toUpperCase().padStart(8, "0")}
                    </td>
                    <td className="space-x-0.5">
                      {Array.from({ length: BYTES_PER_ROW }).map((_, col) => {
                        const i = offset + col;
                        const b = bytes[i] ?? 0;
                        return (
                          <span
                            key={col}
                            className={
                              selectedAddress !== null &&
                              baseAddress + BigInt(i) === selectedAddress
                                ? "bg-primary text-primary-foreground px-0.5"
                                : ""
                            }
                          >
                            {b.toString(16).padStart(2, "0").toUpperCase()}
                          </span>
                        );
                      })}
                    </td>
                    <td className="pl-2 text-muted-foreground">
                      {Array.from({ length: BYTES_PER_ROW })
                        .map((_, col) => {
                          const b = bytes[offset + col] ?? 0;
                          return b >= 32 && b < 127 ? String.fromCharCode(b) : ".";
                        })
                        .join("")}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </CardContent>
    </Card>
  );
}
