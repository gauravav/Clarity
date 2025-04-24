//
//  AppDelegate.swift
//  TaskMenuBarApp
//
//  Created by Gaurav Avula on 4/22/25.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover = NSPopover()
    var settingsWindow: NSWindow?
    let sharedSettings = AppSettings()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = ContentView(settings: sharedSettings)
            .modelContainer(for: TaskItem.self)

        popover.contentSize = NSSize(width: 400, height: 550)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "bubble.left", accessibilityDescription: "Tasks")
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.action = #selector(statusBarButtonClicked(_:))
        }
    }

    @objc func statusBarButtonClicked(_ sender: AnyObject?) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: "s"))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApp.terminate(_:)), keyEquivalent: "q"))

            // 👉 Temporarily attach the menu
            statusItem.menu = menu
            statusItem.button?.performClick(nil)

            // ✅ Reset the menu so left-click shows popover next time
            DispatchQueue.main.async {
                self.statusItem.menu = nil
            }

        } else {
            // Left click - show task popover
            if popover.isShown {
                popover.performClose(sender)
            } else if let button = statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }


    @objc func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView(settings: sharedSettings)
            let hostingController = NSHostingController(rootView: settingsView)

            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.contentView = hostingController.view
            settingsWindow?.title = "Settings"
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
