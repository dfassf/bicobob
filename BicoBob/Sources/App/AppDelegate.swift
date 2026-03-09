import AppKit
import SwiftUI
import UserNotifications

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: StatusBarPanel!
    private var eventMonitor: Any?
    private let vm = LunchViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        panel = StatusBarPanel(content: PopoverContentView(vm: vm))
        setupStatusItem()
        setupEventMonitor()
        setupNotificationTimer()

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
            button.action = #selector(togglePanel)
            button.target = self
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
            self?.checkAndSendNotification()
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

        let content = UNMutableNotificationContent()
        content.title = "점심시간이에요!"

        if let cache = vm.cache {
            let day = DateUtils.weekdayName(offset: 0)
            if let menu = cache.menus.first(where: { $0.day == day }) {
                let items = menu.lunch.prefix(3).joined(separator: ", ")
                content.body = items.isEmpty ? "오늘의 메뉴를 확인하세요" : "오늘 메뉴: \(items)"
            }
        }

        let request = UNNotificationRequest(identifier: "lunch-\(todayKey)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cleanup

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
