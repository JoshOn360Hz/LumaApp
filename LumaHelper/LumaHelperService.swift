import Foundation
import Darwin

final class LumaHelperService: NSObject, LumaHelperProtocol {
    func getProtocolVersion(withReply reply: @escaping (Int) -> Void) {
        reply(LumaConstants.protocolVersion)
    }

    func getIlluminationState(withReply reply: @escaping (Int, String?) -> Void) {
        guard geteuid() == 0 else {
            reply(IlluminationState.unknown.rawValue, "The Luma helper isn't running with administrator privileges.")
            return
        }
        guard HardwareSupport.isSupported else {
            reply(IlluminationState.unknown.rawValue, "This Mac doesn't support logo illumination control.")
            return
        }
        let (state, message) = PreferenceController.read()
        reply(state.rawValue, message)
    }

    func setIlluminationEnabled(_ enabled: Bool, withReply reply: @escaping (Int, String?) -> Void) {
        guard geteuid() == 0 else {
            reply(IlluminationState.unknown.rawValue, "The Luma helper isn't running with administrator privileges.")
            return
        }
        guard HardwareSupport.isSupported else {
            reply(IlluminationState.unknown.rawValue, "This Mac doesn't support logo illumination control.")
            return
        }
        let (state, message) = PreferenceController.setEnabled(enabled)
        reply(state.rawValue, message)
    }
}
