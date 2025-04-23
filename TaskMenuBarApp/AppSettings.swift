//
//  AppSettings.swift
//  TaskMenuBarApp
//
//  Created by Gaurav Avula on 4/22/25.
//

import SwiftUI

class AppSettings: ObservableObject {
    @Published var enableAnimation: Bool = true
    @Published var enableUndoDelete: Bool = true
    @Published var showConfetti: Bool = true
    @Published var themeMode: ThemeMode = .system
    @Published var autoReset: ResetInterval = .off
    @Published var showMenuBarBadge: Bool = true
    @Published var autoLaunchOnLogin: Bool = false

    enum ThemeMode: String, CaseIterable, Identifiable {
        case light, dark, system
        var id: String { rawValue }
    }

    enum ResetInterval: String, CaseIterable, Identifiable {
        case off, daily, weekly
        var id: String { rawValue }
    }
}
