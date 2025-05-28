import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    if let mainMenu = NSApp.mainMenu {
      // APP_NAME 메뉴 (보통 첫 번째 메뉴의 하위 메뉴)
      if let appMenu = mainMenu.item(at: 0)?.submenu {
        // Tag로 Preferences 메뉴 아이템 찾기
        if let preferencesItem = appMenu.item(withTag: 1001) { // 여기서 1001은 Xcode에서 설정한 Tag 값
          preferencesItem.target = self
          preferencesItem.action = #selector(showPreferences(_:))
          print("Preferences item programmatically targeted.")
        } else {
          print("Preferences item with tag 1001 not found.")
        }
      }
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  @objc public func showPreferences(_ sender: NSMenuItem) {
    NSLog("NSLog: Preferences menu item clicked!")

    // FlutterViewController 가져오기
    // mainFlutterWindow는 FlutterAppDelegate의 프로퍼티로 접근하거나, 직접 NSApp.windows를 통해 찾아야 할 수 있습니다.
    // 여기서는 mainFlutterWindow가 AppDelegate의 프로퍼티로 유효하다고 가정합니다.
    guard let flutterViewController = mainFlutterWindow?.contentViewController as? FlutterViewController else {
        NSLog("Error: Could not get FlutterViewController.")
        return
    }

    let channelName = "com.hamilcar1026.polishlearningapp/settings"
    let methodChannel = FlutterMethodChannel(name: channelName,
                                             binaryMessenger: flutterViewController.engine.binaryMessenger)

    methodChannel.invokeMethod("showSettingsPage", arguments: nil) { (result: Any?) in
        if result is FlutterError {
            NSLog("Error invoking showSettingsPage method from Swift.") // 단순한 로그로 대체
        } else {
            NSLog("showSettingsPage method invoked successfully.")
        }
    }
    
    // 만약 기본 Flutter Window를 앞으로 가져오고 싶다면:
    if let window = mainFlutterWindow {
      window.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
    }
  }

  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    if menuItem.action == #selector(showPreferences(_:)) {
      // NSLog("Validating menu item for showPreferences: %@", String(describing: menuItem.title)) // NSLog 잠시 주석 처리
      return true // Preferences 메뉴 항목은 항상 활성화
    }
    
    // 다른 메뉴 항목
    // NSLog("Validating other menu item: %@, isEnabled: %d", String(describing: menuItem.title), menuItem.isEnabled)
    return menuItem.isEnabled
  }
}
