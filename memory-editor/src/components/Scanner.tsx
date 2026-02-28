import { invoke } from "@tauri-apps/api/core";
import { useState, useEffect, useRef } from "react";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "./ui/select";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "./ui/table";
import { Search, ChevronRight, Loader2, ListPlus } from "lucide-react";

const SCAN_TYPES = [
  "int32",
  "int64",
  "float",
  "double",
  "utf8",
  "utf16",
  "aob",
] as const;

const SCAN_CONDITIONS = [
  "exactvalue",
  "increasedvalue",
  "decreasedvalue",
  "changedvalue",
  "unchangedvalue",
  "biggerthan",
  "smallerthan",
] as const;

type ScanType = (typeof SCAN_TYPES)[number];
type ScanCondition = (typeof SCAN_CONDITIONS)[number];

interface ScanResultEntry {
  address: string;
  value_str: string;
  raw_bytes?: number[];
}

interface ScannerProps {
  pid: number | null;
  onScanResults: (results: { address: bigint; valueStr: string; rawBytes: number[] }[]) => void;
  scanResults: { address: bigint; valueStr: string; rawBytes: number[] }[];
  onAddToAddressList: (items: { address: bigint; valueStr: string; rawBytes: number[] }[]) => void;
}

export function Scanner({ pid, onScanResults, onAddToAddressList }: ScannerProps) {
  const [scanType, setScanType] = useState<ScanType>("int32");
  const [condition, setCondition] = useState<ScanCondition>("exactvalue");
  const [valueStr, setValueStr] = useState("");
  const [loading, setLoading] = useState(false);
  const [results, setResults] = useState<ScanResultEntry[]>([]);
  const [prevAddresses, setPrevAddresses] = useState<Array<[number, number[]]>>([]);
  const [selectedAddrs, setSelectedAddrs] = useState<Set<string>>(new Set());
  const addrKey = (r: ScanResultEntry) => String(r.address);
  const doFirstRef = useRef<() => void>(() => {});
  const doNextRef = useRef<() => void>(() => {});

  const doFirstScan = async () => {
    if (pid == null) return;
    setLoading(true);
    try {
      const res = await invoke<ScanResultEntry[]>("scanner_first_scan", {
        pid,
        params: {
          scan_type: scanType,
          condition,
          value_str: valueStr.trim() || null,
          aob_bytes: null,
        },
      });
      setResults(res);
      setPrevAddresses(
        res.map((r) => {
          const addr = typeof r.address === "bigint" ? Number(r.address) : Number(r.address);
          return [addr, (r.raw_bytes ?? []).map(Number)] as [number, number[]];
        })
      );
      onScanResults(
        res.map((r) => ({
          address: typeof r.address === "bigint" ? r.address : BigInt(r.address),
          valueStr: r.value_str,
          rawBytes: (r.raw_bytes ?? []).map(Number),
        }))
      );
    } catch (e: unknown) {
      console.error(e);
      setResults([]);
      setPrevAddresses([]);
      onScanResults([]);
    } finally {
      setLoading(false);
    }
  };

  const doNextScan = async () => {
    if (pid == null || prevAddresses.length === 0) return;
    setLoading(true);
    try {
      const prev = prevAddresses.map(([addr, bytes]) => [addr, bytes] as [number, number[]]);
      const res = await invoke<ScanResultEntry[]>("scanner_next_scan", {
        pid,
        params: {
          scan_type: scanType,
          condition,
          value_str: valueStr.trim() || null,
          aob_bytes: null,
        },
        prev_addresses: prev,
      });
      setResults(res);
      setPrevAddresses(
        res.map((r) => {
          const addr = typeof r.address === "bigint" ? Number(r.address) : r.address;
          return [addr, (r.raw_bytes ?? []).map(Number)] as [number, number[]];
        })
      );
      onScanResults(
        res.map((r) => ({
          address: typeof r.address === "bigint" ? r.address : BigInt(r.address),
          valueStr: r.value_str,
          rawBytes: (r.raw_bytes ?? []).map(Number),
        }))
      );
    } catch (e: unknown) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  doFirstRef.current = doFirstScan;
  doNextRef.current = doNextScan;
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.ctrlKey && e.key === "f") {
        e.preventDefault();
        doFirstRef.current();
      } else if (e.ctrlKey && e.key === "n") {
        e.preventDefault();
        doNextRef.current();
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  return (
    <Card className="rounded-none border-0 border-b flex flex-col flex-1 min-h-0">
      <CardHeader className="py-2 px-3 shrink-0">
        <CardTitle className="text-sm">Memory Scanner</CardTitle>
        <div className="flex flex-wrap items-end gap-2 mt-2">
          <div className="flex flex-col gap-1">
            <Label className="text-xs">Type</Label>
            <Select value={scanType} onValueChange={(v) => setScanType(v as ScanType)}>
              <SelectTrigger className="w-28 h-8">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {SCAN_TYPES.map((t) => (
                  <SelectItem key={t} value={t}>
                    {t}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="flex flex-col gap-1">
            <Label className="text-xs">Condition</Label>
            <Select value={condition} onValueChange={(v) => setCondition(v as ScanCondition)}>
              <SelectTrigger className="w-36 h-8">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {SCAN_CONDITIONS.map((c) => (
                  <SelectItem key={c} value={c}>
                    {c}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="flex flex-col gap-1">
            <Label className="text-xs">Value (hex: 0x...)</Label>
            <Input
              className="w-40 h-8"
              placeholder="100 or 0x64"
              value={valueStr}
              onChange={(e) => setValueStr(e.target.value)}
            />
          </div>
          <Button
            size="sm"
            onClick={doFirstScan}
            disabled={pid == null || loading}
            title="First scan (Ctrl+F)"
          >
            {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Search className="h-4 w-4" />}
            First Scan
          </Button>
          <Button
            size="sm"
            variant="outline"
            onClick={doNextScan}
            disabled={pid == null || loading || prevAddresses.length === 0}
            title="Next scan (Ctrl+N)"
          >
            <ChevronRight className="h-4 w-4" />
            Next Scan
          </Button>
          <Button
            size="sm"
            variant="secondary"
            onClick={() => {
              const items = results
                .filter((r) => selectedAddrs.has(addrKey(r)))
                .map((r) => ({
                  address: BigInt(r.address),
                  valueStr: r.value_str,
                  rawBytes: (r.raw_bytes ?? []).map(Number),
                }));
              if (items.length) onAddToAddressList(items);
            }}
            disabled={results.length === 0 || selectedAddrs.size === 0}
          >
            <ListPlus className="h-4 w-4" />
            Add selected to list
          </Button>
        </div>
      </CardHeader>
      <CardContent className="p-0 flex-1 overflow-auto min-h-0">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead className="w-8">
                <input
                  type="checkbox"
                  checked={results.length > 0 && selectedAddrs.size === results.slice(0, 2000).length}
                  onChange={(e) => {
                    if (e.target.checked)
                      setSelectedAddrs(new Set(results.slice(0, 2000).map(addrKey)));
                    else setSelectedAddrs(new Set());
                  }}
                />
              </TableHead>
              <TableHead className="w-32">Address</TableHead>
              <TableHead>Value</TableHead>
              <TableHead className="w-24">Type</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {results.slice(0, 2000).map((r) => (
              <TableRow
                key={r.address}
                className="cursor-pointer"
                onClick={() => {
                  setSelectedAddrs((prev) => {
                    const next = new Set(prev);
                    const k = addrKey(r);
                    if (next.has(k)) next.delete(k);
                    else next.add(k);
                    return next;
                  });
                }}
              >
                <TableCell onClick={(e) => e.stopPropagation()}>
                  <input
                    type="checkbox"
                    checked={selectedAddrs.has(addrKey(r))}
                    onChange={(e) => {
                      setSelectedAddrs((prev) => {
                        const next = new Set(prev);
                        if (e.target.checked) next.add(addrKey(r));
                        else next.delete(addrKey(r));
                        return next;
                      });
                    }}
                  />
                </TableCell>
                <TableCell className="font-mono text-xs">
                  0x{BigInt(r.address).toString(16).toUpperCase()}
                </TableCell>
                <TableCell className="font-mono text-xs">{r.value_str}</TableCell>
                <TableCell className="text-xs">{scanType}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
        {results.length > 2000 && (
          <p className="text-xs text-muted-foreground px-3 py-1">
            Showing first 2000 of {results.length} results.
          </p>
        )}
      </CardContent>
    </Card>
  );
}
