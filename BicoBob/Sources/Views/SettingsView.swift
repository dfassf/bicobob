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

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider().opacity(0.3)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    apiSection
                    Divider().opacity(0.2).padding(.vertical, 4)
                    generalSection
                    saveButton
                }
                .padding(14)
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack {
            Button("< 뒤로") { showSettings = false }
                .buttonStyle(TrayButtonStyle())
            Spacer()
            Text("설정")
                .font(.system(size: 13, weight: .semibold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var apiSection: some View {
        Group {
            SettingsField(label: "Slack Token", text: $form.slackToken, placeholder: "xoxp-...", isSecure: true)
            SettingsField(label: "채널명", text: $form.channelName, placeholder: "general")
            SettingsField(label: "Slack 사용자명", text: $form.username, placeholder: "홍길동")
            SettingsField(label: "Gemini API Key", text: $form.geminiApiKey, placeholder: "AIza...", isSecure: true)
        }
    }

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsToggleRow(label: "점심 알림", isOn: $form.notifyEnabled) {
                TextField("12:35", text: $form.notifyTime)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .disabled(!form.notifyEnabled)
                    .opacity(form.notifyEnabled ? 1 : 0.4)
            }

            SettingsToggleRow(label: "시작 시 패널 표시", isOn: $form.showOnStartup)
            SettingsToggleRow(label: "로그인 시 자동 실행", isOn: $form.launchAtLogin)
        }
    }

    private var saveButton: some View {
        Button("저장") {
            vm.settings = form
            vm.saveSettings()
            LaunchAtLoginService.setEnabled(form.launchAtLogin)
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
