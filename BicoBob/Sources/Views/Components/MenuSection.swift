import SwiftUI

struct MenuSection: View {
    let title: String
    let items: [String]

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .padding(.bottom, 2)

                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundStyle(.cyan)
                        Text(item)
                            .font(.system(size: 13))
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
                }
            }
        }
    }
}
