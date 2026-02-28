// =============================================================================
// DX11 HOOK — PRESENT / ENDSCENE FOR OVERLAY
// =============================================================================
// Unity Mono (early 2010s) often uses DX11; we hook Present to draw ImGui
// on top. Educational skeleton only; no hardcoded offsets.
// =============================================================================

#pragma once

#include <d3d11.h>
#include <functional>
#include <windows.h>

namespace lab {

// Called every frame from hooked Present (or equivalent). Return true to continue chain.
using PresentCallback = std::function<bool(ID3D11Device*, ID3D11DeviceContext*, IDXGISwapChain*)>;

bool HookDX11Init();
void HookDX11Shutdown();
void HookDX11SetCallback(PresentCallback cb);

} // namespace lab
