import SwiftUI

struct RootTabView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        TabView {
            ContentView(settings: settings)
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }

            SettingsView(settings: settings)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}



