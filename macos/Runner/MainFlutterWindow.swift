import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Set localized window title based on system language
    // To add more languages, add additional if/else-if conditions
    let preferredLanguage = Locale.preferredLanguages.first ?? "en"
    if preferredLanguage.hasPrefix("zh") {
      // Simplified Chinese
      self.title = "九宫计时"
    } else if preferredLanguage.hasPrefix("ja") {
      // Japanese (example for future expansion)
      // self.title = "グリッドタイマー"
      self.title = "Grid Timer"
    } else if preferredLanguage.hasPrefix("ko") {
      // Korean (example for future expansion)
      // self.title = "그리드 타이머"
      self.title = "Grid Timer"
    } else if preferredLanguage.hasPrefix("es") {
      // Spanish (example for future expansion)
      // self.title = "Temporizador de Cuadrícula"
      self.title = "Grid Timer"
    } else {
      // Default to English
      self.title = "Grid Timer"
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
