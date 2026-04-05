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
            .navigationTitle("AZFormula")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - 結果パネル

    private var resultPanel: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(viewModel.formula.isEmpty ? " " : viewModel.formula)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(viewModel.displayResult)
                .font(.system(size: 44, weight: .bold, design: .monospaced))
                .foregroundStyle(viewModel.hasError ? Color.red : Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - フォームセクション

    private var formulaSection: some View {
        Section("式") {
            TextField("例: 100+5%", text: $viewModel.formula)
                .font(.body.monospacedDigit())
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
    }

    private var configSection: some View {
        Section("設定") {
            Stepper("小数桁数: \(viewModel.decimalDigits)",
                    value: $viewModel.decimalDigits, in: 0...10)
            Picker("丸めタイプ", selection: $viewModel.roundType) {
                ForEach(AZDecimalConfig.RoundType.demoAllCases, id: \.self) { type in
                    Text(type.demoLabel).tag(type)
                }
            }
        }
    }

    private var examplesSection: some View {
        Section("使用例（タップで入力）") {
            ForEach(FormulaExample.all) { ex in
                Button {
                    viewModel.formula = ex.formula
                } label: {
                    HStack {
                        Text(ex.formula)
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(LocalizedStringKey(ex.description))
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
    let description: String

    static let all: [FormulaExample] = [
        FormulaExample(formula: "100+5%",    description: "5%増し"),
        FormulaExample(formula: "100-5%",    description: "5%引き"),
        FormulaExample(formula: "100×5%",    description: "100の5%"),
        FormulaExample(formula: "100÷5%",    description: "5%での除算"),
        FormulaExample(formula: "1÷3",       description: "割り切れない"),
        FormulaExample(formula: "√2",        description: "平方根"),
        FormulaExample(formula: "∛27",       description: "立方根"),
        FormulaExample(formula: "(1+2)×(4-1)", description: "括弧"),
        FormulaExample(formula: "-(20-5)",   description: "符号反転"),
        FormulaExample(formula: "-3+4×-2-6÷3", description: "複合式"),
    ]
}
