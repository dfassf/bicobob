import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var vm: LunchViewModel
    @Binding var showSettings: Bool
    @State private var form: AppSettings

    init(vm: LunchViewModel, showSettings: Binding<Bool>) {
        self.vm = vm
        self._showSettings = showSettings
        self._form = State(initialValue: vm.settings)
    }

    // "HH:mm" 문자열 ↔ Date 변환. DatePicker(.hourAndMinute)는 항상 유효한 시각만 내므로
    // 잘못된 입력이 원천적으로 불가능하다(검증 불필요).
    private var notifyTimeBinding: Binding<Date> {
        Binding(
            get: { Self.date(fromHHmm: form.notifyTime) },
            set: { form.notifyTime = Self.hhmm(from: $0) }
        )
    }

    private static func date(fromHHmm hhmm: String) -> Date {
        let parts = hhmm.split(separator: ":")
        var comps = DateComponents()
        comps.hour = parts.indices.contains(0) ? Int(parts[0]) ?? 12 : 12
        comps.minute = parts.indices.contains(1) ? Int(parts[1]) ?? 35 : 35
        return Calendar.current.date(from: comps) ?? Date()
    }

    private static func hhmm(from date: Date) -> String {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider().opacity(0.3)

            ScrollView {
                generalSection
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
            }

            saveButton
                .padding(.horizontal, 14)
                .padding(.bottom, 6)

            Button("비코밥 종료") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.bottom, 12)
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack {
            Button(action: { showSettings = false }) {
                HStack(spacing: 3) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .semibold))
                    Text("뒤로")
                }
            }
            .buttonStyle(TrayButtonStyle())
            Spacer()
            Text("설정")
                .font(.system(size: 13, weight: .semibold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsToggleRow(label: "점심 알림", isOn: $form.notifyEnabled) {
                DatePicker("", selection: notifyTimeBinding, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .frame(width: 90)
                    .disabled(!form.notifyEnabled)
                    .opacity(form.notifyEnabled ? 1 : 0.4)
            }

            SettingsToggleRow(label: "시작 시 패널 표시", isOn: $form.showOnStartup)
            SettingsToggleRow(label: "로그인 시 자동 실행", isOn: $form.launchAtLogin)
            SettingsToggleRow(label: "다크 모드", isOn: Binding(
                get: { form.darkMode },
                set: { newValue in
                    form.darkMode = newValue
                    vm.settings.darkMode = newValue          // 즉시 반영용으로 vm 에도 커밋
                    NotificationCenter.default.post(name: .bicoAppearanceChanged, object: nil)
                }
            ))
        }
    }

    private var saveButton: some View {
        Button("저장") {
            vm.settings = form
            vm.saveSettings()
            LaunchAtLoginService.setEnabled(form.launchAtLogin)
            NotificationCenter.default.post(name: .bicoAppearanceChanged, object: nil)
            showSettings = false
            Task { await vm.refresh() }
        }
        .buttonStyle(SaveButtonStyle())
        .padding(.top, 4)
    }
}

// MARK: - Subcomponents

struct SettingsField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
            }
        }
    }
}

struct SettingsToggleRow<Trailing: View>: View {
    let label: String
    @Binding var isOn: Bool
    var trailing: (() -> Trailing)?

    init(label: String, isOn: Binding<Bool>, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.label = label
        self._isOn = isOn
        self.trailing = trailing
    }

    init(label: String, isOn: Binding<Bool>) where Trailing == EmptyView {
        self.label = label
        self._isOn = isOn
        self.trailing = nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Toggle("", isOn: $isOn)
                    .toggleStyle(.checkbox)
                    .labelsHidden()

                if let trailing {
                    trailing()
                }
            }
        }
    }
}
