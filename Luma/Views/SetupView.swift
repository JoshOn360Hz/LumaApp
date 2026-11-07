import SwiftUI

struct SetupView: View {
    @ObservedObject var service: IlluminationService

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbolName)
                .font(.callout.weight(.semibold))
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(actionTitle) {
                if service.helperStatus == .approvalRequired {
                    service.openApprovalSettings()
                } else {
                    service.installHelper()
                }
            }
            .disabled(service.isBusy)
            .padding(.top, 4)
        }
    }

    private var title: String {
        switch service.helperStatus {
        case .setupRequired: "Finish Setup"
        case .approvalRequired: "Approval Needed"
        default: "Luma Needs Repair"
        }
    }

    private var detail: String {
        switch service.helperStatus {
        case .setupRequired: "Allow Luma to control your illuminated logo. macOS will ask for administrator approval."
        case .approvalRequired: "Allow Luma in System Settings, then reopen this menu."
        default: "Reconnect Luma to restore illumination control."
        }
    }

    private var actionTitle: String {
        switch service.helperStatus {
        case .setupRequired: "Enable Luma"
        case .approvalRequired: "Open System Settings"
        default: "Repair Luma"
        }
    }

    private var symbolName: String {
        switch service.helperStatus {
        case .setupRequired, .approvalRequired: "lock.shield"
        default: "arrow.clockwise.circle"
        }
    }
}
