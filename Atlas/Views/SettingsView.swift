import SwiftUI
import Translation

struct SettingsView: View {
    @AppStorage("atlas.targetLocale") private var targetLocale: String = Locale.current.language.languageCode?.identifier ?? "en"
    @AppStorage("atlas.notificationsEnabled") private var notificationsEnabled: Bool = true
    @State private var availableTargets: [Locale.Language] = []

    var body: some View {
        Form {
            Section("Translation") {
                Picker("Target language", selection: $targetLocale) {
                    ForEach(availableTargets, id: \.minimalIdentifier) { language in
                        Text(Locale.current.localizedString(forLanguageCode: language.minimalIdentifier) ?? language.minimalIdentifier)
                            .tag(language.minimalIdentifier)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section("Notifications") {
                Toggle("Notify on completion", isOn: $notificationsEnabled)
                Text("When listening ends, Atlas posts a banner with the translated transcript. Tap it to open the session.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Text("Atlas activates from Control Center. Add the tile in Settings → Control Center.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .task { await loadLanguages() }
    }

    private func loadLanguages() async {
        let availability = LanguageAvailability()
        let supported = await availability.supportedLanguages
        let unique = Array(Set(supported.map(\.minimalIdentifier))).sorted()
        availableTargets = unique.map { Locale.Language(identifier: $0) }
    }
}
