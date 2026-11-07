import AppKit
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var service: IlluminationService
    @State private var showingRemovalConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 11) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 30, height: 30)

                Text("Luma")
                    .font(.headline)
                Spacer(minLength: 0)
            }

            Divider().padding(.vertical, 15)

            switch service.helperStatus {
            case .unsupported:
                Label("This Mac doesn't support logo illumination control.", systemImage: "info.circle")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            case .ready:
                HStack(spacing: 10) {
                    Image(systemName: displayedEnabled ? "sun.max.fill" : "sun.max")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(displayedEnabled ? Color.accentColor : Color(nsColor: .secondaryLabelColor))
                        .frame(width: 30, height: 30)
                        .background(displayedEnabled ? Color.accentColor.opacity(0.09) : Color(nsColor: .secondaryLabelColor).opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Logo Illumination")
                            .font(.callout.weight(.medium))
                        Text(service.isBusy ? "Updating…" : service.state.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 12)
                    Toggle("Logo Illumination", isOn: Binding(
                        get: { displayedEnabled },
                        set: { service.setEnabled($0) }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .disabled(service.isBusy || service.isRefreshing || service.state == .unknown)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if service.state == .unknown {
                    Text("The configured state couldn't be determined.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 9)
                }
            case .checking:
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Checking illumination…")
                        .foregroundStyle(.secondary)
                }
                .font(.callout)
            case .setupRequired, .approvalRequired, .repairRequired:
                SetupView(service: service)
            }

            if let errorMessage = service.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
            }

            Divider().padding(.vertical, 15)

            Toggle("Launch at Login", isOn: Binding(
                get: { service.isLoginItemEnabled },
                set: { service.setLaunchAtLogin($0) }
            ))
            .toggleStyle(.checkbox)
            .controlSize(.small)
            .font(.callout)

            HStack(spacing: 8) {
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Quit Luma").frame(maxWidth: .infinity)
                }
                Button(role: .destructive) {
                    showingRemovalConfirmation = true
                } label: {
                    Text("Remove Luma…").frame(maxWidth: .infinity)
                }
                .disabled(service.isBusy)
            }
            .font(.callout)
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .padding(.top, 14)
        }
        .padding(16)
        .frame(width: 300, alignment: .leading)
        .task { service.refresh() }
        .confirmationDialog(
            "Remove Luma's background service?",
            isPresented: $showingRemovalConfirmation
        ) {
            Button("Remove Luma", role: .destructive) { service.removeLumaServices() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This turns off Launch at Login and unregisters the helper. Your current logo setting stays as it is. You can then move Luma to Trash.")
        }
    }

    private var displayedEnabled: Bool {
        service.pendingEnabled ?? (service.state == .on)
    }
}
