//! Memory Editor - Tauri backend.
//! Process list, attach, memory read/write, scanner, address list.

mod memory;
mod process;
mod scanner;

use memory::{get_memory_regions, read_memory, write_memory, MemoryRegion};
use process::{attach_process, detach_process, list_processes, ProcessInfo};
use scanner::{first_scan, next_scan, ScanParams, ScanResultEntry};
use std::sync::Mutex;

/// Attached PID; guarded for multi-thread access.
static ATTACHED_PID: Mutex<Option<u32>> = Mutex::new(None);

#[tauri::command]
fn get_process_list() -> Result<Vec<ProcessInfo>, String> {
    list_processes()
}

#[tauri::command]
fn attach(pid: u32) -> Result<(), String> {
    attach_process(pid)?;
    *ATTACHED_PID.lock().map_err(|e| e.to_string())? = Some(pid);
    Ok(())
}

#[tauri::command]
fn detach(pid: u32) -> Result<(), String> {
    detach_process(pid)?;
    let mut guard = ATTACHED_PID.lock().map_err(|e| e.to_string())?;
    if *guard == Some(pid) {
        *guard = None;
    }
    Ok(())
}

#[tauri::command]
fn get_attached_pid() -> Option<u32> {
    ATTACHED_PID.lock().ok().and_then(|g| *g)
}

#[tauri::command]
fn read_mem(pid: u32, address: u64, size: usize) -> Result<Vec<u8>, String> {
    read_memory(pid, address, size)
}

#[tauri::command]
fn write_mem(pid: u32, address: u64, data: Vec<u8>) -> Result<(), String> {
    write_memory(pid, address, &data)
}

#[tauri::command]
fn get_maps(pid: u32) -> Result<Vec<MemoryRegion>, String> {
    get_memory_regions(pid)
}

#[tauri::command]
fn scanner_first_scan(pid: u32, params: ScanParams) -> Result<Vec<ScanResultEntry>, String> {
    first_scan(pid, &params)
}

#[tauri::command]
fn scanner_next_scan(
    pid: u32,
    params: ScanParams,
    prev_addresses: Vec<(u64, Vec<u8>)>,
) -> Result<Vec<ScanResultEntry>, String> {
    next_scan(pid, &params, &prev_addresses)
}

/// Simple pointer scan: find addresses in [start, end) that contain `target_value` (4 or 8 bytes).
#[tauri::command]
fn pointer_scan(
    pid: u32,
    start: u64,
    end: u64,
    target_value: u64,
    pointer_size_8: bool,
) -> Result<Vec<u64>, String> {
    let size: usize = if pointer_size_8 { 8 } else { 4 };
    if start >= end || (end - start) > 512 * 1024 * 1024 {
        return Err("Invalid or too large range".to_string());
    }
    let mut results = Vec::new();
    let chunk: usize = 256 * 1024;
    let mut addr = start;
    while addr + (size as u64) <= end {
        let to_read = ((end - addr) as usize).min(chunk + size);
        match read_memory(pid, addr, to_read) {
            Ok(buf) => {
                let step = size;
                for i in (0..buf.len().saturating_sub(size)).step_by(step) {
                    let val = if pointer_size_8 && buf.len() >= i + 8 {
                        u64::from_le_bytes(buf[i..i + 8].try_into().unwrap())
                    } else if buf.len() >= i + 4 {
                        u32::from_le_bytes(buf[i..i + 4].try_into().unwrap()) as u64
                    } else {
                        continue;
                    };
                    if val == target_value {
                        results.push(addr + i as u64);
                    }
                }
            }
            Err(_) => {}
        }
        addr += to_read as u64;
        if results.len() > 100_000 {
            break;
        }
    }
    Ok(results)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![
            get_process_list,
            attach,
            detach,
            get_attached_pid,
            read_mem,
            write_mem,
            get_maps,
            scanner_first_scan,
            scanner_next_scan,
            pointer_scan,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
