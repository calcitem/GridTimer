#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

// Get localized window title based on system language.
// To add more languages:
// 1. Add the language constant (e.g., LANG_JAPANESE)
// 2. Add the corresponding if condition with localized title
// 3. Use Unicode escape sequences (e.g., L"\xXXXX") for non-ASCII characters
const wchar_t* GetLocalizedWindowTitle() {
  LANGID langId = GetUserDefaultUILanguage();
  WORD primaryLangId = PRIMARYLANGID(langId);

  if (primaryLangId == LANG_CHINESE) {
    // Simplified Chinese: 九宫计时
    return L"\x4E5D\x5BAB\x683C\x8BA1\x65F6\x5668";
  }
  // Add more languages here as needed:
  // if (primaryLangId == LANG_JAPANESE) {
  //   return L"\x30B0\x30EA\x30C3\x30C9\x30BF\x30A4\x30DE\x30FC"; // グリッドタイマー
  // }
  // if (primaryLangId == LANG_KOREAN) {
  //   return L"\xADF8\xB9AC\xB4DC \xD0C0\xC774\xBA38"; // 그리드 타이머
  // }
  // if (primaryLangId == LANG_SPANISH) {
  //   return L"Temporizador de Cuadrícula";
  // }

  // Default to English
  return L"Grid Timer";
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(GetLocalizedWindowTitle(), origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);
  // Enable minimize to system tray on close.
  window.SetMinimizeToTray(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
