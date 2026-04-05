// FormatDemoView.swift

import SwiftUI
import AZDecimal

struct FormatDemoView: View {
    @State private var inputText: String = "1234567.89"
    @State private var decimalDigits: Int = 2
    @State private var roundType: AZDecimalConfig.RoundType = .r54
    @State private var groupType: AZDecimalConfig.GroupType = .threes
    @State private var groupSeparator: String = ","
    @State private var decimalSeparator: String = "."
    @State private var trailZero: Bool = true

    private var config: AZDecimalConfig {
        AZDecimalConfig(
            decimalDigits: decimalDigits,
            decimalSeparator: decimalSeparator,
            roundType: roundType,
            trailZero: trailZero,
            groupType: groupType,
            groupSeparator: groupSeparator
        )
    }

    private var formattedResult: String {
        AZDecimal(inputText).rounded(config: config).formatted(config: config)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("入力") {
                    TextField("数値", text: $inputText)
                        .font(.body.monospacedDigit())
                        .keyboardType(.numbersAndPunctuation)
                        .autocorrectionDisabled()
                }

                Section("丸め") {
                    Stepper("小数桁数: \(decimalDigits)", value: $decimalDigits, in: 0...10)
                    Picker("丸めタイプ", selection: $roundType) {
                        ForEach(AZDecimalConfig.RoundType.demoAllCases, id: \.self) { type in
                            Text(type.demoLabel).tag(type)
                        }
                    }
                    Toggle("末尾ゼロ補充", isOn: $trailZero)
                }

                Section("桁区切り") {
                    Picker("区切りタイプ", selection: $groupType) {
                        Text("なし").tag(AZDecimalConfig.GroupType.none)
                        Text("3桁 (1,234,567)").tag(AZDecimalConfig.GroupType.threes)
                        Text("4桁 (1234,5678)").tag(AZDecimalConfig.GroupType.fours)
                        Text("インド式 (12,34,567)").tag(AZDecimalConfig.GroupType.indian)
                    }
                    HStack {
                        Text("桁区切り記号")
                        Spacer()
                        TextField(",", text: $groupSeparator)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 40)
                    }
                    HStack {
                        Text("小数点記号")
                        Spacer()
                        TextField(".", text: $decimalSeparator)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 40)
                    }
                }

                Section("結果") {
                    Text(formattedResult)
                        .font(.largeTitle.bold().monospacedDigit())
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .navigationTitle("AZDecimal Format")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
