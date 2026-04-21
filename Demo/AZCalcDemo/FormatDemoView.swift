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
        AZDecimal(inputText).rounded(config).formatted(config)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("common.input.section") {
                    TextField("common.number.placeholder", text: $inputText)
                        .font(.body.monospacedDigit())
                        .keyboardType(.numbersAndPunctuation)
                        .autocorrectionDisabled()
                }

                Section("rounding.section") {
                    Stepper("common.decimalDigits.value \(decimalDigits)", value: $decimalDigits, in: 0...10)
                    Picker("rounding.type.label", selection: $roundType) {
                        ForEach(AZDecimalConfig.RoundType.demoAllCases, id: \.self) { type in
                            Text(type.demoLabel).tag(type)
                        }
                    }
                    Toggle("format.trailingZeros.label", isOn: $trailZero)
                }

                Section("format.grouping.section") {
                    Picker("format.grouping.type.label", selection: $groupType) {
                        Text("format.grouping.none").tag(AZDecimalConfig.GroupType.none)
                        Text("format.grouping.threes").tag(AZDecimalConfig.GroupType.threes)
                        Text("format.grouping.fours").tag(AZDecimalConfig.GroupType.fours)
                        Text("format.grouping.indian").tag(AZDecimalConfig.GroupType.indian)
                    }
                    HStack {
                        Text("format.grouping.separator.label")
                        Spacer()
                        TextField("format.grouping.separator.placeholder", text: $groupSeparator)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 40)
                    }
                    HStack {
                        Text("format.decimal.separator.label")
                        Spacer()
                        TextField("format.decimal.separator.placeholder", text: $decimalSeparator)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 40)
                    }
                }

                Section("common.result.section") {
                    Text(formattedResult)
                        .font(.largeTitle.bold().monospacedDigit())
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .navigationTitle("format.title")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
