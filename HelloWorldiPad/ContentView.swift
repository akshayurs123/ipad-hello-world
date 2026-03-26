import SwiftUI

struct ContentView: View {
    @State private var navigateToCustomers = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "ipad")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundStyle(.blue)

                Text("Hello, World!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Welcome to iPad development with SwiftUI")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 16) {
                    Button(action: {}) {
                        Text("Devices")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button(action: {}) {
                        Text("Commands")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    NavigationLink(destination: CustomerListView()) {
                        Text("Customer")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
