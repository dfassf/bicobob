import SwiftUI

struct TrayButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(configuration.isPressed ? Color.primary.opacity(0.15) : Color.primary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct NavButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? (configuration.isPressed ? .primary : .secondary) : .quaternary)
            .background(configuration.isPressed ? Color.primary.opacity(0.15) : Color.primary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct FullWidthButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(configuration.isPressed ? Color.primary.opacity(0.15) : Color.primary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct SaveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(configuration.isPressed ? Color.primary.opacity(0.15) : Color.primary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
