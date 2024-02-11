import SwiftUI

struct SettingsPreferencesSection: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Section {
            appearancePicker
            themePicker
            iconPicker

        } header: {
            Text("Preferences")
        } footer: {
            Text("Styling options will be a paid feature in the App Store version.")
        }
        .tint(.secondary)
    }

    var themePicker: some View {
        Picker(selection: $settings.theme) {
            ForEach(Theme.allCases) { theme in
                Text(theme.rawValue)
            }
        } label: {
            Label {
                Text("Accent Color")
            } icon: {
                Image(systemName: "paintpalette").foregroundStyle(settings.theme.tint)
            }
        }
        .onChange(of: settings.theme) {
            dependencies.router.reset()
        }
    }

    var appearancePicker: some View {
        Picker(selection: $settings.appearance) {
            ForEach(Appearance.allCases) { colorScheme in
                Text(colorScheme.rawValue)
            }
        } label: {
            Label {
                Text("Appearance")
            } icon: {
                if settings.appearance.preferredColorScheme == .dark {
                    Image(systemName: "moon").foregroundStyle(.white)
                } else {
                    Image(systemName: "sun.max").foregroundStyle(.black)
                }
            }
        }
    }

    var iconPicker: some View {
        NavigationLink(value: SettingsView.Path.icons) {
            Label {
                LabeledContent {
                    Text(settings.icon.data.label)
                } label: {
                    Text("App Icon")
                }
            } icon: {
                Image(
                    uiImage: UIImage(named: UIApplication.shared.alternateIconName ?? "AppIcon")!
                )
                .resizable()
                .frame(width: 24, height: 24)
                .clipShape(.rect(cornerRadius: (10 / 57) * 24))
            }
        }
    }
}
