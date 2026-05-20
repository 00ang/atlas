import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(sort: [SortDescriptor(\Session.startedAt, order: .reverse)])
    private var sessions: [Session]

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "No sessions yet",
                    systemImage: "waveform",
                    description: Text("Tap the Atlas tile in Control Center to start a session.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(sessions) { session in
                    NavigationLink(value: session.id) {
                        SessionRow(session: session)
                    }
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle("Atlas")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
        .navigationDestination(for: UUID.self) { id in
            if let session = sessions.first(where: { $0.id == id }) {
                SessionDetailView(session: session)
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sessions[index])
        }
        try? modelContext.save()
    }
}

private struct SessionRow: View {
    let session: Session

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.startedAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(session.startedAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(session.sourceLocale.uppercased()) → \(session.targetLocale.uppercased())")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            Text(session.translatedTranscript.isEmpty ? "(no translation)" : session.translatedTranscript)
                .lineLimit(2)
                .font(.body)
        }
        .padding(.vertical, 4)
    }
}
