import SwiftUI

struct DeviceInfoView: View {
    let device: Device

    @State private var showRebootConfirm = false
    @State private var rebootStatus: RebootStatus = .idle

    enum RebootStatus {
        case idle, loading, success, failure(String)
    }

    var body: some View {
        List {
            // ── Information ──────────────────────────────────────
            Section {
                // Status badge + name hero row
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(device.isOffline ? Color.red.opacity(0.12) : Color.green.opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: device.isOffline ? "desktopcomputer.slash" : "desktopcomputer")
                            .font(.system(size: 36))
                            .foregroundStyle(device.isOffline ? .red : .green)
                    }

                    Text(device.deviceName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(device.isOffline ? "OFFLINE" : "ONLINE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(device.isOffline ? Color.red : Color.green)
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } header: {
                Text("Information")
            }

            Section {
                InfoRow(icon: "barcode", label: "Serial Number", value: device.deviceSn)
                InfoRow(icon: "tag", label: "Device Code",
                        value: device.deviceCode.isEmpty ? "—" : device.deviceCode)
                InfoRow(icon: "mappin.and.ellipse", label: "Location",
                        value: device.deviceLocation.flatMap { $0.isEmpty ? nil : $0 } ?? "—")
                InfoRow(icon: "clock", label: "Last Active",
                        value: device.formattedLastActive,
                        valueColor: device.isOffline ? .red : .primary)
                InfoRow(icon: "app.badge", label: "App Version", value: "—")
                InfoRow(icon: "person.2", label: "Employee Count", value: "—")
                InfoRow(icon: "calendar.badge.clock", label: "Attendance Count", value: "—")
            }

            // ── Operations ───────────────────────────────────────
            Section(header: Text("Operations")) {
                Button {
                    showRebootConfirm = true
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange)
                                .frame(width: 34, height: 34)
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(.white)
                                .fontWeight(.semibold)
                        }
                        Text("Reboot")
                            .foregroundStyle(.primary)
                            .fontWeight(.medium)
                        Spacer()
                        switch rebootStatus {
                        case .loading:
                            ProgressView().tint(.orange)
                        case .success:
                            Label("Sent", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        case .failure(let msg):
                            Text(msg)
                                .foregroundStyle(.red)
                                .font(.caption)
                        case .idle:
                            EmptyView()
                        }
                    }
                }
                .disabled(rebootStatus == .loading)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Device Info")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Reboot \(device.deviceName)?",
            isPresented: $showRebootConfirm,
            titleVisibility: .visible
        ) {
            Button("Reboot", role: .destructive) {
                Task { await sendReboot() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will restart the device remotely. It may go offline briefly.")
        }
    }

    private func sendReboot() async {
        rebootStatus = .loading
        // TODO: replace with real reboot API endpoint when available
        // e.g. POST /iclock/api_v1/devices/{sn}/reboot
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        rebootStatus = .failure("API not available")
    }
}

// ── Reusable info row ────────────────────────────────────────────
private struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.secondary)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(value == "—" ? Color.secondary : valueColor)
                .multilineTextAlignment(.trailing)
        }
    }
}

// Make RebootStatus equatable for .disabled check
extension DeviceInfoView.RebootStatus: Equatable {
    static func == (lhs: DeviceInfoView.RebootStatus, rhs: DeviceInfoView.RebootStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.success, .success): return true
        case (.failure(let a), .failure(let b)): return a == b
        default: return false
        }
    }
}

#Preview {
    NavigationStack {
        DeviceInfoView(device: Device(
            deviceSn: "CKF8232360137",
            deviceCode: "CKF01",
            deviceName: "Los Banos Branch",
            deviceLocation: "Los Banos Branch",
            lastActiveTime: "2026-03-16T10:00:27.692-07:00"
        ))
    }
}
