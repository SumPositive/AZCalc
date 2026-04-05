// AZFormulaTests.swift
// AZFormula トークン分割・RPN変換・評価テスト

import XCTest
import AZDecimal
@testable import AZFormula

// MARK: - tokenize

final class TokenizeTests: XCTestCase {

    func test_basicOperators() {
        XCTAssertEqual(AZFormula.tokenize("12+34"), ["12", "+", "34"])
    }

    func test_parenthesesAndMixedOperators() {
        XCTAssertEqual(
            AZFormula.tokenize("(1+2)×3÷4+5*6/7"),
            ["(", "1", "+", "2", ")", "×", "3", "÷", "4", "+", "5", "*", "6", "/", "7"]
        )
    }

    func test_rootSymbol() {
        XCTAssertEqual(AZFormula.tokenize("√25+4"), ["√", "25", "+", "4"])
    }

    func test_unaryMinus_leadingNumber() {
        XCTAssertEqual(AZFormula.tokenize("-20-5"), ["-20", "-", "5"])
    }

    func test_unaryMinus_inParentheses() {
        XCTAssertEqual(AZFormula.tokenize("(20-5)"), ["(", "20", "-", "5", ")"])
    }

    func test_unaryMinus_complex() {
        XCTAssertEqual(
            AZFormula.tokenize("-(20-5)-4×-3÷(-2-1)"),
            ["-", "(", "20", "-", "5", ")", "-", "4", "×", "-3", "÷", "(", "-2", "-", "1", ")"]
        )
    }

    func test_mixedOperatorsWithRoot() {
        XCTAssertEqual(
            AZFormula.tokenize("-100*(20-5)/√4"),
            ["-100", "*", "(", "20", "-", "5", ")", "/", "√", "4"]
        )
    }

    func test_emptyInput() {
        XCTAssertEqual(AZFormula.tokenize(""), [])
    }

    func test_plusNegativeNumber() {
        XCTAssertEqual(AZFormula.tokenize("5+-6"), ["5", "+", "-6"])
    }

    func test_divideNegativeNumber() {
        XCTAssertEqual(AZFormula.tokenize("10/-5"), ["10", "/", "-5"])
    }

    // パーセント系

    func test_percent_add() {
        // "100+5%" → "100×(100+5)÷100"
        XCTAssertEqual(
            AZFormula.tokenize("100+5%"),
            ["100", "×", "(", "100", "+", "5", ")", "÷", "100"]
        )
    }

    func test_percent_sub() {
        // "100-5%" → "100×(100-5)÷100"（カシオ式：5%引き）
        XCTAssertEqual(
            AZFormula.tokenize("100-5%"),
            ["100", "×", "(", "100", "-", "5", ")", "÷", "100"]
        )
    }

    func test_percent_mul() {
        // "100×5%" → "100×5÷100"
        XCTAssertEqual(AZFormula.tokenize("100×5%"), ["100", "×", "5", "÷", "100"])
    }

    func test_percent_div() {
        // "100÷5%" → "100÷5×100"
        XCTAssertEqual(AZFormula.tokenize("100÷5%"), ["100", "÷", "5", "×", "100"])
    }
}

// MARK: - toRPN

final class ToRPNTests: XCTestCase {

    func test_simpleAddition() {
        XCTAssertEqual(AZFormula.toRPN(["2", "+", "3"]), ["2", "3", "+"])
    }

    func test_addAndSubtract() {
        XCTAssertEqual(AZFormula.toRPN(["5", "+", "4", "-", "3"]), ["5", "4", "+", "3", "-"])
    }

    func test_multiplicationPriority() {
        // "+" より "*" が優先される
        XCTAssertEqual(AZFormula.toRPN(["5", "+", "4", "*", "3"]), ["5", "4", "3", "*", "+"])
    }

    func test_parenthesesRemoved() {
        XCTAssertEqual(AZFormula.toRPN(["5", "+", "(", "4", "*", "3", ")"]), ["5", "4", "3", "*", "+"])
    }

    func test_parenthesesOverridePriority() {
        XCTAssertEqual(AZFormula.toRPN(["(", "5", "+", "4", ")", "*", "3"]), ["5", "4", "+", "3", "*"])
    }

    func test_nestedExpression() {
        XCTAssertEqual(AZFormula.toRPN(["2", "+", "(", "3", "*", "4", ")"]), ["2", "3", "4", "*", "+"])
    }

    func test_complexExpression() {
        XCTAssertEqual(
            AZFormula.toRPN(["-3", "+", "4", "*", "-2", "-", "6", "/", "3"]),
            ["-3", "4", "-2", "*", "+", "6", "3", "/", "-"]
        )
    }

    func test_unaryMinus_parentheses() {
        // "-" トークン単体は「0 - ...」に変換
        XCTAssertEqual(
            AZFormula.toRPN(["-", "(", "20", "-", "5", ")"]),
            ["0", "20", "5", "-", "-"]
        )
    }

    func test_percent_add_rpn() {
        XCTAssertEqual(
            AZFormula.toRPN(["100", "×", "(", "100", "+", "5", ")", "÷", "100"]),
            ["100", "100", "5", "+", "×", "100", "÷"]
        )
    }

    func test_percent_mul_rpn() {
        XCTAssertEqual(
            AZFormula.toRPN(["100", "×", "5", "÷", "100"]),
            ["100", "5", "×", "100", "÷"]
        )
    }

    func test_percent_div_rpn() {
        XCTAssertEqual(
            AZFormula.toRPN(["100", "÷", "5", "×", "100"]),
            ["100", "5", "÷", "100", "×"]
        )
    }
}

// MARK: - evaluate（エンドツーエンド）

final class EvaluateTests: XCTestCase {

    private func value(_ formula: String) -> String? {
        if case .success(let s) = AZFormula.evaluate(formula) { return s }
        return nil
    }

    func test_emptyFormula() {
        XCTAssertEqual(value(""), "0")
    }

    func test_simpleAddition() {
        XCTAssertEqual(value("2+3"), "5")
    }

    func test_nestedParentheses() {
        // 2 + (3 * 4) = 14
        XCTAssertEqual(value("2+(3*4)"), "14")
    }

    func test_complexExpression() {
        // -3 + 4×(-2) - 6/3 = -3 - 8 - 2 = -13
        XCTAssertEqual(value("-3+4*-2-6/3"), "-13")
    }

    func test_doubleNegative() {
        // 5 - (-6) = 11
        XCTAssertEqual(value("5--6"), "11")
    }

    func test_leadingNegative_doubleNegative() {
        // -5 - (-6) - 2 = 1 - 2 = -1
        XCTAssertEqual(value("-5--6-2"), "-1")
    }

    func test_unaryMinus_parentheses() {
        // -(20 - 5) = -15
        XCTAssertEqual(value("-(20-5)"), "-15")
    }

    func test_percent_add() {
        // 100 + 5% → 100×(100+5)÷100 = 105
        XCTAssertEqual(value("100+5%"), "105")
    }

    func test_percent_sub() {
        // 100 - 5% → 100×(100-5)÷100 = 95（カシオ式：5%引き）
        XCTAssertEqual(value("100-5%"), "95")
    }

    func test_percent_mul() {
        // 100 × 5% = 5
        XCTAssertEqual(value("100×5%"), "5")
    }

    func test_percent_div() {
        // 100 ÷ 5% = 2000
        XCTAssertEqual(value("100÷5%"), "2000")
    }

    func test_sqrt() {
        XCTAssertEqual(value("√25"), "5.0")
    }

    func test_sqrt_negative_returnsError() {
        // "√-4" はトークン分割で ["√", "-", "4"] になりスタック不足で invalidExpression になる。
        // "√(0-1)" は正しく -1 をスタックに積んで negativeSqrt を返す。
        guard case .failure(let e) = AZFormula.evaluate("√(0-1)") else {
            XCTFail("Expected negativeSqrt error"); return
        }
        XCTAssertEqual(e, .negativeSqrt)
    }

    func test_tooLong_returnsError() {
        let longFormula = String(repeating: "1", count: 201)
        guard case .failure(let e) = AZFormula.evaluate(longFormula) else {
            XCTFail("Expected tooLong error"); return
        }
        XCTAssertEqual(e, .tooLong)
    }

    func test_invalidCharacters_filtered() {
        // "1a+2$" の無効文字は除去されて "1+2" と同じ結果になる
        XCTAssertEqual(value("1a+2$"), value("1+2"))
    }
}

// MARK: - evaluateDecimal

final class EvaluateDecimalTests: XCTestCase {

    func test_evaluateDecimal_returnsAZDecimal() {
        guard case .success(let result) = AZFormula.evaluateDecimal("1+2") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(result, AZDecimal("3"))
    }

    func test_evaluateDecimal_emptyReturnsZero() {
        guard case .success(let result) = AZFormula.evaluateDecimal("") else {
            XCTFail("Expected success"); return
        }
        XCTAssertTrue(result.isZero)
    }

    func test_evaluateDecimal_withConfig() {
        let config = AZDecimalConfig.default.digits(2).rounding(.r54)
        guard case .success(let result) = AZFormula.evaluateDecimal("1÷3", config: config) else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(result, AZDecimal("0.33"))
    }

    func test_evaluateDecimal_errorPropagates() {
        guard case .failure(let e) = AZFormula.evaluateDecimal("√(0-1)") else {
            XCTFail("Expected failure"); return
        }
        XCTAssertEqual(e, .negativeSqrt)
    }

    func test_evaluateDecimal_enablesFurtherArithmetic() {
        // evaluateDecimal を使えば結果をさらに演算できる
        guard case .success(let a) = AZFormula.evaluateDecimal("10+5"),
              case .success(let b) = AZFormula.evaluateDecimal("2+1") else {
            XCTFail("Expected success"); return
        }
        XCTAssertEqual(a * b, AZDecimal("45"))
    }

    func test_maxFormulaLength_isPublic() {
        XCTAssertEqual(AZFormula.maxFormulaLength, 200)
        // 200文字はギリギリ有効
        let justRight = String(repeating: "1", count: 199) // 199桁の数値は1トークン
        XCTAssertNotNil(try? AZFormula.evaluate(justRight).get())
        // 201文字は tooLong
        guard case .failure(let e) = AZFormula.evaluate(String(repeating: "1", count: 201)) else {
            XCTFail("Expected tooLong"); return
        }
        XCTAssertEqual(e, .tooLong)
    }
}
