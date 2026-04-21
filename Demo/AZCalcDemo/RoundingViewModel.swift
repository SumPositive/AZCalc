// RoundingViewModel.swift

import Observation
import AZDecimal

struct RoundingRow: Identifiable {
    let id: AZDecimalConfig.RoundType
    let modeNameKey: String
    let descriptionKey: String
    let result: String
}

@Observable
@MainActor
final class RoundingViewModel {

    var inputText: String = "3.456"
    var decimalDigits: Int = 2

    var rows: [RoundingRow] {
        // 表示名と説明文は Localizable.xcstrings の ID-key で管理する。
        let specs: [(AZDecimalConfig.RoundType, String, String)] = [
            (.rup,      "rounding.mode.rup.title",      "rounding.mode.rup.description"),
            (.rPlus,    "rounding.mode.rPlus.title",    "rounding.mode.rPlus.description"),
            (.r54,      "rounding.mode.r54.title",      "rounding.mode.r54.description"),
            (.r55,      "rounding.mode.r55.title",      "rounding.mode.r55.description"),
            (.r65,      "rounding.mode.r65.title",      "rounding.mode.r65.description"),
            (.rMinus,   "rounding.mode.rMinus.title",   "rounding.mode.rMinus.description"),
            (.truncate, "rounding.mode.truncate.title", "rounding.mode.truncate.description"),
        ]
        let value = AZDecimal(inputText)
        return specs.map { (type, name, desc) in
            let config = AZDecimalConfig(decimalDigits: decimalDigits, roundType: type)
            return RoundingRow(
                id: type,
                modeNameKey: name,
                descriptionKey: desc,
                result: value.rounded(config).value
            )
        }
    }
}
