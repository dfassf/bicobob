import AppKit
import SwiftUI

@MainActor
final class StatusBarPanel {
    private let panel: NSPanel
    private let visualEffect: NSVisualEffectView
    private let panelWidth: CGFloat = 300
    private let panelHeight: CGFloat = 360

    init<Content: View>(content: Content) {
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .menu
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 10
        visualEffect.layer?.masksToBounds = true

        self.visualEffect = visualEffect

        let hostingView = TransparentHostingView(rootView: content)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        visualEffect.addSubview(hostingView)

        panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.hasShadow = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = false
        panel.contentView = visualEffect

        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
        ])
    }

    var isVisible: Bool { panel.isVisible }

    /// 패널 외관을 다크/라이트로 적용한다.
    /// panel.appearance 하나만 바꾸면 블러 배경(visualEffect)·SwiftUI 콘텐츠가 모두 따라온다.
    /// (visualEffect.appearance 를 따로 박으면 패널 변경을 무시해버려 다크 고정 버그 발생 → 박지 않는다)
    func applyAppearance(darkMode: Bool) {
        panel.appearance = NSAppearance(named: darkMode ? .darkAqua : .aqua)
    }

    func toggle(relativeTo button: NSStatusBarButton) {
        if panel.isVisible {
            hide()
        } else {
            show(relativeTo: button)
        }
    }

    func show(relativeTo button: NSStatusBarButton) {
        guard let buttonWindow = button.window else { return }
        let buttonFrame = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))

        let x = buttonFrame.midX - panelWidth / 2
        let y = buttonFrame.minY - panelHeight - 2

        panel.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true)
        panel.makeKeyAndOrderFront(nil)
        // accessory 앱이라 키보드 포커스를 받으려면 활성화 필요 (텍스트필드 입력용)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        panel.orderOut(nil)
    }
}

/// nonactivatingPanel 은 기본적으로 key 윈도우가 안 돼 텍스트필드 입력을 못 받는다.
/// canBecomeKey 를 열어 설정 화면의 시간 입력 등이 키보드 입력을 받게 한다.
private final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}
