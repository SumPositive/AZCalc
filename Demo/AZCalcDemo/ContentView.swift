// ContentView.swift

import SwiftUI
import AZDecimal

struct ContentView: View {
    var body: some View {
        TabView {
            FormulaCalculatorView()
                .tabItem { Label("計算機", systemImage: "function") }
            RoundingComparisonView()
                .tabItem { Label("丸め", systemImage: "plusminus") }
            FormatDemoView()
                .tabItem { Label("書式", systemImage: "textformat.123") }
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
        case .rup:      "切り上げ (rup)"
        case .rPlus:    "正方向 (rPlus)"
        case .r54:      "四捨五入 (r54)"
        case .r55:      "五捨五超入 (r55)"
        case .r65:      "五捨六入 (r65)"
        case .rMinus:   "負方向 (rMinus)"
        case .truncate: "切り捨て (truncate)"
        }
    }
}
