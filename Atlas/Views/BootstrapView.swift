import SwiftUI

struct BootstrapView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 48, weight: .regular))
                    .foregroundStyle(.secondary)
                Text("Listening in the background")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    BootstrapView()
}
