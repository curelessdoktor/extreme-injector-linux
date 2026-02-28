// =============================================================================
// INJECTION STUB — DOCUMENTATION AND PLACEHOLDER ONLY
// =============================================================================
// We do NOT implement remote injection (manual map, APC, etc.) in this
// project. This file exists to:
// 1) Document pros/cons of different entry points (see injection_docs.h).
// 2) Provide a single placeholder that could be replaced by an external
//    loader (e.g. a test executable that uses CreateRemoteThread + LoadLibrary
//    for local, authorized testing only).
//
// Any actual injection into a target process must be done by the researcher
// in a controlled, authorized environment — not by this DLL.
// =============================================================================

#include "injection_docs.h"

namespace research {
namespace injection {

// Placeholder: "which method was documented for this build."
// In a full research harness you might pass this from the loader.
DocumentedMethod GetDocumentedMethod() {
  return DocumentedMethod::kNone;
}

}  // namespace injection
}  // namespace research
