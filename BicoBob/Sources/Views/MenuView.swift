import SwiftUI

struct MenuView: View {
    @ObservedObject var vm: LunchViewModel
    @Binding var showSettings: Bool

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider().opacity(0.3)
            dateNavSection
            Divider().opacity(0.3)
            contentSection
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack {
            Text("비코밥")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            Button("설정") { showSettings = true }
                .buttonStyle(TrayButtonStyle())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var dateNavSection: some View {
        HStack(spacing: 8) {
            Button(action: { vm.navigateDay(-1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .medium))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(NavButtonStyle())
            .disabled(!vm.canGoPrev)

            Text(vm.dateString)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)

            Button(action: { vm.navigateDay(1) }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(NavButtonStyle())
            .disabled(!vm.canGoNext)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }

    private var contentSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                errorView
                statusView
                menuView
                actionButtons
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Content Views

    @ViewBuilder
    private var errorView: some View {
        if let error = vm.error {
            Text(error)
                .font(.system(size: 12))
                .foregroundStyle(.red)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }

    @ViewBuilder
    private var statusView: some View {
        if vm.status == .fetching || vm.status == .analyzing {
            Text(vm.status == .fetching ? "메뉴 가져오는 중..." : "메뉴 분석 중...")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        } else if vm.isWeekendDay {
            Text("주말입니다")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        }
    }

    @ViewBuilder
    private var menuView: some View {
        if let menu = vm.todayMenu, vm.status != .fetching, vm.status != .analyzing, !vm.isWeekendDay {
            MenuSection(title: "중식", items: menu.lunch)
            MenuSection(title: "석식", items: menu.dinner)
        } else if vm.status == .done && vm.error == nil && !vm.isWeekendDay && vm.todayMenu == nil {
            Text("해당 요일의 메뉴 정보가 없습니다.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        if vm.status == .error {
            Button("다시 시도") {
                Task { await vm.refresh() }
            }
            .buttonStyle(FullWidthButtonStyle())
        }

        if vm.cache?.imageBase64 != nil && vm.status == .done {
            Button("메뉴 원본 이미지 보기") {
                ImageViewerWindow.show(base64: vm.cache!.imageBase64)
            }
            .buttonStyle(FullWidthButtonStyle())
        }
    }
}
