import Foundation

enum IlluminationState: Int, Sendable {
    case unknown = -1
    case off = 0
    case on = 1

    var subtitle: String {
        switch self {
        case .on: "On"
        case .off: "Off"
        case .unknown: "Unknown"
        }
    }
}

enum LumaConstants {
    static let appBundleIdentifier = "com.josh.luma"
    static let helperLabel = "com.josh.luma.helper"
    static let helperPlist = "com.josh.luma.helper.plist"
    static let legacyHelperPlist = "com.joshmansfield.luma.helper.plist"
    static let protocolVersion = 1
    static let teamID = "VCZ6LUVE4J"

    // These are the four PROLED XDR MacBook Pro identifiers. Keep this allowlist
    // in both processes so a daemon request cannot bypass the app's UI gate.
    static let supportedModels: Set<String> = [
        "Mac17,10", "Mac17,11", "Mac17,12", "Mac17,13"
    ]
}

@objc protocol LumaHelperProtocol {
    func getProtocolVersion(withReply reply: @escaping (Int) -> Void)
    func getIlluminationState(withReply reply: @escaping (Int, String?) -> Void)
    func setIlluminationEnabled(_ enabled: Bool, withReply reply: @escaping (Int, String?) -> Void)
}
