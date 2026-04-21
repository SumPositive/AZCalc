// FormulaCalculatorView.swift

import SwiftUI
import AZDecimal

struct FormulaCalculatorView: View {
    @State private var viewModel = FormulaViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                resultPanel
                Form {
                    formulaSection
                    configSection
                    examplesSection
                }
            }
            .navigationTitle("formula.title")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - 結果パネル

    private var resultPanel: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if !viewModel.formula.isEmpty {
                Text(viewModel.formula)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            Text(viewModel.displayResult)
                .font(.system(size: 44, weight: .bold, design: .monospaced))
                .foregroundStyle(viewModel.hasError ? Color.red : Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - フォームセクション

    private var formulaSection: some View {
        Section("formula.input.section") {
            TextField("formula.input.placeholder", text: $viewModel.formula)
                .font(.body.monospacedDigit())
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
    }

    private var configSection: some View {
        Section("settings.title") {
            Stepper("common.decimalDigits.value \(viewModel.decimalDigits)",
                    value: $viewModel.decimalDigits, in: 0...10)
            Picker("rounding.type.label", selection: $viewModel.roundType) {
                ForEach(AZDecimalConfig.RoundType.demoAllCases, id: \.self) { type in
                    Text(type.demoLabel).tag(type)
                }
            }
        }
    }

    private var examplesSection: some View {
        Section("formula.examples.section") {
            ForEach(FormulaExample.all) { ex in
                Button {
                    viewModel.formula = ex.formula
                } label: {
                    HStack {
                        Text(ex.formula)
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(LocalizedStringKey(ex.descriptionKey))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - 使用例データ

struct FormulaExample: Identifiable {
    let id = UUID()
    let formula: String
    // 説明文は Localizable.xcstrings の ID-key で管理する。
    let descriptionKey: String

    static let all: [FormulaExample] = [
        FormulaExample(formula: "100+5%",    descriptionKey: "formula.example.addPercent"),
        FormulaExample(formula: "100-5%",    descriptionKey: "formula.example.subtractPercent"),
        FormulaExample(formula: "100×5%",    descriptionKey: "formula.example.percentOf"),
        FormulaExample(formula: "100÷5%",    descriptionKey: "formula.example.divideByPercent"),
        FormulaExample(formula: "1÷3",       descriptionKey: "formula.example.nonTerminating"),
        FormulaExample(formula: "√2",        descriptionKey: "formula.example.squareRoot"),
        FormulaExample(formula: "∛27",       descriptionKey: "formula.example.cubeRoot"),
        FormulaExample(formula: "(1+2)×(4-1)", descriptionKey: "formula.example.parentheses"),
        FormulaExample(formula: "-(20-5)",   descriptionKey: "formula.example.negate"),
        FormulaExample(formula: "-3+4×-2-6÷3", descriptionKey: "formula.example.complex"),
    ]
}
