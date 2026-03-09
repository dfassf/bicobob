import SwiftUI

struct PopoverContentView: View {
    @ObservedObject var vm: LunchViewModel
    @State private var showSettings = false

    var body: some View {
        Group {
            if showSettings || vm.settings.slackToken.isEmpty {
                SettingsView(vm: vm, showSettings: $showSettings)
            } else {
                MenuView(vm: vm, showSettings: $showSettings)
            }
        }
        .frame(width: 300, height: 360)
        .background(.clear)
    }
}
