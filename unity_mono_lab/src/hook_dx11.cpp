// =============================================================================
// DX11 HOOK — PRESENT FOR OVERLAY (Unity pattern)
// =============================================================================
// Hooks IDXGISwapChain::Present. Uses MinHook. Educational only.
// =============================================================================

#include "hook_dx11.hpp"
#include <d3d11.h>
#include <dxgi.h>
#include <MinHook.h>
#include <windows.h>
#include <atomic>

#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "dxgi.lib")

namespace lab {

namespace {
  using PresentFn = HRESULT(WINAPI*)(IDXGISwapChain*, UINT, UINT);
  PresentFn g_originalPresent = nullptr;
  std::atomic<bool> g_hookActive{ false };
  PresentCallback g_callback;

  IDXGISwapChain* g_swapChain = nullptr;
  ID3D11Device* g_device = nullptr;
  ID3D11DeviceContext* g_context = nullptr;
}

static HRESULT WINAPI HookedPresent(IDXGISwapChain* pSwapChain, UINT syncInterval, UINT flags) {
  if (!g_originalPresent) return E_FAIL;
  if (g_device && g_context && pSwapChain && g_callback) {
    g_swapChain = pSwapChain;
    g_device->GetImmediateContext(&g_context);
    if (g_context) {
      g_callback(g_device, g_context, pSwapChain);
      g_context->Release();
    }
  }
  return g_originalPresent(pSwapChain, syncInterval, flags);
}

// Create a dummy device/swap chain to get Present vtable (standard approach).
static bool GetPresentAddress(PresentFn* out) {
  WNDCLASSEXW wc = {};
  wc.cbSize = sizeof(wc);
  wc.lpfnWndProc = DefWindowProcW;
  wc.hInstance = GetModuleHandleW(nullptr);
  wc.lpszClassName = L"UnityMonoLabDummy";
  if (!RegisterClassExW(&wc)) return false;

  HWND hwnd = CreateWindowExW(0, wc.lpszClassName, L"", WS_OVERLAPPED, 0, 0, 1, 1, nullptr, nullptr, wc.hInstance, nullptr);
  if (!hwnd) return false;

  DXGI_SWAP_CHAIN_DESC scd = {};
  scd.BufferCount = 1;
  scd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
  scd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
  scd.OutputWindow = hwnd;
  scd.SampleDesc.Count = 1;
  scd.Windowed = TRUE;
  scd.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;

  IDXGISwapChain* pSwap = nullptr;
  ID3D11Device* pDev = nullptr;
  ID3D11DeviceContext* pCtx = nullptr;
  D3D_FEATURE_LEVEL level;
  HRESULT hr = D3D11CreateDeviceAndSwapChain(
    nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, 0, nullptr, 0,
    D3D11_SDK_VERSION, &scd, &pSwap, &pDev, &level, &pCtx);

  if (FAILED(hr) || !pSwap) {
    DestroyWindow(hwnd);
    UnregisterClassW(wc.lpszClassName, wc.hInstance);
    return false;
  }

  void** vtable = *reinterpret_cast<void***>(pSwap);
  *out = reinterpret_cast<PresentFn>(vtable[8]); // Present is at index 8 in IDXGISwapChainVtbl

  pCtx->Release();
  pDev->Release();
  pSwap->Release();
  DestroyWindow(hwnd);
  UnregisterClassW(wc.lpszClassName, wc.hInstance);
  return true;
}

bool HookDX11Init() {
  if (g_hookActive) return true;
  if (MH_Initialize() != MH_OK) return false;

  PresentFn presentAddr = nullptr;
  if (!GetPresentAddress(&presentAddr)) {
    MH_Uninitialize();
    return false;
  }

  if (MH_CreateHook(reinterpret_cast<LPVOID>(presentAddr), reinterpret_cast<LPVOID>(&HookedPresent), reinterpret_cast<void**>(&g_originalPresent)) != MH_OK) {
    MH_Uninitialize();
    return false;
  }
  if (MH_EnableHook(reinterpret_cast<LPVOID>(presentAddr)) != MH_OK) {
    MH_RemoveHook(reinterpret_cast<LPVOID>(presentAddr));
    MH_Uninitialize();
    return false;
  }
  g_hookActive = true;
  return true;
}

void HookDX11Shutdown() {
  if (!g_hookActive) return;
  if (g_originalPresent) {
    MH_DisableHook(MH_ALL_HOOKS);
    MH_RemoveHook(MH_ALL_HOOKS);
  }
  MH_Uninitialize();
  g_hookActive = false;
  g_originalPresent = nullptr;
  g_swapChain = nullptr;
  g_device = nullptr;
  g_context = nullptr;
}

void HookDX11SetCallback(PresentCallback cb) {
  g_callback = std::move(cb);
}

} // namespace lab
