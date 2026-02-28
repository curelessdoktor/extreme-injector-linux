//! Memory scanner: exact value, increased, decreased, changed, unchanged.
//! Supports: 4/8 byte int, float, double, string (UTF-8/UTF-16), byte array (AoB).

use serde::{Deserialize, Serialize};

use crate::memory;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ScanType {
    Int32,
    Int64,
    Float,
    Double,
    Utf8,
    Utf16,
    Aob, // Array of bytes
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ScanCondition {
    ExactValue,
    IncreasedValue,
    DecreasedValue,
    ChangedValue,
    UnchangedValue,
    BiggerThan,
    SmallerThan,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScanParams {
    pub scan_type: ScanType,
    pub condition: ScanCondition,
    /// For ExactValue: string value or parsed number; for Aob: hex string "DE AD BE EF"
    pub value_str: Option<String>,
    /// For Aob: bytes to search
    pub aob_bytes: Option<Vec<u8>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScanResultEntry {
    pub address: u64,
    pub value_str: String,
    pub raw_bytes: Option<Vec<u8>>,
}

/// Parse hex (0x...) or decimal or float from string.
fn parse_value_for_type(s: &str, scan_type: ScanType) -> Result<Vec<u8>, String> {
    let s = s.trim();
    let hex = s.strip_prefix("0x").or_else(|| s.strip_prefix("0X"));
    match scan_type {
        ScanType::Int32 => {
            let n: i32 = if let Some(h) = hex {
                i32::from_str_radix(h, 16).map_err(|e| e.to_string())?
            } else {
                s.parse::<i32>().map_err(|e| e.to_string())?
            };
            Ok(n.to_le_bytes().to_vec())
        }
        ScanType::Int64 => {
            let n: i64 = if let Some(h) = hex {
                i64::from_str_radix(h, 16).map_err(|e| e.to_string())?
            } else {
                s.parse::<i64>().map_err(|e| e.to_string())?
            };
            Ok(n.to_le_bytes().to_vec())
        }
        ScanType::Float => {
            let n: f32 = s.parse::<f32>().map_err(|e| e.to_string())?;
            Ok(n.to_le_bytes().to_vec())
        }
        ScanType::Double => {
            let n: f64 = s.parse::<f64>().map_err(|e| e.to_string())?;
            Ok(n.to_le_bytes().to_vec())
        }
        ScanType::Utf8 => Ok(s.as_bytes().to_vec()),
        ScanType::Utf16 => {
            let utf16: Vec<u16> = s.encode_utf16().collect();
            let mut bytes = Vec::with_capacity(utf16.len() * 2);
            for u in utf16 {
                bytes.extend_from_slice(&u.to_le_bytes());
            }
            Ok(bytes)
        }
        ScanType::Aob => {
            let hex_str: String = s.split_whitespace().collect::<Vec<_>>().join("");
            if hex_str.len() % 2 != 0 {
                return Err("AOB hex length must be even.".to_string());
            }
            let mut bytes = Vec::new();
            for chunk in hex_str.as_bytes().chunks(2) {
                let s = std::str::from_utf8(chunk).map_err(|_| "Invalid hex")?;
                let b = u8::from_str_radix(s, 16).map_err(|e| e.to_string())?;
                bytes.push(b);
            }
            Ok(bytes)
        }
    }
}

fn type_size(scan_type: ScanType, value_len: Option<usize>) -> Option<usize> {
    match scan_type {
        ScanType::Int32 => Some(4),
        ScanType::Int64 => Some(8),
        ScanType::Float => Some(4),
        ScanType::Double => Some(8),
        ScanType::Utf8 | ScanType::Utf16 => value_len,
        ScanType::Aob => value_len,
    }
}

fn format_value(scan_type: ScanType, bytes: &[u8]) -> String {
    match scan_type {
        ScanType::Int32 => {
            if bytes.len() >= 4 {
                let n = i32::from_le_bytes([bytes[0], bytes[1], bytes[2], bytes[3]]);
                format!("{}", n)
            } else {
                format!("{:?}", bytes)
            }
        }
        ScanType::Int64 => {
            if bytes.len() >= 8 {
                let n = i64::from_le_bytes(bytes[..8].try_into().unwrap());
                format!("{}", n)
            } else {
                format!("{:?}", bytes)
            }
        }
        ScanType::Float => {
            if bytes.len() >= 4 {
                let n = f32::from_le_bytes([bytes[0], bytes[1], bytes[2], bytes[3]]);
                format!("{}", n)
            } else {
                format!("{:?}", bytes)
            }
        }
        ScanType::Double => {
            if bytes.len() >= 8 {
                let n = f64::from_le_bytes(bytes[..8].try_into().unwrap());
                format!("{}", n)
            } else {
                format!("{:?}", bytes)
            }
        }
        ScanType::Utf8 => String::from_utf8_lossy(bytes).to_string(),
        ScanType::Utf16 => {
            let mut s = String::new();
            for chunk in bytes.chunks(2) {
                if chunk.len() == 2 {
                    let u = u16::from_le_bytes([chunk[0], chunk[1]]);
                    if let Some(c) = char::from_u32(u as u32) {
                        s.push(c);
                    }
                }
            }
            s
        }
        ScanType::Aob => bytes.iter().map(|b| format!("{:02X}", b)).collect::<Vec<_>>().join(" "),
    }
}

/// First scan: iterate readable regions, compare with value/condition.
pub fn first_scan(pid: u32, params: &ScanParams) -> Result<Vec<ScanResultEntry>, String> {
    use crate::scanner::ScanCondition::*;

    let regions = memory::get_memory_regions(pid)?;
    let value_bytes = params
        .value_str
        .as_deref()
        .map(|s| parse_value_for_type(s, params.scan_type))
        .transpose()?
        .or(params.aob_bytes.clone());

    let size = match params.condition {
        ExactValue | BiggerThan | SmallerThan => value_bytes
            .as_ref()
            .and_then(|v| type_size(params.scan_type, Some(v.len())))
            .ok_or("Value or AOB required for this scan type")?,
        _ => type_size(params.scan_type, value_bytes.as_ref().map(|v| v.len()))
            .unwrap_or(4),
    };

    let mut results = Vec::new();
    for r in regions {
        if !r.readable || r.start >= r.end {
            continue;
        }
        let region_size = (r.end - r.start) as usize;
        if region_size < size {
            continue;
        }
        let chunk_size = (1024 * 1024).min(region_size);
        let mut offset = 0usize;
        while offset + size <= region_size {
            let to_read = (chunk_size + size - 1).min(region_size - offset);
            let addr = r.start + offset as u64;
            match memory::read_memory(pid, addr, to_read) {
                Ok(buf) => {
                    for i in (0..buf.len().saturating_sub(size)).step_by(align_step(params.scan_type)) {
                        let slice = &buf[i..i + size];
                        if matches_condition(
                            params.condition,
                            params.scan_type,
                            slice,
                            value_bytes.as_deref(),
                        )? {
                            let value_str = format_value(params.scan_type, slice);
                            results.push(ScanResultEntry {
                                address: addr + i as u64,
                                value_str,
                                raw_bytes: Some(slice.to_vec()),
                            });
                        }
                    }
                }
                Err(_) => {}
            }
            offset += to_read;
            if results.len() > 500_000 {
                return Ok(results);
            }
        }
    }
    Ok(results)
}

fn align_step(scan_type: ScanType) -> usize {
    match scan_type {
        ScanType::Int32 | ScanType::Float => 4,
        ScanType::Int64 | ScanType::Double => 8,
        ScanType::Utf8 | ScanType::Utf16 | ScanType::Aob => 1,
    }
}

fn matches_condition(
    cond: crate::scanner::ScanCondition,
    _scan_type: ScanType,
    current: &[u8],
    target: Option<&[u8]>,
) -> Result<bool, String> {
    use crate::scanner::ScanCondition::*;
    match cond {
        ExactValue => {
            let t = target.ok_or("Exact value required")?;
            Ok(current == t)
        }
        ChangedValue => Ok(target.map(|t| current != t).unwrap_or(true)),
        UnchangedValue => Ok(target.map(|t| current == t).unwrap_or(false)),
        IncreasedValue | DecreasedValue | BiggerThan | SmallerThan => {
            if current.len() < 4 {
                return Ok(false);
            }
            let a = i32::from_le_bytes(current[..4].try_into().unwrap());
            let b = target.and_then(|t| t.get(..4).map(|x| i32::from_le_bytes(x.try_into().unwrap())));
            let (inc, big, small) = match cond {
                IncreasedValue => (b.map(|b| a > b).unwrap_or(true), false, false),
                DecreasedValue => (b.map(|b| a < b).unwrap_or(true), false, false),
                BiggerThan => (false, b.map(|b| a > b).unwrap_or(false), false),
                SmallerThan => (false, false, b.map(|b| a < b).unwrap_or(false)),
                _ => (false, false, false),
            };
            Ok(inc || big || small)
        }
    }
}

/// Next scan: filter previous addresses by re-reading and re-checking condition.
/// prev_addresses: list of (address, previous_value_bytes) from first scan.
pub fn next_scan(
    pid: u32,
    params: &ScanParams,
    prev_addresses: &[(u64, Vec<u8>)],
) -> Result<Vec<ScanResultEntry>, String> {
    let size = prev_addresses
        .first()
        .map(|(_, b)| b.len())
        .unwrap_or(0);
    if size == 0 {
        return Ok(Vec::new());
    }

    let _value_bytes = params
        .value_str
        .as_deref()
        .map(|s| parse_value_for_type(s, params.scan_type))
        .transpose()?
        .or(params.aob_bytes.clone());

    let mut results = Vec::new();
    for (addr, prev_bytes) in prev_addresses {
        match memory::read_memory(pid, *addr, size) {
            Ok(current) => {
                if current.len() < size {
                    continue;
                }
                let slice = &current[..size];
                let prev = Some(prev_bytes.as_slice());
                if matches_condition(params.condition, params.scan_type, slice, prev)? {
                    results.push(ScanResultEntry {
                        address: *addr,
                        value_str: format_value(params.scan_type, slice),
                        raw_bytes: Some(slice.to_vec()),
                    });
                }
            }
            Err(_) => {}
        }
        if results.len() > 500_000 {
            break;
        }
    }
    Ok(results)
}
