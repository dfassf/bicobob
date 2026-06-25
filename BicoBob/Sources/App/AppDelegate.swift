import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: StatusBarPanel!
    private var eventMonitor: Any?
    private let vm = LunchViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        panel = StatusBarPanel(content: PopoverContentView(vm: vm))
        panel.applyAppearance(darkMode: vm.settings.darkMode)
        setupStatusItem()
        setupEventMonitor()
        setupNotificationTimer()
        setupAppearanceObserver()

        if vm.settings.showOnStartup {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let button = self?.statusItem.button else { return }
                self?.panel.show(relativeTo: button)
            }
        }

        Task { await vm.refresh() }
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "fork.knife", accessibilityDescription: "비코밥")
            button.action = #selector(handleStatusClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])  // 우클릭도 받기
        }
    }

    @objc private func handleStatusClick() {
        let event = NSApp.currentEvent
        let isRightClick = event?.type == .rightMouseUp
            || event?.modifierFlags.contains(.control) == true
        if isRightClick {
            showStatusMenu()
        } else {
            togglePanel()
        }
    }

    private func showStatusMenu() {
        panel.hide()
        let menu = NSMenu()
        let quit = NSMenuItem(title: "비코밥 종료", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        if let button = statusItem.button {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    private func setupAppearanceObserver() {
        NotificationCenter.default.addObserver(
            forName: .bicoAppearanceChanged, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.panel.applyAppearance(darkMode: self.vm.settings.darkMode)
            }
        }
    }

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.panel.hide()
        }
    }

    @objc private func togglePanel() {
        guard let button = statusItem.button else { return }
        panel.toggle(relativeTo: button)
        if panel.isVisible {
            Task { await vm.refresh() }
        }
    }

    // MARK: - Notifications

    private func setupNotificationTimer() {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkAndSendNotification()
            }
        }
    }

    private func checkAndSendNotification() {
        let settings = vm.settings
        guard settings.notifyEnabled else { return }

        let timeStr = DateUtils.timeString()
        guard timeStr == settings.notifyTime else { return }

        let todayKey = DateUtils.dateString()
        let lastNotify = UserDefaults.standard.string(forKey: "last_notify_date")
        guard lastNotify != todayKey else { return }

        UserDefaults.standard.set(todayKey, forKey: "last_notify_date")

        var body = "오늘의 메뉴를 확인하세요"
        if let cache = vm.cache {
            let day = DateUtils.weekdayName(offset: 0)
            if let menu = cache.menus.first(where: { $0.day == day }) {
                let items = menu.lunch.prefix(3).joined(separator: ", ")
                if !items.isEmpty { body = items }
            }
        }

        NotificationWindow.show(title: "점심시간이에요!", body: body, darkMode: vm.settings.darkMode)
    }

    // MARK: - Cleanup

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
