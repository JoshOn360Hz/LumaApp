import CoreFoundation
import Foundation

enum PreferenceController {
    private static var domain: CFString { "com.apple.CoreBrightness" as CFString }
    private static var key: CFString { "LEBacklightMode" as CFString }
    private static let queue = DispatchQueue(label: "com.josh.luma.preferences")

    static func read() -> (IlluminationState, String?) {
        queue.sync { readUnlocked() }
    }

    private static func readUnlocked() -> (IlluminationState, String?) {
        // The daemon runs as root, matching Apple's documented sudo defaults
        // commands. A missing override means the system's default behaviour.
        guard CFPreferencesSynchronize(domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost) else {
            return (.unknown, "Couldn't read the illumination setting.")
        }
        guard let value = CFPreferencesCopyValue(
            key, domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost
        ) else {
            return (.on, nil)
        }
        if CFGetTypeID(value) == CFNumberGetTypeID(),
           let number = value as? NSNumber,
           !CFNumberIsFloatType(number),
           number.intValue == 0 {
            return (.off, nil)
        }
        return (.unknown, "The illumination setting has an unexpected value.")
    }

    static func setEnabled(_ enabled: Bool) -> (IlluminationState, String?) {
        queue.sync {
            CFPreferencesSetValue(
                key,
                enabled ? nil : (0 as CFNumber),
                domain,
                kCFPreferencesCurrentUser,
                kCFPreferencesAnyHost
            )
            guard CFPreferencesSynchronize(domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost) else {
                return (.unknown, "Couldn't change illumination. Try again.")
            }
            let result = readUnlocked()
            let expected: IlluminationState = enabled ? .on : .off
            guard result.0 == expected else {
                return (.unknown, "Couldn't verify the illumination setting.")
            }
            return result
        }
    }
}
