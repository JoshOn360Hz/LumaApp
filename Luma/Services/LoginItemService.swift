import ServiceManagement

enum LoginItemService {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }
    static var isRegistered: Bool {
        SMAppService.mainApp.status == .enabled || SMAppService.mainApp.status == .requiresApproval
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
