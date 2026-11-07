import Darwin

enum HardwareSupport {
    static var modelIdentifier: String? {
        var size = 0
        guard sysctlbyname("hw.model", nil, &size, nil, 0) == 0, size > 1 else {
            return nil
        }
        var bytes = [CChar](repeating: 0, count: size)
        guard sysctlbyname("hw.model", &bytes, &size, nil, 0) == 0 else {
            return nil
        }
        return String(decoding: bytes.prefix(while: { $0 != 0 }).map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }

    static var isSupported: Bool {
        guard let modelIdentifier else { return false }
        return LumaConstants.supportedModels.contains(modelIdentifier)
    }
}
