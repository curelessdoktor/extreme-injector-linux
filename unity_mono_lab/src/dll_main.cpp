// =============================================================================
// DLL ENTRY — MANUAL MAPPING FRIENDLY, BACKGROUND THREAD INIT
// =============================================================================

#include "common.hpp"
#include "hook_dx11.hpp"
#include "overlay_menu.hpp"
#include "mono_bridge.hpp"
#include "memory_patches.hpp"
#include "module_enum.hpp"
#include "imgui.h"
#include "imgui_impl_win32.h"
#include "imgui_impl_dx11.h"
#include <windows.h>
#include <d3d11.h>
#include <atomic>
#include <thread>

extern IMGUI_IMPL_API LRESULT ImGui_ImplWin32_WndProcHandler(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

namespace {

std::atomic<bool> g_running{ true };
std::thread g_initThread;
lab::ModState g_modState;
lab::OverlayMenu g_menu;

constexpr uintptr_t kPlayerHealthOffset = 0x0;
constexpr uintptr_t kMovementSpeedOffset = 0x0;
constexpr uintptr_t kNoclipFlagOffset = 0x0;

ID3D11Device* g_pd3dDevice = nullptr;
ID3D11DeviceContext* g_pd3dDeviceContext = nullptr;
ID3D11RenderTargetView* g_mainRenderTargetView = nullptr;
bool g_imguiInitialized = false;
WNDPROC g_originalWndProc = nullptr;
HWND g_hwnd = nullptr;

LRESULT CALLBACK HookWndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam) {
  if (ImGui_ImplWin32_WndProcHandler(hWnd, msg, wParam, lParam))
    return 0;
  return g_originalWndProc ? CallWindowProcW(g_originalWndProc, hWnd, msg, wParam, lParam) : DefWindowProcW(hWnd, msg, wParam, lParam);
}

void CreateRenderTarget(IDXGISwapChain* pSwapChain) {
  ID3D11Texture2D* pBackBuffer = nullptr;
  pSwapChain->GetBuffer(0, IID_PPV_ARGS(&pBackBuffer));
  if (!pBackBuffer) return;
  g_pd3dDevice->CreateRenderTargetView(pBackBuffer, nullptr, &g_mainRenderTargetView);
  pBackBuffer->Release();
}

void CleanupRenderTarget() {
  if (g_mainRenderTargetView) {
    g_mainRenderTargetView->Release();
    g_mainRenderTargetView = nullptr;
  }
}

bool PresentCallbackImpl(ID3D11Device* pDevice, ID3D11DeviceContext* pContext, IDXGISwapChain* pSwapChain) {
  if (!pDevice || !pContext || !pSwapChain) return true;

  if (!g_imguiInitialized) {
    g_pd3dDevice = pDevice;
    g_pd3dDeviceContext = pContext;
    pDevice->AddRef();
    pContext->AddRef();
    CreateRenderTarget(pSwapChain);

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO();
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;

    DXGI_SWAP_CHAIN_DESC scd;
    pSwapChain->GetDesc(&scd);
    g_hwnd = scd.OutputWindow;
    g_originalWndProc = (WNDPROC)SetWindowLongPtrW(g_hwnd, GWLP_WNDPROC, (LONG_PTR)HookWndProc);
    ImGui_ImplWin32_Init(scd.OutputWindow);
    ImGui_ImplDX11_Init(pDevice, pContext);
    ImGui::StyleColorsDark();
    g_imguiInitialized = true;
  }

  ImGui_ImplDX11_NewFrame();
  ImGui_ImplWin32_NewFrame();
  ImGui::NewFrame();

  g_menu.SetModState(&g_modState);
  g_menu.SetExecutor([](const std::string& snippet) {
    auto res = lab::MonoBridge_Eval(snippet);
    return std::make_pair(res.success, res.success ? res.output : res.error);
  });
  g_menu.Frame();

  ImGui::Render();
  pContext->OMSetRenderTargets(1, &g_mainRenderTargetView, nullptr);
  ImGui_ImplDX11_RenderDrawData(ImGui::GetDrawData());

  return true;
}

void ApplyModState() {
  lab::ModuleInfo info;
  if (lab::ModuleEnum_FindByName("mono", &info))
    lab::MemoryPatches_SetBase(info.base);
  lab::MemoryPatches_ApplyGodMode(g_modState.god_mode, kPlayerHealthOffset, 9999);
  lab::MemoryPatches_ApplySpeedHack(g_modState.speed_hack, g_modState.speed_mult, kMovementSpeedOffset);
  lab::MemoryPatches_ApplyNoClip(g_modState.no_clip, kNoclipFlagOffset);
  lab::MemoryPatches_ApplyESP(g_modState.esp_toggle);
}

void InitThread(HMODULE hModule) {
  (void)hModule;
  while (g_running && !lab::HookDX11Init()) {
    Sleep(500);
  }
  if (!g_running) return;
  lab::HookDX11SetCallback(PresentCallbackImpl);

  while (g_running) {
    ApplyModState();
    Sleep(100);
  }
}

void ShutdownImGui() {
  if (!g_imguiInitialized) return;
  if (g_hwnd && g_originalWndProc) {
    SetWindowLongPtrW(g_hwnd, GWLP_WNDPROC, (LONG_PTR)g_originalWndProc);
    g_originalWndProc = nullptr;
    g_hwnd = nullptr;
  }
  ImGui_ImplDX11_Shutdown();
  ImGui_ImplWin32_Shutdown();
  ImGui::DestroyContext();
  CleanupRenderTarget();
  if (g_pd3dDeviceContext) { g_pd3dDeviceContext->Release(); g_pd3dDeviceContext = nullptr; }
  if (g_pd3dDevice) { g_pd3dDevice->Release(); g_pd3dDevice = nullptr; }
  g_imguiInitialized = false;
}

} // namespace

BOOL APIENTRY DllMain(HMODULE hModule, DWORD reason, LPVOID /*reserved*/) {
  switch (reason) {
    case DLL_PROCESS_ATTACH:
      DisableThreadLibraryCalls(hModule);
      g_running = true;
      g_initThread = std::thread(InitThread, hModule);
      break;
    case DLL_PROCESS_DETACH:
      g_running = false;
      if (g_initThread.joinable())
        g_initThread.join();
      ShutdownImGui();
      lab::HookDX11Shutdown();
      break;
    case DLL_THREAD_ATTACH:
    case DLL_THREAD_DETACH:
      break;
  }
  return TRUE;
}
