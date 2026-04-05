// AZFormula.swift
// 数式パースと評価エンジン
//
// Originally created by MSPO/azukid on 2010/03/15
// Converted from Objective-C by sumpo/azukid on 2025/07/02
// Refactored as AZFormula Swift Package by sumpo/azukid on 2026/04/05

import Foundation
import AZDecimal

// MARK: - エラー型

/// AZFormula の評価エラー
public enum AZFormulaError: Error, Sendable {
    /// 式が長すぎる（200文字超）
    case tooLong
    /// 負の数の平方根
    case negativeSqrt
    /// 評価できない式
    case invalidExpression
}

// MARK: - 演算子定数（内部）

private let opAdd  = "+"
private let opSub  = "-"
private let opMul  = "×"
private let opMul_ = "*"
private let opDiv  = "÷"
private let opDiv_ = "/"
private let opSqrt = "√"
private let opCbrt = "∛"
private let opPerc = "%"
private let opWari = "割"
private let opBu   = "分"
private let opRi   = "厘"
private let opPtL  = "("
private let opPtR  = ")"
private let opDot  = "."

private let allOperators  = [opAdd, opSub, opMul, opMul_, opDiv, opDiv_]
private let formulaLength = AZFormula.maxFormulaLength
private let allowedFormulaChars = CharacterSet(charactersIn: "0123456789.-+*/×÷√∛()%割分厘")

// MARK: - AZFormula

/// 数式の文字列評価エンジン。
///
/// ```swift
/// // 基本的な使い方
/// let result = AZFormula.evaluate("(100 + 5%) × 1.08")
/// // → .success("113.4")
///
/// // 設定をカスタマイズ
/// var config = AZDecimalConfig()
/// config.decimalDigits = 2
/// config.roundType = .r54
/// let result = AZFormula.evaluate("1 ÷ 3", config: config)
/// // → .success("0.33")
/// ```
public enum AZFormula {

    /// 評価可能な数式の最大文字数。これを超えると `.tooLong` エラーを返します。
    public static let maxFormulaLength = 200

    // MARK: - 公開 API

    /// 数式文字列を評価して結果を返す。
    ///
    /// - Parameters:
    ///   - formula: 評価する数式
    ///   - config: 丸め・書式設定（省略時は `AZDecimalConfig.default`）
    /// - Returns: 成功時は丸め済み結果文字列、失敗時はエラー
    public static func evaluate(
        _ formula: String,
        config: AZDecimalConfig = .default
    ) -> Result<String, AZFormulaError> {
        guard !formula.isEmpty else {
            return .success("0")
        }
        guard formula.count < formulaLength else {
            return .failure(.tooLong)
        }

        // 許可文字だけにフィルタ
        let filtered = formula.filter {
            $0.unicodeScalars.allSatisfy { allowedFormulaChars.contains($0) }
        }

        // 1文字（単体の数値）はそのまま返す
        if filtered.count <= 1 { return .success(filtered) }

        let tokens = tokenize(filtered)
        let rpn    = toRPN(tokens)

        switch evalRPN(rpn) {
        case .success(let decimal):
            return .success(decimal.rounded(config: config).value)
        case .failure(let error):
            return .failure(error)
        }
    }

    /// 数式文字列を評価して `AZDecimal` を返す。
    ///
    /// `evaluate(_:config:)` と同じ処理を行いますが、文字列ではなく `AZDecimal` を返します。
    /// フォーマットや追加の演算が必要な場合に使用してください。
    ///
    /// - Parameters:
    ///   - formula: 評価する数式
    ///   - config: 丸め設定（省略時は `AZDecimalConfig.default`）
    /// - Returns: 成功時は丸め済み `AZDecimal`、失敗時はエラー
    public static func evaluateDecimal(
        _ formula: String,
        config: AZDecimalConfig = .default
    ) -> Result<AZDecimal, AZFormulaError> {
        guard !formula.isEmpty else {
            return .success(.zero)
        }
        guard formula.count < formulaLength else {
            return .failure(.tooLong)
        }

        let filtered = formula.filter {
            $0.unicodeScalars.allSatisfy { allowedFormulaChars.contains($0) }
        }

        if filtered.count <= 1 { return .success(AZDecimal(filtered)) }

        let tokens = tokenize(filtered)
        let rpn    = toRPN(tokens)

        switch evalRPN(rpn) {
        case .success(let decimal):
            return .success(decimal.rounded(config: config))
        case .failure(let error):
            return .failure(error)
        }
    }

    // MARK: - 公開サブステップ（テスト・拡張用）

    /// 数式文字列をトークン列に分割する。
    public static func tokenize(_ formula: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var prevToken = ""

        let operators: Set<Character> = Set("+-*/×÷√∛()%割分厘")
        let signPrev:  Set<Character> = Set("+-*/×÷(")

        for (index, char) in formula.enumerated() {
            guard operators.contains(char) else {
                current.append(char)
                prevToken = ""
                continue
            }

            // マイナス記号の符号 vs 演算子判定
            if char == Character(opSub) {
                if index == 0 || (prevToken.last.map { signPrev.contains($0) } ?? false) {
                    current.append(char)
                    continue
                }
            }

            // パーセント系（%・割・分・厘）
            if char == Character(opPerc) || char == Character(opWari)
                || char == Character(opBu) || char == Character(opRi) {

                let per: String
                switch char {
                case Character(opWari): per = "10"
                case Character(opPerc), Character(opBu): per = "100"
                case Character(opRi): per = "1000"
                default: per = "1"
                }

                if tokens.isEmpty || !allOperators.contains(tokens.last ?? "") {
                    // "5%" → "5 / 100"
                    tokens.append(current); tokens.append(opDiv); tokens.append(per)
                } else if tokens.count >= 2 {
                    switch tokens.last {
                    case opAdd:
                        // "100+5%" → "100*(100+5)/100"
                        tokens.removeLast()
                        tokens += [opMul, opPtL, per, opAdd, current, opPtR, opDiv, per]
                    case opSub:
                        // "100-5%" → "100*(100-5)/100"
                        tokens.removeLast()
                        tokens += [opMul, opPtL, per, opSub, current, opPtR, opDiv, per]
                    case opMul, opMul_:
                        // "100*5%" → "100*5/100"
                        tokens += [current, opDiv, per]
                    case opDiv, opDiv_:
                        // "100/5%" → "100/5*100"
                        tokens += [current, opMul, per]
                    default:
                        tokens.append(current); tokens.append(opDiv); tokens.append(per)
                    }
                } else {
                    tokens.append(current); tokens.append(opDiv); tokens.append(per)
                }
                prevToken = ""; current = ""
                continue
            }

            // 通常の演算子
            if !current.isEmpty {
                tokens.append(current)
                prevToken = current
                current = ""
            }
            tokens.append(String(char))
            prevToken = String(char)
        }

        if !current.isEmpty { tokens.append(current) }
        return tokens
    }

    /// トークン列を逆ポーランド記法（RPN）に変換する（Shunting Yard アルゴリズム）。
    public static func toRPN(_ tokens: [String]) -> [String] {
        var rpn: [String] = []
        var ope: [String] = []
        var prev: String? = nil

        let priority: [String: Int] = [
            opSqrt: 0, opCbrt: 0,
            opMul: 1, opDiv: 1, opMul_: 1, opDiv_: 1,
            opAdd: 2, opSub: 2
        ]

        for token in tokens {
            // 単項マイナス → "0 - ..."
            if token == opSub && (prev == nil || priority[prev!] != nil || prev == opPtL) {
                rpn.append("0")
            }

            if Double(token) != nil {
                rpn.append(token)
            } else if let pri = priority[token] {
                while let top = ope.last, let topPri = priority[top], topPri <= pri {
                    rpn.append(ope.removeLast())
                }
                ope.append(token)
            } else if token == opPtL {
                ope.append(token)
            } else if token == opPtR {
                while let top = ope.last, top != opPtL {
                    rpn.append(ope.removeLast())
                }
                if ope.last == opPtL { ope.removeLast() }
            } else {
                rpn.append(token)
            }
            prev = token
        }

        while let op = ope.popLast() { rpn.append(op) }
        return rpn
    }

    // MARK: - 内部評価

    private static func evalRPN(_ tokens: [String]) -> Result<AZDecimal, AZFormulaError> {
        var stack: [AZDecimal] = []

        for token in tokens {
            switch token {
            case opAdd, opSub, opMul, opMul_, opDiv, opDiv_:
                guard stack.count >= 2 else { return .failure(.invalidExpression) }
                let b = stack.removeLast()
                let a = stack.removeLast()
                switch token {
                case opAdd:         stack.append(a + b)
                case opSub:         stack.append(a - b)
                case opMul, opMul_: stack.append(a * b)
                case opDiv, opDiv_: stack.append(a / b)
                default: break
                }

            case opSqrt:
                guard stack.count >= 1 else { return .failure(.invalidExpression) }
                let a = stack.removeLast()
                let v = Double(a.value) ?? 0
                if v < 0 { return .failure(.negativeSqrt) }
                stack.append(AZDecimal(String(sqrt(v))))

            case opCbrt:
                guard stack.count >= 1 else { return .failure(.invalidExpression) }
                let a = stack.removeLast()
                let v = Double(a.value) ?? 0
                let cbrt = v < 0 ? -pow(-v, 1.0 / 3.0) : pow(v, 1.0 / 3.0)
                stack.append(AZDecimal(String(cbrt)))

            default:
                stack.append(AZDecimal(token))
            }
        }

        guard let result = stack.first else { return .failure(.invalidExpression) }
        return .success(result)
    }
}
