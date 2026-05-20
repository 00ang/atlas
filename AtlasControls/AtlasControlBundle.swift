import SwiftUI
import WidgetKit

@main
struct AtlasControlBundle: WidgetBundle {
    var body: some Widget {
        StartListeningControl()
        AtlasListeningLiveActivity()
    }
}
