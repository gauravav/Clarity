//
//  SettingsView.swift
//  TaskMenuBarApp
//
//  Created by Gaurav Avula on 4/22/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section(header: Text("General")) {
                Toggle("Drag-to-Reorder Animation", isOn: $settings.enableAnimation)
                Toggle("Undo Last Delete", isOn: $settings.enableUndoDelete)
                Toggle("Confetti on Completion", isOn: $settings.showConfetti)
            }

            Section(header: Text("Appearance")) {
                Picker("Theme", selection: $settings.themeMode) {
                    ForEach(AppSettings.ThemeMode.allCases) { mode in
                        Text(mode.rawValue.capitalized).tag(mode)
                    }
                }
            }

            Section(header: Text("Automation")) {
                Picker("Auto Reset", selection: $settings.autoReset) {
                    ForEach(AppSettings.ResetInterval.allCases) { interval in
                        Text(interval.rawValue.capitalized).tag(interval)
                    }
                }
                Toggle("Auto Launch on Login", isOn: $settings.autoLaunchOnLogin)
            }

            Section(header: Text("Display")) {
                Toggle("Show Menu Bar Badge", isOn: $settings.showMenuBarBadge)
            }
        }
        .padding()
        .frame(width: 375)
    }
}
