import Flutter
import UIKit
import Firebase

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
// 1. Adicione o arquivo GoogleService-Info.plist baixado do Firebase Console na pasta Runner do seu projeto no Xcode.
// 2. No Xcode, vá em "Signing & Capabilities" e adicione a capability "Push Notifications".
// 3. Adicione também a capability "Background Modes" e marque "Background fetch" e "Remote notifications".
