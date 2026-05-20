import SwiftUI

struct SessionDetailView: View {
    let session: Session

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                metadata
                section(title: "Translated (\(session.targetLocale.uppercased()))", text: session.translatedTranscript)
                section(title: "Original (\(session.sourceLocale.uppercased()))", text: session.originalTranscript)
            }
            .padding()
        }
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.startedAt, format: .dateTime)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let endedAt = session.endedAt {
                let duration = endedAt.timeIntervalSince(session.startedAt)
                Text("Duration: \(Int(duration))s")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    @ViewBuilder
    private func section(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(text.isEmpty ? "(empty)" : text)
                .font(.body)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var shareText: String {
        """
        Atlas session — \(session.startedAt.formatted(date: .abbreviated, time: .shortened))
        \(session.sourceLocale.uppercased()) → \(session.targetLocale.uppercased())

        Translated:
        \(session.translatedTranscript)

        Original:
        \(session.originalTranscript)
        """
    }
}
