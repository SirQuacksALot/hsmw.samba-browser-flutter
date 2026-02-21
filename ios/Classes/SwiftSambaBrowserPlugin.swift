import Flutter
import UIKit
import AMSMB2

public class SwiftSambaBrowserPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "samba_browser", binaryMessenger: registrar.messenger())
        let instance = SwiftSambaBrowserPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "invalid_arguments", message: "Arguments are missing or invalid", details: nil))
            return
        }
        
        switch call.method {
        case "getShareList":
            getShareList(args: args, flutterResult: result)
        case "saveFile":
            saveFile(args: args, flutterResult: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func buildClient(from urlString: String, user: String, password: String) -> (client: SMBClient, share: String) {
        let parts = urlString.split(separator: "/")
        let baseURL = "smb://" + Array(parts)[1..<3].joined(separator: "/")
        let share = String(baseURL.split(separator: "/").last!)
        return (SMBClient(url: baseURL, share: share, user: user, password: password), share)
    }
    
    private func getShareList(args: [String: Any], flutterResult: @escaping FlutterResult) {
        guard
            let urlString = args["url"] as? String,
            let user = args["username"] as? String,
            let password = args["password"] as? String
        else {
            flutterResult(FlutterError(code: "invalid_arguments", message: "Missing required arguments", details: nil))
            return
        }
        
        let parts = urlString.split(separator: "/")
        let baseURL = "smb://" + Array(parts)[1..<3].joined(separator: "/")
        let share = String(baseURL.split(separator: "/").last!)
        let path = urlString.components(separatedBy: "/").dropFirst(4).joined(separator: "/")
        
        Task {
            do {
                let files = try await SMBClient(url: baseURL, share: share, user: user, password: password)
                    .listDirectory(path: path)
                flutterResult(files)
            } catch {
                flutterResult(FlutterError(code: "error", message: error.localizedDescription, details: nil))
            }
        }
    }
    
    private func saveFile(args: [String: Any], flutterResult: @escaping FlutterResult) {
        guard
            let urlString = args["url"] as? String,
            let saveFolder = args["saveFolder"] as? String,
            let fileName = args["fileName"] as? String,
            let user = args["username"] as? String,
            let password = args["password"] as? String
        else {
            flutterResult(FlutterError(code: "invalid_arguments", message: "Missing required arguments", details: nil))
            return
        }
        
        let parts = urlString.split(separator: "/")
        let baseURL = "smb://" + Array(parts)[1..<3].joined(separator: "/")
        let share = String(baseURL.split(separator: "/").last!)
        let atPath = String(urlString.replacingOccurrences(of: baseURL, with: "").dropFirst())
        
        Task {
            do {
                let path = try await SMBClient(url: baseURL, share: share, user: user, password: password)
                    .downloadFile(atPath: atPath, to: saveFolder + fileName)
                flutterResult(path)
            } catch {
                flutterResult(FlutterError(code: "error", message: error.localizedDescription, details: nil))
            }
        }
    }
}
