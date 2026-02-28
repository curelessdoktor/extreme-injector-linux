// =============================================================================
// STRING ENCRYPTION — EDUCATIONAL USE ONLY
// =============================================================================
// All user-facing and diagnostic literals should go through this to avoid
// plain-text signatures in the binary. XOR with a key; not real protection.
// =============================================================================

#pragma once

#include <string>
#include <array>
#include <cstddef>

namespace lab {

template <std::size_t N>
constexpr std::array<char, N> EncryptLiteral(const char (&data)[N], unsigned char key) {
  std::array<char, N> out{};
  for (std::size_t i = 0; i < N - 1; ++i)
    out[i] = static_cast<char>(static_cast<unsigned char>(data[i]) ^ key);
  out[N - 1] = '\0';
  return out;
}

inline std::string Decrypt(const char* data, std::size_t len, unsigned char key) {
  std::string out;
  out.reserve(len);
  for (std::size_t i = 0; i < len && data[i]; ++i)
    out += static_cast<char>(static_cast<unsigned char>(data[i]) ^ key);
  return out;
}

} // namespace lab
