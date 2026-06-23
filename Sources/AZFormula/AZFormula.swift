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
    /// ゼロ除算
    case zeroDivision
    /// オーバーフロー（精度桁数を超えた）
    case overflow
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
private let opPow  = "^"
private let opPerc = "%"
private let opWari = "割"
private let opBu   = "分"
private let opRi   = "厘"
private let opPtL  = "("
private let opPtR  = ")"

private let allOperators  = [opAdd, opSub, opMul, opMul_, opDiv, opDiv_, opPow]
private let allowedFormulaChars = CharacterSet(charactersIn: "0123456789.-+*/×÷√∛^()%割分厘")

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
    /// アプリ起動時に変更できます（例: `AZFormula.maxFormulaLength = 500`）。
    public static var maxFormulaLength = 200

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
        guard formula.count <= maxFormulaLength else {
            return .failure(.tooLong)
        }

        // 許可文字だけにフィルタ
        let filtered = formula.filter {
            $0.unicodeScalars.allSatisfy { allowedFormulaChars.contains($0) }
        }

        // フィルタ後が空、または数字以外の1文字（単体の演算子など）はエラー
        guard !filtered.isEmpty else { return .failure(.invalidExpression) }
        if filtered.count == 1 {
            guard filtered.first?.isNumber == true else {
                return .failure(.invalidExpression)
            }
            return .success(filtered)
        }

        let tokens: [String]
        switch tokenizeResult(filtered) {
        case .success(let value): tokens = value
        case .failure(let error): return .failure(error)
        }

        let rpn: [String]
        switch toRPNResult(tokens) {
        case .success(let value): rpn = value
        case .failure(let error): return .failure(error)
        }

        switch evalRPN(rpn) {
        case .success(let decimal):
            return .success(decimal.rounded(config).value)
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
        guard formula.count <= maxFormulaLength else {
            return .failure(.tooLong)
        }

        let filtered = formula.filter {
            $0.unicodeScalars.allSatisfy { allowedFormulaChars.contains($0) }
        }

        guard !filtered.isEmpty else { return .failure(.invalidExpression) }
        if filtered.count == 1 {
            guard filtered.first?.isNumber == true else {
                return .failure(.invalidExpression)
            }
            return .success(AZDecimal(filtered))
        }

        let tokens: [String]
        switch tokenizeResult(filtered) {
        case .success(let value): tokens = value
        case .failure(let error): return .failure(error)
        }

        let rpn: [String]
        switch toRPNResult(tokens) {
        case .success(let value): rpn = value
        case .failure(let error): return .failure(error)
        }

        switch evalRPN(rpn) {
        case .success(let decimal):
            return .success(decimal.rounded(config))
        case .failure(let error):
            return .failure(error)
        }
    }

    // MARK: - 公開サブステップ（テスト・拡張用）

    /// 数式文字列をトークン列に分割する。
    public static func tokenize(_ formula: String) -> [String] {
        (try? tokenizeResult(formula).get()) ?? []
    }

    /// 数式文字列を検証しながらトークン列に分割する
    private static func tokenizeResult(_ formula: String) -> Result<[String], AZFormulaError> {
        var tokens: [String] = []
        var current = ""
        var prevToken = ""

        let operators: Set<Character> = Set("+-*/×÷√∛^()%割分厘")
        let signPrev:  Set<Character> = Set("+-*/×÷^(√∛")

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
                guard isNumericToken(current) else {
                    return .failure(.invalidExpression)
                }

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
                        tokens.append(contentsOf: [opMul, opPtL, per, opAdd, current, opPtR, opDiv, per])
                    case opSub:
                        // "100-5%" → "100*(100-5)/100"
                        tokens.removeLast()
                        tokens.append(contentsOf: [opMul, opPtL, per, opSub, current, opPtR, opDiv, per])
                    case opMul, opMul_:
                        // "100*5%" → "100*5/100"
                        tokens.append(contentsOf: [current, opDiv, per])
                    case opDiv, opDiv_:
                        // "100/5%" → "100/5*100"
                        tokens.append(contentsOf: [current, opMul, per])
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
        return .success(tokens)
    }

    /// トークン列を逆ポーランド記法（RPN）に変換する（Shunting Yard アルゴリズム）。
    public static func toRPN(_ tokens: [String]) -> [String] {
        (try? toRPNResult(tokens).get()) ?? []
    }

    /// トークン列を検証しながら逆ポーランド記法へ変換する
    private static func toRPNResult(_ tokens: [String]) -> Result<[String], AZFormulaError> {
        var rpn: [String] = []
        var ope: [String] = []
        var prev: String? = nil

        // 中置二項演算子の優先度（数値が小さいほど高優先）
        let priority: [String: Int] = [
            opPow: 0,
            opMul: 1, opDiv: 1, opMul_: 1, opDiv_: 1,
            opAdd: 2, opSub: 2
        ]
        // 右結合の中置演算子（べき乗）。2^3^2 = 2^(3^2) と解釈する
        let rightAssoc: Set<String> = [opPow]
        // 前置単項演算子（√・∛）は右結合のため priority マップと分離して管理
        // スタック上での優先度は 0（×÷ より高い）とみなしてポップ判定に使う
        let prefixUnary: Set<String> = [opSqrt, opCbrt]
        let prefixUnaryPriority = 0

        for token in tokens {
            // 単項マイナス → "0 - ..."（前置単項演算子の直後も単項とみなす）
            if token == opSub && (prev == nil || priority[prev!] != nil
                                  || prefixUnary.contains(prev!) || prev == opPtL) {
                rpn.append("0")
            }

            if isNumericToken(token) {
                rpn.append(token)
            } else if prefixUnary.contains(token) {
                // 前置単項演算子は右結合：ポップせずそのままスタックへ積む
                ope.append(token)
            } else if let pri = priority[token] {
                // 中置二項演算子：スタック上の高優先演算子を吐き出す
                // 前置単項演算子はスタック上で priority 0 として扱う
                // 右結合演算子は同位（<）でポップせず、左結合は同位以下（<=）でポップする
                let popOnEqual = !rightAssoc.contains(token)
                while let top = ope.last {
                    let topPri = priority[top] ?? (prefixUnary.contains(top) ? prefixUnaryPriority : Int.max)
                    let shouldPop = popOnEqual ? (topPri <= pri) : (topPri < pri)
                    guard shouldPop else { break }
                    rpn.append(ope.removeLast())
                }
                ope.append(token)
            } else if token == opPtL {
                ope.append(token)
            } else if token == opPtR {
                while let top = ope.last, top != opPtL {
                    rpn.append(ope.removeLast())
                }
                guard ope.last == opPtL else {
                    return .failure(.invalidExpression)
                }
                ope.removeLast()
            } else {
                return .failure(.invalidExpression)
            }
            prev = token
        }

        while let op = ope.popLast() {
            guard op != opPtL else {
                return .failure(.invalidExpression)
            }
            rpn.append(op)
        }
        return .success(rpn)
    }

    // MARK: - 内部評価

    /// AZDecimal が受け付ける数値トークンかどうかを判定する。
    /// `Double` 変換では "inf"・"nan"・科学的記数法も通過してしまうため、
    /// 文字種（数字・符号・小数点のみ）で判定する。
    private static func isNumericToken(_ token: String) -> Bool {
        var s = token[...]
        if s.hasPrefix("-") { s = s.dropFirst() }
        guard !s.isEmpty else { return false }
        var dotSeen = false
        var digitSeen = false
        for c in s {
            if c == "." {
                if dotSeen { return false }
                dotSeen = true
            } else if !c.isNumber {
                return false
            } else {
                digitSeen = true
            }
        }
        return digitSeen
    }

    private static func evalRPN(_ tokens: [String]) -> Result<AZDecimal, AZFormulaError> {
        var stack: [AZDecimal] = []

        for token in tokens {
            switch token {
            case opAdd, opSub, opMul, opMul_, opDiv, opDiv_:
                guard 2 <= stack.count else { return .failure(.invalidExpression) }
                let b = stack.removeLast()
                let a = stack.removeLast()
                switch token {
                case opAdd:         stack.append(a + b)
                case opSub:         stack.append(a - b)
                case opMul, opMul_: stack.append(a * b)
                case opDiv, opDiv_:
                    if b.isZero { return .failure(.zeroDivision) }
                    stack.append(a / b)
                default: break
                }

            case opPow:
                guard 2 <= stack.count else { return .failure(.invalidExpression) }
                let b = stack.removeLast()
                let a = stack.removeLast()
                // 指数は整数のみサポート（非整数指数は対数・指数関数が必要なため）
                guard let exp = b.integerValue else { return .failure(.invalidExpression) }
                let r = a.power(exp)
                if r.isNaN { return .failure(.overflow) }
                stack.append(r)

            case opSqrt:
                guard 1 <= stack.count else { return .failure(.invalidExpression) }
                let a = stack.removeLast()
                if a.isNegative { return .failure(.negativeSqrt) }
                stack.append(a.squareRoot())

            case opCbrt:
                guard 1 <= stack.count else { return .failure(.invalidExpression) }
                let a = stack.removeLast()
                stack.append(a.cubeRoot())

            default:
                guard isNumericToken(token) else { return .failure(.invalidExpression) }
                stack.append(AZDecimal(token))
            }
        }

        guard stack.count == 1, let result = stack.first else { return .failure(.invalidExpression) }
        // 演算途中でオーバーフロー等が起きると NaN が伝播する
        if result.isNaN { return .failure(.overflow) }
        return .success(result)
    }
}
