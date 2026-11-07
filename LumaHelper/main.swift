import Foundation

private final class HelperListenerDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        connection.exportedInterface = NSXPCInterface(with: LumaHelperProtocol.self)
        connection.exportedObject = LumaHelperService()
        connection.setCodeSigningRequirement(
            "anchor apple generic and certificate leaf[subject.OU] = \"\(LumaConstants.teamID)\" and identifier \"\(LumaConstants.appBundleIdentifier)\""
        )
        connection.resume()
        return true
    }
}

let listener = NSXPCListener(machServiceName: LumaConstants.helperLabel)
private let delegate = HelperListenerDelegate()
listener.delegate = delegate
listener.resume()
RunLoop.main.run()
