// RoundingViewModel.swift

import Observation
import AZDecimal

struct RoundingRow: Identifiable {
    let id: AZDecimalConfig.RoundType
    let modeName: String
    let description: String
    let result: String
}

@Observable
@MainActor
final class RoundingViewModel {

    var inputText: String = "3.456"
    var decimalDigits: Int = 2

    var rows: [RoundingRow] {
        let specs: [(AZDecimalConfig.RoundType, String, String)] = [
            (.rup,      "切り上げ",    "絶対値方向に丸める"),
            (.rPlus,    "正方向",      "正の無限大方向に丸める"),
            (.r54,      "四捨五入",    "JIS Z 8401 規則B"),
            (.r55,      "五捨五超入",  "JIS Z 8401 規則A（偶数丸め）"),
            (.r65,      "五捨六入",    "5は切り捨て・6以上は切り上げ"),
            (.rMinus,   "負方向",      "負の無限大方向に丸める"),
            (.truncate, "切り捨て",    "丸めなし（生の値を返す）"),
        ]
        let value = AZDecimal(inputText)
        return specs.map { (type, name, desc) in
            let config = AZDecimalConfig(decimalDigits: decimalDigits, roundType: type)
            return RoundingRow(
                id: type,
                modeName: name,
                description: desc,
                result: value.rounded(config: config).value
            )
        }
    }
}
