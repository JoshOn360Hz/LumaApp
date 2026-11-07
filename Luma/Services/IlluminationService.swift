import Combine
import Foundation
import ServiceManagement

@MainActor
final class IlluminationService: ObservableObject {
    enum HelperStatus {
        case checking
        case setupRequired
        case approvalRequired
        case ready
        case repairRequired
        case unsupported
    }

    @Published private(set) var state: IlluminationState = .unknown
    @Published private(set) var helperStatus: HelperStatus = .checking
    @Published private(set) var isBusy = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var pendingEnabled: Bool?
    @Published private(set) var isLoginItemEnabled = LoginItemService.isEnabled
    @Published var errorMessage: String?

    private let connection = HelperConnection()
    private var refreshGeneration = 0
    private var confirmedState: IlluminationState = .unknown
    private var daemon: SMAppService { .daemon(plistName: LumaConstants.helperPlist) }
    private var legacyDaemon: SMAppService { .daemon(plistName: LumaConstants.legacyHelperPlist) }

    init() {
        DispatchQueue.main.async { [weak self] in self?.refresh() }
    }

    func refresh() {
        isLoginItemEnabled = LoginItemService.isEnabled
        guard !isBusy else { return }
        let canKeepConfirmedState = helperStatus == .ready && state != .unknown
        errorMessage = nil
        guard HardwareSupport.isSupported else {
            helperStatus = .unsupported
            state = .unknown
            isRefreshing = false
            return
        }
        refreshGeneration += 1
        let generation = refreshGeneration
        switch daemon.status {
        case .notRegistered:
            helperStatus = .setupRequired
            state = .unknown
            isRefreshing = false
            return
        case .requiresApproval:
            helperStatus = .approvalRequired
            state = .unknown
            isRefreshing = false
            return
        case .notFound:
            helperStatus = .repairRequired
            state = .unknown
            isRefreshing = false
            return
        case .enabled:
            isRefreshing = true
            if !canKeepConfirmedState {
                helperStatus = .checking
                state = .unknown
            }
        @unknown default:
            helperStatus = .repairRequired
            state = .unknown
            isRefreshing = false
            return
        }

        connection.version { [weak self] result in
            guard let self, self.refreshGeneration == generation else { return }
            switch result {
            case .success(let version) where version == LumaConstants.protocolVersion:
                self.connection.read { [weak self] result in
                    guard let self, self.refreshGeneration == generation else { return }
                    self.isRefreshing = false
                    switch result {
                    case .success(let (state, message)):
                        self.state = state
                        self.confirmedState = state
                        self.helperStatus = .ready
                        self.errorMessage = message
                    case .failure(let error):
                        self.state = .unknown
                        self.helperStatus = .repairRequired
                        self.errorMessage = error.localizedDescription
                    }
                }
            case .success:
                self.isRefreshing = false
                self.state = .unknown
                self.helperStatus = .repairRequired
                self.errorMessage = HelperError.incompatible.localizedDescription
            case .failure(let error):
                self.isRefreshing = false
                self.state = .unknown
                self.helperStatus = .repairRequired
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func installHelper() {
        guard HardwareSupport.isSupported, !isBusy else { return }
        isBusy = true
        errorMessage = nil
        do {
            if legacyDaemon.status == .enabled || legacyDaemon.status == .requiresApproval {
                try legacyDaemon.unregister()
            }
            if helperStatus == .repairRequired, daemon.status == .enabled {
                try daemon.unregister()
            }
            try daemon.register()
            isBusy = false
            refresh()
        } catch {
            isBusy = false
            refresh()
            if helperStatus == .setupRequired || helperStatus == .approvalRequired {
                errorMessage = "Luma couldn't register its helper. Check administrator approval."
            }
        }
    }

    func openApprovalSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    func setEnabled(_ enabled: Bool) {
        guard helperStatus == .ready, !isBusy, !isRefreshing else { return }
        isBusy = true
        pendingEnabled = enabled
        errorMessage = nil
        refreshGeneration += 1
        let previous = confirmedState
        connection.write(enabled) { [weak self] result in
            guard let self else { return }
            self.isBusy = false
            switch result {
            case .success(let state) where state == (enabled ? .on : .off):
                self.state = state
                self.confirmedState = state
            case .success:
                self.state = previous
                self.errorMessage = "Couldn't verify the new setting. Try again."
            case .failure(let error):
                self.state = previous
                self.errorMessage = error.localizedDescription
            }
            self.pendingEnabled = nil
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        errorMessage = nil
        do {
            try LoginItemService.setEnabled(enabled)
            isLoginItemEnabled = LoginItemService.isEnabled
            UserDefaults.standard.set(isLoginItemEnabled, forKey: "launchAtLogin")
        } catch {
            isLoginItemEnabled = LoginItemService.isEnabled
            errorMessage = "Couldn't update Launch at Login."
        }
    }

    func removeLumaServices() {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        do {
            if LoginItemService.isRegistered {
                try LoginItemService.setEnabled(false)
            }
            if daemon.status == .enabled || daemon.status == .requiresApproval {
                try daemon.unregister()
            }
            if legacyDaemon.status == .enabled || legacyDaemon.status == .requiresApproval {
                try legacyDaemon.unregister()
            }
            UserDefaults.standard.set(false, forKey: "launchAtLogin")
            isBusy = false
            refresh()
        } catch {
            isBusy = false
            refresh()
            errorMessage = "Couldn't remove Luma's background service. Try again."
        }
    }
}
