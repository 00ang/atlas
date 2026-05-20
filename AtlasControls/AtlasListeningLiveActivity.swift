import ActivityKit
import AtlasShared
import SwiftUI
import WidgetKit

struct AtlasListeningLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AtlasListeningAttributes.self) { context in
            LockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text("Atlas")
                            .font(.caption.weight(.semibold))
                    } icon: {
                        Image(systemName: "mic.fill")
                            .foregroundStyle(.orange)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    StopButton()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        if !context.state.originalPreview.isEmpty {
                            Text(context.state.originalPreview)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        if !context.state.translatedPreview.isEmpty {
                            Text(context.state.translatedPreview)
                                .font(.callout)
                                .foregroundStyle(.primary)
                                .lineLimit(3)
                        } else if let status = context.state.statusMessage {
                            Text(status)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                Image(systemName: "mic.fill")
                    .foregroundStyle(.orange)
            } compactTrailing: {
                if !context.state.sourceLocaleCode.isEmpty {
                    Text(context.state.sourceLocaleCode.prefix(2).uppercased())
                        .font(.caption2.monospaced())
                }
            } minimal: {
                Image(systemName: "mic.fill")
                    .foregroundStyle(.orange)
            }
            .keylineTint(.orange)
        }
    }
}

private struct LockScreenView: View {
    let context: ActivityViewContext<AtlasListeningAttributes>

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "mic.fill")
                        .foregroundStyle(.orange)
                    Text("Atlas listening")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                    if !context.state.sourceLocaleCode.isEmpty {
                        Text(context.state.sourceLocaleCode.uppercased())
                            .font(.caption2.monospaced())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                if !context.state.originalPreview.isEmpty {
                    Text(context.state.originalPreview)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                if !context.state.translatedPreview.isEmpty {
                    Text(context.state.translatedPreview)
                        .font(.callout)
                        .foregroundStyle(.white)
                        .lineLimit(3)
                } else if let status = context.state.statusMessage {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            StopButton()
        }
        .padding(12)
    }
}

private struct StopButton: View {
    var body: some View {
        Button(intent: StopListeningIntent()) {
            Label("Stop", systemImage: "stop.fill")
                .labelStyle(.iconOnly)
                .font(.headline)
                .foregroundStyle(.white)
                .padding(10)
                .background(Color.red)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Stop listening")
    }
}
