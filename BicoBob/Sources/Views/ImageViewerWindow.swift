import AppKit
import SwiftUI

enum ImageViewerWindow {
    private static var window: NSWindow?

    static func show(base64: String) {
        // Close existing
        window?.close()
        window = nil

        // Parse base64 data URL
        guard let commaIndex = base64.firstIndex(of: ",") else { return }
        let pureB64 = String(base64[base64.index(after: commaIndex)...])
        guard let data = Data(base64Encoded: pureB64),
              let nsImage = NSImage(data: data) else { return }

        let view = ImageViewerView(image: nsImage)
        let hostingView = NSHostingView(rootView: view)

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        w.title = "메뉴 원본 이미지"
        w.contentView = hostingView
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        window = w
    }
}

struct ImageViewerView: View {
    let image: NSImage
    @State private var zoomed = false

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: zoomed ? .fill : .fit)
                .scaleEffect(zoomed ? 2.0 : 1.0)
                .frame(
                    minWidth: zoomed ? 1600 : 400,
                    minHeight: zoomed ? 1200 : 300
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        zoomed.toggle()
                    }
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }
}
