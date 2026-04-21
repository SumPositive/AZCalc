// ContentView.swift

import SwiftUI
import AZDecimal

struct ContentView: View {
    var body: some View {
        TabView {
            FormulaCalculatorView()
                .tabItem { Label("app.tab.calculator", systemImage: "function") }
            RoundingComparisonView()
                .tabItem { Label("app.tab.rounding", systemImage: "plusminus") }
            FormatDemoView()
                .tabItem { Label("app.tab.format", systemImage: "textformat.123") }
        }
    }
}

// MARK: - AZDecimalConfig 拡張（デモ用ラベル）

extension AZDecimalConfig.RoundType {
    static let demoAllCases: [AZDecimalConfig.RoundType] = [
        .rup, .rPlus, .r54, .r55, .r65, .rMinus, .truncate
    ]

    var demoLabel: LocalizedStringKey {
        switch self {
        case .rup:      "rounding.mode.rup.option"
        case .rPlus:    "rounding.mode.rPlus.option"
        case .r54:      "rounding.mode.r54.option"
        case .r55:      "rounding.mode.r55.option"
        case .r65:      "rounding.mode.r65.option"
        case .rMinus:   "rounding.mode.rMinus.option"
        case .truncate: "rounding.mode.truncate.option"
        }
    }
}
