import SwiftUI

struct Device: Identifiable, Decodable {
    let deviceSn: String
    let deviceCode: String
    let deviceName: String
    let deviceLocation: String?
    let lastActiveTime: String?

    var id: String { deviceSn }

    private var lastActiveDate: Date? {
        guard let raw = lastActiveTime else { return nil }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return isoFormatter.date(from: raw)
    }

    var isOffline: Bool {
        guard let date = lastActiveDate else { return true }
        return Date().timeIntervalSince(date) > 86_400  // 24 hours in seconds
    }

    var formattedLastActive: String {
        guard let date = lastActiveDate else { return "Never" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct DeviceAPIResponse: Decodable {
    let totalSize: Int
    let pageNumber: Int
    let pageSize: Int
    let data: [Device]
}

@MainActor
class DeviceViewModel: ObservableObject {
    @Published var devices: [Device] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastStatusCode: Int?
    @Published var currentPage = 1
    @Published var totalSize = 0

    let pageSize = 10
    var totalPages: Int { max(1, Int(ceil(Double(totalSize) / Double(pageSize)))) }

    private let baseURL = "https://zkcirrus-1.workdayclocks.com/iclock/api_v1/devices/client-code"

    func fetchPage(_ page: Int, clientCode: String) async {
        isLoading = true
        errorMessage = nil

        do {
            guard let url = URL(string: "\(baseURL)/\(clientCode)?pageNum=\(page)&pageSize=\(pageSize)") else {
                throw URLError(.badURL)
            }
            let (data, response) = try await URLSession.shared.data(from: url)
            lastStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let decoded = try JSONDecoder().decode(DeviceAPIResponse.self, from: data)
            devices = decoded.data
            totalSize = decoded.totalSize
            currentPage = page
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

struct DeviceListView: View {
    let client: Client
    @StateObject private var viewModel = DeviceViewModel()

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading devices...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.red)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        Button("Retry") {
                            Task { await viewModel.fetchPage(viewModel.currentPage, clientCode: client.clientCode) }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.devices.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "desktopcomputer.slash")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No devices found for \(client.clientName).")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.devices) { device in
                        NavigationLink(destination: DeviceInfoView(device: device)) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .center, spacing: 8) {
                                    Text(device.deviceName)
                                        .font(.headline)
                                    if device.isOffline {
                                        Text("OFFLINE")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Color.red)
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }
                                }
                                HStack(spacing: 12) {
                                    Label(device.deviceSn, systemImage: "barcode")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                if let location = device.deviceLocation, !location.isEmpty {
                                    Label(location, systemImage: "mappin.and.ellipse")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Label("Last active: \(device.formattedLastActive)", systemImage: "clock")
                                    .font(.caption)
                                    .foregroundStyle(device.isOffline ? AnyShapeStyle(.red) : AnyShapeStyle(.tertiary))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }

            Divider()

            // Pagination controls
            HStack(spacing: 20) {
                Button(action: {
                    Task { await viewModel.fetchPage(viewModel.currentPage - 1, clientCode: client.clientCode) }
                }) {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                }
                .disabled(viewModel.currentPage <= 1 || viewModel.isLoading)

                Spacer()

                VStack(spacing: 2) {
                    Text("Page \(viewModel.currentPage) of \(viewModel.totalPages)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("\(viewModel.totalSize) total devices")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: {
                    Task { await viewModel.fetchPage(viewModel.currentPage + 1, clientCode: client.clientCode) }
                }) {
                    Image(systemName: "chevron.right")
                        .fontWeight(.semibold)
                }
                .disabled(viewModel.currentPage >= viewModel.totalPages || viewModel.isLoading)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.bar)

            // HTTP status bar
            if let code = viewModel.lastStatusCode {
                HStack(spacing: 8) {
                    Circle()
                        .fill(code == 200 ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text("HTTP \(code)")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text("Showing \(viewModel.devices.count) of \(viewModel.totalSize) devices")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("devices/client-code/\(client.clientCode)?page=\(viewModel.currentPage)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle("\(client.clientCode) Device List")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.fetchPage(1, clientCode: client.clientCode)
        }
    }
}

#Preview {
    NavigationStack {
        DeviceListView(client: Client(clientId: 39, clientCode: "AAA", clientName: "AAA NCNU"))
    }
}
