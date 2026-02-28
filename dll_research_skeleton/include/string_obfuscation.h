// =============================================================================
// SIMPLE STRING OBFUSCATION (EDUCATIONAL)
// =============================================================================
// Minimal compile-time or runtime string masking to avoid plain-text
// literals in binary. Not intended as real protection; for study only.
// =============================================================================

#pragma once

#include <string>
#include <array>
#include <cstddef>

namespace research {
namespace obfuscation {

// XOR with a single byte key (compile-time for const strings).
template <std::size_t N>
constexpr std::array<char, N> XorEncrypt(const char (&data)[N], unsigned char key) {
  std::array<char, N> out{};
  for (std::size_t i = 0; i < N - 1; ++i)  // exclude null
    out[i] = static_cast<char>(static_cast<unsigned char>(data[i]) ^ key);
  out[N - 1] = '\0';
  return out;
}

// Runtime decrypt from a buffer (e.g. from XorEncrypt).
inline std::string XorDecrypt(const char* data, std::size_t len, unsigned char key) {
  std::string out;
  out.reserve(len);
  for (std::size_t i = 0; i < len && data[i]; ++i)
    out += static_cast<char>(static_cast<unsigned char>(data[i]) ^ key);
  return out;
}

}  // namespace obfuscation
}  // namespace research
