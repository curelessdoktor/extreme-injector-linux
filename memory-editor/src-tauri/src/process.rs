//! Process listing and attach logic.
//! Linux: /proc + ptrace. Windows/macOS: stubs or platform APIs.

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProcessInfo {
    pub pid: u32,
    pub name: String,
    /// Icon path or base64; optional, often not available on Linux
    pub icon: Option<String>,
}

/// List running processes. On Linux uses /proc; requires no special privileges for listing.
pub fn list_processes() -> Result<Vec<ProcessInfo>, String> {
    #[cfg(target_os = "linux")]
    return list_processes_linux();

    #[cfg(not(target_os = "linux"))]
    Err("Process listing is only implemented for Linux. Windows/macOS: use stub or add platform code.".to_string())
}

#[cfg(target_os = "linux")]
fn list_processes_linux() -> Result<Vec<ProcessInfo>, String> {
    let all = procfs::process::all_processes().map_err(|e| {
        format!(
            "Failed to read /proc. On Linux you need read access to /proc. Error: {}",
            e
        )
    })?;

    let mut out = Vec::new();
    for proc in all.flatten() {
        let pid = proc.pid();
        let name = proc
            .cmdline()
            .ok()
            .and_then(|c| c.into_iter().next())
            .or_else(|| proc.stat().ok().map(|s| s.comm.clone()))
            .unwrap_or_else(|| format!("[{}]", pid));
        out.push(ProcessInfo {
            pid: pid as u32,
            name,
            icon: None,
        });
    }
    out.sort_by(|a, b| a.name.to_lowercase().cmp(&b.name.to_lowercase()));
    Ok(out)
}

/// Attach to process for memory access. On Linux this uses ptrace(PTRACE_ATTACH).
/// Requires: same user or root; on some systems you may need to set ptrace_scope:
///   echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
pub fn attach_process(pid: u32) -> Result<(), String> {
    #[cfg(target_os = "linux")]
    return attach_process_linux(pid);

    #[cfg(not(target_os = "linux"))]
    let _ = pid;
    Err("Attach is only implemented for Linux.".to_string())
}

#[cfg(target_os = "linux")]
fn attach_process_linux(pid: u32) -> Result<(), String> {
    use nix::sys::ptrace;
    use nix::sys::wait::waitpid;
    use nix::unistd::Pid;

    let pid_nix = Pid::from_raw(pid as i32);
    ptrace::attach(pid_nix).map_err(|e| {
        match e {
            nix::errno::Errno::EPERM => "Permission denied. Try: (1) Run this app as root, or (2) Same user as target, and run: echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope".to_string(),
            nix::errno::Errno::ESRCH => "No such process.".to_string(),
            _ => format!("ptrace attach failed: {}", e),
        }
    })?;
    // Wait for the process to stop
    let _ = waitpid(pid_nix, None);
    Ok(())
}

/// Detach from process.
pub fn detach_process(pid: u32) -> Result<(), String> {
    #[cfg(target_os = "linux")]
    return detach_process_linux(pid);

    #[cfg(not(target_os = "linux"))]
    let _ = pid;
    Err("Detach is only implemented for Linux.".to_string())
}

#[cfg(target_os = "linux")]
fn detach_process_linux(pid: u32) -> Result<(), String> {
    use nix::sys::ptrace;
    use nix::unistd::Pid;

    let pid_nix = Pid::from_raw(pid as i32);
    ptrace::detach(pid_nix, None).map_err(|e| format!("ptrace detach failed: {}", e))?;
    Ok(())
}
