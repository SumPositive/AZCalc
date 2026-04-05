// RoundingComparisonView.swift

import SwiftUI

struct RoundingComparisonView: View {
    @State private var viewModel = RoundingViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("入力") {
                    TextField("数値", text: $viewModel.inputText)
                        .font(.body.monospacedDigit())
                        .keyboardType(.numbersAndPunctuation)
                        .autocorrectionDisabled()
                    Stepper("小数桁数: \(viewModel.decimalDigits)",
                            value: $viewModel.decimalDigits, in: 0...10)
                }

                Section {
                    ForEach(viewModel.rows) { row in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizedStringKey(row.modeName))
                                    .font(.subheadline.bold())
                                Text(LocalizedStringKey(row.description))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(row.result)
                                .font(.body.monospacedDigit())
                                .foregroundStyle(row.id == .truncate ? .secondary : .primary)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("丸めモード比較")
                } footer: {
                    Text("切り捨て（truncate）は桁制限なしで生の値を返します。")
                        .font(.caption)
                }
            }
            .navigationTitle("AZDecimal Rounding")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
