import AppIntents
import AtlasShared
import SwiftUI
import WidgetKit

struct StartListeningControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.atlas.app.controls.start") {
            ControlWidgetButton(action: StartListeningIntent()) {
                Label("Atlas", systemImage: "mic.fill")
            }
        }
        .displayName("Atlas")
        .description("Listen and translate nearby audio.")
    }
}
