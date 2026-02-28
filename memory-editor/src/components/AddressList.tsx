import { invoke } from "@tauri-apps/api/core";
import { useEffect, useState } from "react";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "./ui/table";
import { Snowflake, Pencil, Trash2 } from "lucide-react";

export interface AddressEntry {
  id: string;
  description: string;
  address: bigint;
  valueStr: string;
  type: string;
  frozen: boolean;
  frozenValue?: number[];
}

interface AddressListProps {
  pid: number | null;
  addressList: AddressEntry[];
  setAddressList: React.Dispatch<React.SetStateAction<AddressEntry[]>>;
  onSelectAddress: (addr: bigint | null) => void;
}

export function AddressList({
  pid,
  addressList,
  setAddressList,
  onSelectAddress,
}: AddressListProps) {
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editValue, setEditValue] = useState("");

  // Refresh values for non-frozen entries
  useEffect(() => {
    if (pid == null || addressList.length === 0) return;
    const interval = setInterval(async () => {
      const next = await Promise.all(
        addressList.map(async (entry) => {
          if (entry.frozen && entry.frozenValue) return entry;
          const size =
            entry.type === "int64" || entry.type === "double"
              ? 8
              : entry.type === "utf8" || entry.type === "utf16" || entry.type === "aob"
                ? (entry.frozenValue?.length ?? 4)
                : 4;
          try {
            const bytes = await invoke<number[]>("read_mem", {
              pid,
              address: Number(entry.address),
              size,
            });
            const valueStr = formatBytes(entry.type, bytes);
            return { ...entry, valueStr };
          } catch {
            return entry;
          }
        })
      );
      setAddressList(next);
    }, 500);
    return () => clearInterval(interval);
  }, [pid, addressList.length]);

  // When frozen, periodically write frozenValue to process memory
  useEffect(() => {
    if (pid == null) return;
    const frozen = addressList.filter((e) => e.frozen && e.frozenValue && e.frozenValue.length > 0);
    if (frozen.length === 0) return;
    const interval = setInterval(async () => {
      for (const entry of frozen) {
        if (!entry.frozenValue) continue;
        try {
          await invoke("write_mem", {
            pid,
            address: Number(entry.address),
            data: entry.frozenValue,
          });
        } catch {}
      }
    }, 100);
    return () => clearInterval(interval);
  }, [pid, addressList]);

  const toggleFreeze = (id: string) => {
    setAddressList((prev) =>
      prev.map((e) => {
        if (e.id !== id) return e;
        if (e.frozen) return { ...e, frozen: false, frozenValue: undefined };
        const size =
          e.type === "int64" || e.type === "double" ? 8 : 4;
        const frozenValue = e.frozenValue ?? Array(size).fill(0);
        return { ...e, frozen: true, frozenValue };
      })
    );
  };

  const remove = (id: string) => {
    setAddressList((prev) => prev.filter((e) => e.id !== id));
  };

  const startEdit = (entry: AddressEntry) => {
    setEditingId(entry.id);
    setEditValue(entry.valueStr);
  };

  const saveEdit = async () => {
    if (pid == null || editingId == null) return;
    const entry = addressList.find((e) => e.id === editingId);
    if (!entry) return;
    const bytes = parseValue(entry.type, editValue);
    if (bytes) {
      try {
        await invoke("write_mem", {
          pid,
          address: Number(entry.address),
          data: bytes,
        });
        setAddressList((prev) =>
          prev.map((e) =>
            e.id === editingId ? { ...e, valueStr: editValue, frozenValue: bytes } : e
          )
        );
      } catch (e) {
        console.error(e);
      }
    }
    setEditingId(null);
    setEditValue("");
  };

  function formatBytes(type: string, bytes: number[]): string {
    if (type === "int32" && bytes.length >= 4) {
      const n = new DataView(new Uint8Array(bytes).buffer).getInt32(0, true);
      return String(n);
    }
    if (type === "int64" && bytes.length >= 8) {
      const n = new DataView(new Uint8Array(bytes).buffer).getBigInt64(0, true);
      return String(n);
    }
    if (type === "float" && bytes.length >= 4) {
      const n = new DataView(new Uint8Array(bytes).buffer).getFloat32(0, true);
      return String(n);
    }
    if (type === "double" && bytes.length >= 8) {
      const n = new DataView(new Uint8Array(bytes).buffer).getFloat64(0, true);
      return String(n);
    }
    return bytes.map((b) => b.toString(16).padStart(2, "0")).join(" ");
  }

  function parseValue(type: string, s: string): number[] | null {
    const v = s.trim();
    const hex = v.startsWith("0x") ? v.slice(2) : null;
    try {
      if (type === "int32") {
        const n = hex ? parseInt(hex, 16) : parseInt(v, 10);
        const buf = new ArrayBuffer(4);
        new DataView(buf).setInt32(0, n, true);
        return [...new Uint8Array(buf)];
      }
      if (type === "int64") {
        const n = hex ? BigInt(hex) : BigInt(v);
        const buf = new ArrayBuffer(8);
        new DataView(buf).setBigInt64(0, n, true);
        return [...new Uint8Array(buf)];
      }
      if (type === "float") {
        const n = parseFloat(v);
        const buf = new ArrayBuffer(4);
        new DataView(buf).setFloat32(0, n, true);
        return [...new Uint8Array(buf)];
      }
      if (type === "double") {
        const n = parseFloat(v);
        const buf = new ArrayBuffer(8);
        new DataView(buf).setFloat64(0, n, true);
        return [...new Uint8Array(buf)];
      }
    } catch {
      return null;
    }
    return null;
  }

  return (
    <Card className="rounded-none border-0 flex flex-col flex-1 min-h-0">
      <CardHeader className="py-2 px-3 shrink-0">
        <CardTitle className="text-sm">Address List</CardTitle>
      </CardHeader>
      <CardContent className="p-0 flex-1 overflow-auto min-h-0">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead className="w-8" />
              <TableHead className="w-40">Description</TableHead>
              <TableHead className="w-32">Address</TableHead>
              <TableHead>Value</TableHead>
              <TableHead className="w-20">Type</TableHead>
              <TableHead className="w-20">Freeze</TableHead>
              <TableHead className="w-16" />
            </TableRow>
          </TableHeader>
          <TableBody>
            {addressList.map((entry) => (
              <TableRow
                key={entry.id}
                className="cursor-pointer"
                onClick={() => onSelectAddress(entry.address)}
              >
                <TableCell />
                <TableCell className="font-mono text-xs">
                  {entry.description || "-"}
                </TableCell>
                <TableCell className="font-mono text-xs">
                  0x{entry.address.toString(16).toUpperCase()}
                </TableCell>
                <TableCell className="font-mono text-xs">
                  {editingId === entry.id ? (
                    <Input
                      className="h-7 text-xs"
                      value={editValue}
                      onChange={(e) => setEditValue(e.target.value)}
                      onBlur={saveEdit}
                      onKeyDown={(e) => e.key === "Enter" && saveEdit()}
                      autoFocus
                    />
                  ) : (
                    <span
                      onClick={(e) => {
                        e.stopPropagation();
                        startEdit(entry);
                      }}
                      className="flex items-center gap-1"
                    >
                      {entry.valueStr}
                      <Pencil className="h-3 w-3 opacity-50" />
                    </span>
                  )}
                </TableCell>
                <TableCell className="text-xs">{entry.type}</TableCell>
                <TableCell>
                  <Button
                    size="icon"
                    variant={entry.frozen ? "default" : "ghost"}
                    className="h-7 w-7"
                    onClick={(e) => {
                      e.stopPropagation();
                      toggleFreeze(entry.id);
                    }}
                  >
                    <Snowflake className="h-3 w-3" />
                  </Button>
                </TableCell>
                <TableCell>
                  <Button
                    size="icon"
                    variant="ghost"
                    className="h-7 w-7"
                    onClick={(e) => {
                      e.stopPropagation();
                      remove(entry.id);
                    }}
                  >
                    <Trash2 className="h-3 w-3" />
                  </Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  );
}
