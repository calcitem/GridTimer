import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Set localized window title based on system language
    let preferredLanguage = Locale.preferredLanguages.first ?? "en"
    if preferredLanguage.hasPrefix("zh") {
      self.title = "九宫格计时器"
    } else {
      self.title = "GridTimer"
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
