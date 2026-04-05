// AZDecimalTests.swift
// AZDecimal 演算・丸め・書式テスト

import XCTest
@testable import AZDecimal

// MARK: - 四則演算

final class ArithmeticTests: XCTestCase {

    func test_add_basic() {
        XCTAssertEqual(AZDecimal("1.1") + AZDecimal("2.0456"), AZDecimal("3.1456"))
    }

    func test_add_negativeRHS() {
        XCTAssertEqual(AZDecimal("1.1") + AZDecimal("-2.0456"), AZDecimal("-0.9456"))
    }

    func test_subtract() {
        XCTAssertEqual(AZDecimal("5.25") - AZDecimal("2.1"), AZDecimal("3.15"))
    }

    func test_multiply() {
        XCTAssertEqual(AZDecimal("2.5") * AZDecimal("4.0"), AZDecimal("10"))
    }

    func test_divide() {
        XCTAssertEqual(AZDecimal("10.0") / AZDecimal("4.0"), AZDecimal("2.5"))
    }

    func test_add_negativeLHS() {
        XCTAssertEqual(AZDecimal("-1.5") + AZDecimal("2.5"), AZDecimal("1"))
    }

    func test_divideByZero_returnsError() {
        // ゼロ除算はエラー値（"-0"）を返す
        XCTAssertEqual(AZDecimal("123.45") / AZDecimal("0"), AZDecimal("-0"))
    }

    func test_invalidCharacters_filtered() {
        XCTAssertEqual(AZDecimal("abc123.45円"), AZDecimal("123.45"))
    }

    func test_add_withInvalidCharacters() {
        XCTAssertEqual(AZDecimal("abc123.45円") + AZDecimal("¥0.55"), AZDecimal("124"))
    }

    func test_add_maxPrecision() {
        let half = AZDecimal.precision / 2
        let max1 = String(repeating: "1", count: half)
        let max2 = String(repeating: "2", count: half)
        let max3 = String(repeating: "3", count: half)
        XCTAssertEqual(
            AZDecimal(max1 + "." + max1) + AZDecimal(max2 + "." + max2),
            AZDecimal(max3 + "." + max3)
        )
    }

    func test_add_decimalCarryUp() {
        let half = AZDecimal.precision / 2
        let max9 = String(repeating: "9", count: half)
        let max0 = String(repeating: "0", count: half - 1) + "1"
        XCTAssertEqual(AZDecimal("0." + max9) + AZDecimal("0." + max0), AZDecimal("1"))
    }

    func test_add_integerOverflow_returnsError() {
        let half = AZDecimal.precision / 2
        let max9 = String(repeating: "9", count: half)
        // 最大桁を超えるとオーバーフローエラー（"-0"）
        XCTAssertEqual(AZDecimal(max9 + ".9") + AZDecimal("0.1"), AZDecimal("-0"))
    }

    func test_multiply_atMaxPrecision() {
        let half = AZDecimal.precision / 2
        let max0 = String(repeating: "0", count: half - 1) + "1"
        let max9 = String(repeating: "9", count: half)
        let a = AZDecimal("0." + max0)
        XCTAssertEqual(a * AZDecimal(max9), AZDecimal("0." + max9))
        // 偶数丸めが適用される
        XCTAssertEqual(a * AZDecimal(max9 + "." + max9), AZDecimal("1"))
    }
}

// MARK: - 丸め

final class RoundingTests: XCTestCase {

    func test_truncate_returnsRawValue() {
        let value = AZDecimal("3.129")
        let config = AZDecimalConfig(decimalDigits: 2, roundType: .truncate)
        // truncate モードでは rounded() は self を返す（桁制限なし）
        XCTAssertEqual(value.rounded(config: config), value)
    }

    func test_rup_absoluteCeiling() {
        let value = AZDecimal("9.9001")
        XCTAssertEqual(value.rounded(config: AZDecimalConfig(decimalDigits: 3, roundType: .rup)), AZDecimal("9.901"))
        XCTAssertEqual(value.rounded(config: AZDecimalConfig(decimalDigits: 2, roundType: .rup)), AZDecimal("9.91"))
        XCTAssertEqual(value.rounded(config: AZDecimalConfig(decimalDigits: 1, roundType: .rup)), AZDecimal("10"))
        XCTAssertEqual(value.rounded(config: AZDecimalConfig(decimalDigits: 0, roundType: .rup)), AZDecimal("10"))
    }

    func test_rMinus_negativeDirection() {
        let neg = AZDecimal("-3.1001")
        XCTAssertEqual(neg.rounded(config: AZDecimalConfig(decimalDigits: 3, roundType: .rMinus)), AZDecimal("-3.101"))
        XCTAssertEqual(neg.rounded(config: AZDecimalConfig(decimalDigits: 2, roundType: .rMinus)), AZDecimal("-3.11"))
        XCTAssertEqual(neg.rounded(config: AZDecimalConfig(decimalDigits: 1, roundType: .rMinus)), AZDecimal("-3.2"))
        XCTAssertEqual(neg.rounded(config: AZDecimalConfig(decimalDigits: 0, roundType: .rMinus)), AZDecimal("-4"))
        // 正値は切り捨て同様
        XCTAssertEqual(AZDecimal("3.1001").rounded(config: AZDecimalConfig(decimalDigits: 3, roundType: .rMinus)), AZDecimal("3.1"))
    }

    func test_rPlus_positiveDirection() {
        let pos = AZDecimal("3.1001")
        XCTAssertEqual(pos.rounded(config: AZDecimalConfig(decimalDigits: 3, roundType: .rPlus)), AZDecimal("3.101"))
        XCTAssertEqual(pos.rounded(config: AZDecimalConfig(decimalDigits: 2, roundType: .rPlus)), AZDecimal("3.11"))
        XCTAssertEqual(pos.rounded(config: AZDecimalConfig(decimalDigits: 1, roundType: .rPlus)), AZDecimal("3.2"))
        XCTAssertEqual(pos.rounded(config: AZDecimalConfig(decimalDigits: 0, roundType: .rPlus)), AZDecimal("4"))
        // 負値は切り捨て同様
        XCTAssertEqual(AZDecimal("-3.1001").rounded(config: AZDecimalConfig(decimalDigits: 3, roundType: .rPlus)), AZDecimal("-3.1"))
    }

    func test_r54_roundHalfUp() {
        let value = AZDecimal("3.95345001")
        XCTAssertEqual(value.rounded(config: AZDecimalConfig(decimalDigits: 6, roundType: .r54)), AZDecimal("3.95345"))
        XCTAssertEqual(value.rounded(config: AZDecimalConfig(decimalDigits: 5, roundType: .r54)), AZDecimal("3.95345"))
        XCTAssertEqual(value.rounded(config: AZDecimalConfig(decimalDigits: 4, roundType: .r54)), AZDecimal("3.9535"))
        XCTAssertEqual(value.rounded(config: AZDecimalConfig(decimalDigits: 3, roundType: .r54)), AZDecimal("3.953"))
        XCTAssertEqual(value.rounded(config: AZDecimalConfig(decimalDigits: 2, roundType: .r54)), AZDecimal("3.95"))
        XCTAssertEqual(value.rounded(config: AZDecimalConfig(decimalDigits: 1, roundType: .r54)), AZDecimal("4"))
        XCTAssertEqual(value.rounded(config: AZDecimalConfig(decimalDigits: 0, roundType: .r54)), AZDecimal("4"))
    }

    func test_r55_bankersRounding() {
        // 偶数位で「五」→ 切り捨て
        XCTAssertEqual(AZDecimal("1.25").rounded(config: AZDecimalConfig(decimalDigits: 1, roundType: .r55)), AZDecimal("1.2"))
        // 偶数位で「五超」→ 切り上げ
        XCTAssertEqual(AZDecimal("1.250000001").rounded(config: AZDecimalConfig(decimalDigits: 1, roundType: .r55)), AZDecimal("1.3"))
        XCTAssertEqual(AZDecimal("1.26").rounded(config: AZDecimalConfig(decimalDigits: 1, roundType: .r55)), AZDecimal("1.3"))
        // 奇数位で「五以上」→ 切り上げ
        XCTAssertEqual(AZDecimal("1.349999").rounded(config: AZDecimalConfig(decimalDigits: 1, roundType: .r55)), AZDecimal("1.3"))
        XCTAssertEqual(AZDecimal("1.35").rounded(config: AZDecimalConfig(decimalDigits: 1, roundType: .r55)), AZDecimal("1.4"))
    }

    func test_r65_roundHalfDown() {
        let value = AZDecimal("3.9645601")
        XCTAssertEqual(value.rounded(config: AZDecimalConfig(decimalDigits: 6, roundType: .r65)), AZDecimal("3.96456"))
        XCTAssertEqual(value.rounded(config: AZDecimalConfig(decimalDigits: 5, roundType: .r65)), AZDecimal("3.96456"))
        XCTAssertEqual(value.rounded(config: AZDecimalConfig(decimalDigits: 4, roundType: .r65)), AZDecimal("3.9646"))
        XCTAssertEqual(value.rounded(config: AZDecimalConfig(decimalDigits: 3, roundType: .r65)), AZDecimal("3.964"))
        XCTAssertEqual(value.rounded(config: AZDecimalConfig(decimalDigits: 2, roundType: .r65)), AZDecimal("3.96"))
        XCTAssertEqual(value.rounded(config: AZDecimalConfig(decimalDigits: 1, roundType: .r65)), AZDecimal("4"))
        XCTAssertEqual(value.rounded(config: AZDecimalConfig(decimalDigits: 0, roundType: .r65)), AZDecimal("4"))
    }
}

// MARK: - 書式化

final class FormatTests: XCTestCase {

    func test_trailZero_true() {
        let config = AZDecimalConfig(decimalDigits: 3, roundType: .truncate, trailZero: true, groupType: .none)
        XCTAssertEqual(AZDecimal("3.1").formatted(config: config), "3.100")
    }

    func test_trailZero_false() {
        let config = AZDecimalConfig(decimalDigits: 3, roundType: .truncate, trailZero: false, groupType: .none)
        XCTAssertEqual(AZDecimal("3.1").formatted(config: config), "3.1")
    }

    func test_decimalSeparator_custom() {
        // formatted() は丸めを行わない。decimalDigits を適用するには先に rounded() を呼ぶこと。
        // ここでは小数1桁の値をそのまま渡してセパレータだけを確認する。
        let config = AZDecimalConfig(decimalDigits: 1, decimalSeparator: ":", roundType: .truncate,
                                     trailZero: false, groupType: .none)
        XCTAssertEqual(AZDecimal("100.1").formatted(config: config), "100:1")
    }

    func test_groupSeparator_threes() {
        // 小数2桁の値を渡して桁区切りのみ確認
        let config = AZDecimalConfig(decimalDigits: 2, roundType: .truncate, trailZero: false,
                                     groupType: .threes, groupSeparator: ",")
        XCTAssertEqual(AZDecimal("123456789.01").formatted(config: config), "123,456,789.01")
    }

    func test_groupSeparator_fours() {
        let config = AZDecimalConfig(decimalDigits: 2, roundType: .truncate, trailZero: false,
                                     groupType: .fours, groupSeparator: ";")
        XCTAssertEqual(AZDecimal("123456789.01").formatted(config: config), "1;2345;6789.01")
    }

    func test_groupSeparator_indian() {
        let config = AZDecimalConfig(decimalDigits: 2, roundType: .truncate, trailZero: false,
                                     groupType: .indian, groupSeparator: ",")
        XCTAssertEqual(AZDecimal("123456789.01").formatted(config: config), "12,34,56,789.01")
    }

    func test_roundThenFormat() {
        let value = AZDecimal("123456789.045")

        let base = AZDecimalConfig(decimalDigits: 5, roundType: .r54, trailZero: true,
                                   groupType: .threes, groupSeparator: ",")
        XCTAssertEqual(value.rounded(config: base).formatted(config: base), "123,456,789.04500")

        let d3 = AZDecimalConfig(decimalDigits: 3, roundType: .r54, trailZero: true,
                                 groupType: .threes, groupSeparator: ",")
        XCTAssertEqual(value.rounded(config: d3).formatted(config: d3), "123,456,789.045")

        let d2 = AZDecimalConfig(decimalDigits: 2, roundType: .r54, trailZero: true,
                                 groupType: .threes, groupSeparator: ",")
        XCTAssertEqual(value.rounded(config: d2).formatted(config: d2), "123,456,789.05")

        let d1 = AZDecimalConfig(decimalDigits: 1, roundType: .r54, trailZero: true,
                                 groupType: .threes, groupSeparator: ",")
        XCTAssertEqual(value.rounded(config: d1).formatted(config: d1), "123,456,789.0")

        let d0 = AZDecimalConfig(decimalDigits: 0, roundType: .r54, trailZero: true,
                                 groupType: .threes, groupSeparator: ",")
        XCTAssertEqual(value.rounded(config: d0).formatted(config: d0), "123,456,789")
    }
}
