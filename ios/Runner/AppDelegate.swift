import UIKit
import Flutter
import AVFoundation
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private var sosPlayer: AVAudioPlayer?
  private var sosStopTimer: Timer?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      FlutterMethodChannel(name: "residence/alarms", binaryMessenger: controller.binaryMessenger).setMethodCallHandler { [weak self] call, result in
        do {
          switch call.method {
          case "start":
            guard let bytes = call.arguments as? FlutterStandardTypedData else { result(FlutterError(code: "AUDIO", message: "Missing alarm audio", details: nil)); return }
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            self?.sosPlayer = try AVAudioPlayer(data: bytes.data)
            self?.sosPlayer?.numberOfLoops = -1
            self?.sosPlayer?.play()
            self?.sosStopTimer?.invalidate()
            self?.sosStopTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { [weak self] _ in
              self?.sosPlayer?.stop()
              self?.sosPlayer = nil
              try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            }
          case "stop":
            self?.sosStopTimer?.invalidate()
            self?.sosPlayer?.stop()
            self?.sosPlayer = nil
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
          case "badge":
            application.applicationIconBadgeNumber = call.arguments as? Int ?? 0
          case "initialize": break
          default: result(FlutterMethodNotImplemented); return
          }
          result(nil)
        } catch { result(FlutterError(code: "AUDIO", message: "Unable to play alarm", details: nil)) }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    super.userNotificationCenter(center, willPresent: notification) { options in
      let kind = notification.request.content.userInfo["type"] as? String
      completionHandler(kind == "sos_live" ? options.subtracting(.sound) : options)
    }
  }

}
