//! Read/write process memory.
//! Linux: process_vm_readv / process_vm_writev (after ptrace attach).

use serde::{Deserialize, Serialize};

/// Read bytes from process memory at given address.
pub fn read_memory(pid: u32, address: u64, size: usize) -> Result<Vec<u8>, String> {
    #[cfg(target_os = "linux")]
    return read_memory_linux(pid, address, size);

    #[cfg(not(target_os = "linux"))]
    let _ = (pid, address, size);
    Err("Memory read is only implemented for Linux.".to_string())
}

#[cfg(target_os = "linux")]
fn read_memory_linux(pid: u32, address: u64, size: usize) -> Result<Vec<u8>, String> {
    use std::io::IoSliceMut;
    use nix::sys::uio::{process_vm_readv, RemoteIoVec};

    if size == 0 {
        return Ok(Vec::new());
    }
    let mut buf = vec![0u8; size];
    let mut local = [IoSliceMut::new(&mut buf)];
    let remote = [RemoteIoVec {
        base: address as usize,
        len: size,
    }];
    process_vm_readv(
        nix::unistd::Pid::from_raw(pid as i32),
        &mut local,
        &remote,
    )
    .map_err(|e| format!("process_vm_readv failed: {}. Ensure process is attached (ptrace).", e))?;
    Ok(buf)
}

/// Write bytes to process memory.
pub fn write_memory(pid: u32, address: u64, data: &[u8]) -> Result<(), String> {
    #[cfg(target_os = "linux")]
    return write_memory_linux(pid, address, data);

    #[cfg(not(target_os = "linux"))]
    let _ = (pid, address, data);
    Err("Memory write is only implemented for Linux.".to_string())
}

#[cfg(target_os = "linux")]
fn write_memory_linux(pid: u32, address: u64, data: &[u8]) -> Result<(), String> {
    use std::io::IoSlice;
    use nix::sys::uio::{process_vm_writev, RemoteIoVec};

    if data.is_empty() {
        return Ok(());
    }
    let local = [IoSlice::new(data)];
    let remote = [RemoteIoVec {
        base: address as usize,
        len: data.len(),
    }];
    process_vm_writev(
        nix::unistd::Pid::from_raw(pid as i32),
        &local,
        &remote,
    )
    .map_err(|e| format!("process_vm_writev failed: {}", e))?;
    Ok(())
}

/// Memory region from /proc/pid/maps (for scanner and viewer).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MemoryRegion {
    pub start: u64,
    pub end: u64,
    pub readable: bool,
    pub writable: bool,
    pub executable: bool,
    pub path: Option<String>,
}

pub fn get_memory_regions(pid: u32) -> Result<Vec<MemoryRegion>, String> {
    #[cfg(target_os = "linux")]
    return get_memory_regions_linux(pid);

    #[cfg(not(target_os = "linux"))]
    let _ = pid;
    Err("Memory regions only on Linux.".to_string())
}

#[cfg(target_os = "linux")]
fn get_memory_regions_linux(pid: u32) -> Result<Vec<MemoryRegion>, String> {
    use procfs::process::Process;
    use procfs_core::process::{MMapPath, MMPermissions};

    let proc = Process::new(pid as i32).map_err(|e| format!("Process {}: {}", pid, e))?;
    let maps = proc.maps().map_err(|e| format!("maps: {}", e))?;
    let mut out = Vec::new();
    for map in maps {
        let path = match &map.pathname {
            MMapPath::Path(p) => Some(p.display().to_string()),
            _ => None,
        };
        out.push(MemoryRegion {
            start: map.address.0 as u64,
            end: map.address.1 as u64,
            readable: map.perms.contains(MMPermissions::READ),
            writable: map.perms.contains(MMPermissions::WRITE),
            executable: map.perms.contains(MMPermissions::EXECUTE),
            path,
        });
    }
    Ok(out)
}
