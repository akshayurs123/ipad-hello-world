import SwiftUI

struct Client: Identifiable, Decodable {
    let clientId: Int
    let clientCode: String
    let clientName: String

    var id: Int { clientId }
}

private struct APIResponse: Decodable {
    let totalSize: Int
    let pageNumber: Int
    let pageSize: Int
    let data: [Client]
}

@MainActor
class CustomerViewModel: ObservableObject {
    @Published var clients: [Client] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastStatusCode: Int?
    @Published var currentPage = 1
    @Published var totalSize = 0

    let pageSize = 10
    var totalPages: Int { max(1, Int(ceil(Double(totalSize) / Double(pageSize)))) }

    private let baseURL = "https://zkcirrus-1.workdayclocks.com/iclock/api_v1/clients"

    func fetchPage(_ page: Int) async {
        isLoading = true
        errorMessage = nil

        do {
            guard let url = URL(string: "\(baseURL)?pageNum=\(page)&pageSize=\(pageSize)") else {
                throw URLError(.badURL)
            }
            let (data, response) = try await URLSession.shared.data(from: url)
            lastStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let decoded = try JSONDecoder().decode(APIResponse.self, from: data)
            clients = decoded.data
            totalSize = decoded.totalSize
            currentPage = page
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

struct CustomerListView: View {
    @StateObject private var viewModel = CustomerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Content
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading customers...")
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
                            Task { await viewModel.fetchPage(viewModel.currentPage) }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.clients) { client in
                        NavigationLink(destination: DeviceListView(client: client)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(client.clientName)
                                    .font(.headline)
                                HStack(spacing: 16) {
                                    Label("ID: \(client.clientId)", systemImage: "number")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Label(client.clientCode, systemImage: "tag")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }

            Divider()

            // Pagination controls
            HStack(spacing: 0) {
                // Left group: First + Prev
                HStack(spacing: 0) {
                    // First page
                    Button(action: {
                        Task { await viewModel.fetchPage(1) }
                    }) {
                        Image(systemName: "chevron.backward.to.line")
                            .fontWeight(.semibold)
                            .frame(width: 48, height: 44)
                            .contentShape(Rectangle())
                    }
                    .disabled(viewModel.currentPage <= 1 || viewModel.isLoading)

                    Divider().frame(height: 24)

                    // Previous
                    Button(action: {
                        Task { await viewModel.fetchPage(viewModel.currentPage - 1) }
                    }) {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                            .frame(width: 48, height: 44)
                            .contentShape(Rectangle())
                    }
                    .disabled(viewModel.currentPage <= 1 || viewModel.isLoading)
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator), lineWidth: 0.5))

                Spacer()

                // Page info
                VStack(spacing: 2) {
                    Text("Page \(viewModel.currentPage) of \(viewModel.totalPages)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("\(viewModel.totalSize) total customers")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Right group: Next + Last
                HStack(spacing: 0) {
                    // Next
                    Button(action: {
                        Task { await viewModel.fetchPage(viewModel.currentPage + 1) }
                    }) {
                        Image(systemName: "chevron.right")
                            .fontWeight(.semibold)
                            .frame(width: 48, height: 44)
                            .contentShape(Rectangle())
                    }
                    .disabled(viewModel.currentPage >= viewModel.totalPages || viewModel.isLoading)

                    Divider().frame(height: 24)

                    // Last page
                    Button(action: {
                        Task { await viewModel.fetchPage(viewModel.totalPages) }
                    }) {
                        Image(systemName: "chevron.forward.to.line")
                            .fontWeight(.semibold)
                            .frame(width: 48, height: 44)
                            .contentShape(Rectangle())
                    }
                    .disabled(viewModel.currentPage >= viewModel.totalPages || viewModel.isLoading)
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator), lineWidth: 0.5))
            }
            .padding(.horizontal, 20)
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
                    Text("Showing \(viewModel.clients.count) of \(viewModel.totalSize) customers")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("api_v1/clients?page=\(viewModel.currentPage)&pageSize=\(viewModel.pageSize)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle("Customer List")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.fetchPage(1)
        }
    }
}

#Preview {
    NavigationStack {
        CustomerListView()
    }
}
