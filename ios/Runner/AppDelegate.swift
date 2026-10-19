import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let workOs = WorkOsSignIn()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "br.com.implateflow/workos",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "signIn":
        guard let args = call.arguments as? [String: String],
          let clientId = args["clientId"],
          let redirectUri = args["redirectUri"],
          !clientId.isEmpty,
          !redirectUri.isEmpty
        else {
          result(FlutterError(code: "config", message: "O login do WorkOS não está configurado.", details: nil))
          return
        }
        self?.workOs.signIn(clientID: clientId, redirectURI: redirectUri, result: result)
      case "currentIdentity":
        guard let args = call.arguments as? [String: String],
          let clientId = args["clientId"],
          !clientId.isEmpty
        else {
          result(nil)
          return
        }
        self?.workOs.currentIdentity(clientID: clientId, result: result)
      case "signOut":
        let returnTo = (call.arguments as? [String: String])?["redirectUri"]
          ?? "br.com.implateflow://auth/callback"
        self?.workOs.signOut(returnTo: returnTo, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
