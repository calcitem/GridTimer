#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

// Get localized window title based on system language.
const wchar_t* GetLocalizedWindowTitle() {
  LANGID langId = GetUserDefaultUILanguage();
  WORD primaryLangId = PRIMARYLANGID(langId);

  if (primaryLangId == LANG_CHINESE) {
    // Chinese: U+4E5D U+5BAB U+683C U+8BA1 U+65F6 U+5668 = "九宫计时"
    return L"\x4E5D\x5BAB\x683C\x8BA1\x65F6\x5668";
  }
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
