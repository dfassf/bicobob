import AppKit
import SwiftUI

@MainActor
final class NotificationWindow {
    private static var window: NSWindow?
    private static var hideTask: Task<Void, Never>?

    static func show(title: String, body: String, darkMode: Bool, duration: TimeInterval = 5) {
        hide()

        let view = NotificationPopupView(title: title, message: body) {
            hide()
        }

        let hostingView = TransparentHostingView(rootView: view)
        let size = NSSize(width: 300, height: 90)
        hostingView.frame = NSRect(origin: .zero, size: size)

        let w = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = true
        w.level = .floating
        w.collectionBehavior = [.canJoinAllSpaces, .stationary]
        w.isMovableByWindowBackground = false
        w.titlebarAppearsTransparent = true
        w.titleVisibility = .hidden
        w.appearance = NSAppearance(named: darkMode ? .darkAqua : .aqua)  // 앱 다크모드 토글 반영

        let effect = NSVisualEffectView(frame: w.contentView!.bounds)
        effect.autoresizingMask = [.width, .height]
        // 다크: 어두운 HUD 유지 / 라이트: 외관 따라가는 popover 재질 (hudWindow 는 모드 무관 항상 어둠)
        effect.material = darkMode ? .hudWindow : .popover
        effect.state = .active
        effect.wantsLayer = true
        effect.layer?.cornerRadius = 12
        effect.layer?.masksToBounds = true

        w.contentView?.addSubview(effect)
        w.contentView?.addSubview(hostingView)
        hostingView.frame = w.contentView!.bounds
        hostingView.autoresizingMask = [.width, .height]

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - size.width / 2
            let y = screenFrame.midY + 50
            w.setFrameOrigin(NSPoint(x: x, y: y))
        }

        w.alphaValue = 0
        w.orderFront(nil)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            w.animator().alphaValue = 1
        }

        window = w

        hideTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            hide()
        }
    }

    static func hide() {
        hideTask?.cancel()
        hideTask = nil
        guard let w = window else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.2
            w.animator().alphaValue = 0
        }, completionHandler: {
            w.orderOut(nil)
        })
        window = nil
    }
}

// MARK: - SwiftUI View

private struct NotificationPopupView: View {
    let title: String
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.clear)
    }
}
