// RoundingComparisonView.swift

import SwiftUI

struct RoundingComparisonView: View {
    @State private var viewModel = RoundingViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("common.input.section") {
                    TextField("common.number.placeholder", text: $viewModel.inputText)
                        .font(.body.monospacedDigit())
                        .keyboardType(.numbersAndPunctuation)
                        .autocorrectionDisabled()
                    Stepper("common.decimalDigits.value \(viewModel.decimalDigits)",
                            value: $viewModel.decimalDigits, in: 0...10)
                }

                Section {
                    ForEach(viewModel.rows) { row in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizedStringKey(row.modeNameKey))
                                    .font(.subheadline.bold())
                                Text(LocalizedStringKey(row.descriptionKey))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(row.result)
                                .font(.body.monospacedDigit())
                                .foregroundStyle(row.id == .keepFull ? .secondary : .primary)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("rounding.comparison.title")
                } footer: {
                    Text("rounding.keepFull.footer")
                        .font(.caption)
                }
            }
            .navigationTitle("rounding.title")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
