// AZDecimal.swift
// 符号付き BCD 十進演算
//
// Originally created by MSPO/azukid on 1998/09/15 (C/C++)
// Converted to Swift6 by sumpo/azukid on 2025/07/10
// Refactored as AZDecimal Swift Package by sumpo/azukid on 2026/04/05

import Foundation
import AZDecimalC

/// 符号付き BCD（Binary Coded Decimal）十進演算型。
///
/// 浮動小数点誤差のない高精度計算を提供します。
/// 整数部・小数部それぞれ最大 30 桁（合計 60 桁）の精度を持ちます。
///
/// ```swift
/// let a: AZDecimal = "1.23"
/// let b: AZDecimal = "4.56"
/// print(a + b)  // "5.79"
/// ```
public struct AZDecimal: Sendable {

    /// BCD 演算精度（整数部 + 小数部の合計桁数）。C ヘッダの `SBCD_PRECISION` と同値。
    public static let precision = Int(SBCD_PRECISION)

    /// ゼロ値
    public static let zero = AZDecimal("0")

    /// 一値
    public static let one = AZDecimal("1")

    private static let minusChar   = "-"
    private static let dotChar     = "."
    private static let allowedChars = CharacterSet(charactersIn: "0123456789.-")

    private static let bufSize = Int(SBCD_STRING_BUFFER_SIZE)

    /// 内部文字列（`"-"`, `"."`, `"0"–"9"` のみで構成）
    public private(set) var value: String

    // MARK: - Init

    /// 文字列から初期化。許可外の文字は除去します。
    public init(_ num: String) {
        let filtered = num.filter { $0.unicodeScalars.allSatisfy { AZDecimal.allowedChars.contains($0) } }
        self.value = AZDecimal.normalizedValue(filtered)
    }

    /// C 層の演算結果から初期化。正規化をスキップし "-0" 番兵を保持する。
    private init(cResult: String) {
        self.value = cResult
    }

    /// C コアと比較処理に渡せる数値文字列へ正規化する
    private static func normalizedValue(_ num: String) -> String {
        var source = num
        var isNegative = false

        // 先頭以外のマイナスは符号として扱わない
        if source.hasPrefix(minusChar) {
            isNegative = true
            source.removeFirst()
        }

        let parts = source.split(separator: Character(dotChar), maxSplits: 1, omittingEmptySubsequences: false)
        var intPart = parts.first.map(String.init) ?? ""
        var decPart = 1 < parts.count ? String(parts[1]) : ""

        // 数字以外は取り除き、複数ドット以降の文字も安全に畳み込む
        intPart = intPart.filter(\.isNumber)
        decPart = decPart.filter(\.isNumber)

        // 整数部の先頭ゼロを除去して比較と等価性を安定させる
        while 1 < intPart.count && intPart.first == "0" {
            intPart.removeFirst()
        }
        if intPart.isEmpty {
            intPart = "0"
        }

        // 小数部の末尾ゼロを除去して数値同値を同じ表現にする
        while decPart.last == "0" {
            decPart.removeLast()
        }

        let isZero = intPart == "0" && decPart.isEmpty
        let sign = isNegative && !isZero ? minusChar : ""
        return decPart.isEmpty ? sign + intPart : sign + intPart + dotChar + decPart
    }

    // MARK: - 四則演算メソッド

    public func adding(_ other: AZDecimal) -> AZDecimal {
        var ans = [CChar](repeating: 0, count: Self.bufSize)
        sbcd_add(&ans, value, other.value)
        return AZDecimal(cResult: String(cString: ans))
    }

    public func subtracting(_ other: AZDecimal) -> AZDecimal {
        var ans = [CChar](repeating: 0, count: Self.bufSize)
        sbcd_sub(&ans, value, other.value)
        return AZDecimal(cResult: String(cString: ans))
    }

    public func multiplied(by other: AZDecimal) -> AZDecimal {
        var ans = [CChar](repeating: 0, count: Self.bufSize)
        sbcd_mul(&ans, value, other.value)
        return AZDecimal(cResult: String(cString: ans))
    }

    public func divided(by other: AZDecimal) -> AZDecimal {
        var ans = [CChar](repeating: 0, count: Self.bufSize)
        sbcd_div(&ans, value, other.value)
        return AZDecimal(cResult: String(cString: ans))
    }

    // MARK: - プロパティ

    /// ゼロかどうか
    public var isZero: Bool { value == "0" || value == "-0" }

    /// 負の値かどうか
    public var isNegative: Bool { value.hasPrefix(AZDecimal.minusChar) && !isZero }

    /// 絶対値
    public var abs: AZDecimal {
        isNegative ? AZDecimal(String(value.dropFirst())) : self
    }

    // MARK: - 平方根・立方根

    /// ニュートン法の反復回数。Double 初期値（~15桁）から SBCD_PRECISION 桁に到達するまでの回数。
    /// 1回ごとに有効桁数が2倍になるため ceil(log2(precision/15)) + 安全マージン2。
    private static let newtonIterations: Int = max(4, Int(ceil(log2(Double(precision) / 15.0))) + 2)

    /// 平方根を返す。負の値を渡してはならない。
    public func squareRoot() -> AZDecimal {
        precondition(!isNegative, "squareRoot() called on a negative value: \(value)")
        if isZero { return .zero }
        let initial = Foundation.sqrt(Double(value) ?? 1.0)
        var x = AZDecimal(String(initial))
        let two: AZDecimal = "2"
        for _ in 0..<AZDecimal.newtonIterations {
            x = (x + self / x) / two
        }
        return x
    }

    /// 立方根を返す。負の値にも対応。
    public func cubeRoot() -> AZDecimal {
        let negative = isNegative
        let a = negative ? self.abs : self
        if a.isZero { return .zero }
        let initial = Foundation.pow(Double(a.value) ?? 1.0, 1.0 / 3.0)
        var x = AZDecimal(String(initial))
        let two: AZDecimal = "2"
        let three: AZDecimal = "3"
        for _ in 0..<AZDecimal.newtonIterations {
            x = (two * x + a / (x * x)) / three
        }
        return negative ? AZDecimal(AZDecimal.minusChar + x.value) : x
    }

    // MARK: - 演算子

    public static func + (lhs: AZDecimal, rhs: AZDecimal) -> AZDecimal { lhs.adding(rhs) }
    public static func - (lhs: AZDecimal, rhs: AZDecimal) -> AZDecimal { lhs.subtracting(rhs) }
    public static func * (lhs: AZDecimal, rhs: AZDecimal) -> AZDecimal { lhs.multiplied(by: rhs) }
    public static func / (lhs: AZDecimal, rhs: AZDecimal) -> AZDecimal { lhs.divided(by: rhs) }

    public static func += (lhs: inout AZDecimal, rhs: AZDecimal) { lhs = lhs + rhs }
    public static func -= (lhs: inout AZDecimal, rhs: AZDecimal) { lhs = lhs - rhs }
    public static func *= (lhs: inout AZDecimal, rhs: AZDecimal) { lhs = lhs * rhs }
    public static func /= (lhs: inout AZDecimal, rhs: AZDecimal) { lhs = lhs / rhs }

    // MARK: - 丸め・書式化

    /// 設定に従い丸めた値を返す。
    public func rounded(_ config: AZDecimalConfig = .default) -> AZDecimal {
        var ans = [CChar](repeating: 0, count: Self.bufSize)
        sbcd_round(&ans, value, Int32(config.decimalDigits), Int32(config.roundType.rawValue))
        return AZDecimal(cResult: String(cString: ans))
    }

    /// 設定に従い桁区切り・小数記号を付けた文字列を返す。
    /// 丸めは行いません。先に `rounded(_:)` を呼んでください。
    public func formatted(_ config: AZDecimalConfig = .default) -> String {
        var val = self.value

        // マイナス記号を分離
        var minus = false
        if val.hasPrefix(AZDecimal.minusChar) {
            minus = true
            val.removeFirst()
        }

        // 整数部・小数部に分割
        let parts = val.split(separator: Character(AZDecimal.dotChar), omittingEmptySubsequences: false)
        var intPart = parts.count > 0 ? String(parts[0]) : "0"
        var decPart = parts.count > 1 ? String(parts[1]) : ""

        // 桁区切り
        let chars = Array(intPart)
        switch config.groupType {
        case .threes, .fours:
            let size = config.groupType == .threes ? 3 : 4
            let rev = chars.reversed()
            var result = ""
            for (i, c) in rev.enumerated() {
                if i > 0 && i % size == 0 { result.append(contentsOf: config.groupSeparator) }
                result.append(c)
            }
            intPart = String(result.reversed())
        case .indian:
            let last3 = chars.suffix(3)
            if chars.count > 3 {
                let rev = chars.dropLast(3).reversed()
                var result = ""
                for (i, c) in rev.enumerated() {
                    if i > 0 && i % 2 == 0 { result.append(contentsOf: config.groupSeparator) }
                    result.append(c)
                }
                intPart = String(result.reversed()) + config.groupSeparator + String(last3)
            } else {
                intPart = String(last3)
            }
        case .none:
            break
        }

        // 小数部を decimalDigits に切り詰め
        if decPart.count > config.decimalDigits {
            decPart = String(decPart.prefix(config.decimalDigits))
        }

        // 末尾ゼロ
        if config.trailZero {
            if decPart.count < config.decimalDigits {
                decPart = decPart.padding(toLength: config.decimalDigits, withPad: "0", startingAt: 0)
            }
        } else if !decPart.isEmpty {
            while decPart.last == "0" { decPart.removeLast() }
        }

        // 組み立て
        var result = intPart
        if !decPart.isEmpty {
            result += config.decimalSeparator + decPart
        }
        return minus ? AZDecimal.minusChar + result : result
    }
}

// MARK: - プロトコル適合

extension AZDecimal: Equatable {
    public static func == (lhs: AZDecimal, rhs: AZDecimal) -> Bool {
        lhs.value == rhs.value
    }
}

extension AZDecimal: Comparable {
    public static func < (lhs: AZDecimal, rhs: AZDecimal) -> Bool {
        let lNeg = lhs.value.hasPrefix(AZDecimal.minusChar)
        let rNeg = rhs.value.hasPrefix(AZDecimal.minusChar)

        // 符号が異なる場合
        if lNeg != rNeg { return lNeg }

        // 符号が同じ場合は絶対値で比較（負なら結果反転）
        let lAbs = lNeg ? String(lhs.value.dropFirst()) : lhs.value
        let rAbs = lNeg ? String(rhs.value.dropFirst()) : rhs.value

        let lParts = lAbs.split(separator: Character(AZDecimal.dotChar), omittingEmptySubsequences: false)
        let rParts = rAbs.split(separator: Character(AZDecimal.dotChar), omittingEmptySubsequences: false)
        let lInt = String(lParts[0])
        let rInt = String(rParts[0])

        // 整数部の桁数で比較
        if lInt.count != rInt.count {
            let absLess = lInt.count < rInt.count
            return lNeg ? !absLess : absLess
        }
        // 同桁数なら辞書順（ASCII数字なので有効）
        if lInt != rInt {
            let absLess = lInt < rInt
            return lNeg ? !absLess : absLess
        }
        // 整数部が等しければ小数部を比較
        let lDec = lParts.count > 1 ? String(lParts[1]) : ""
        let rDec = rParts.count > 1 ? String(rParts[1]) : ""
        // 短い方をゼロ埋めして比較
        let maxLen = max(lDec.count, rDec.count)
        let lPad = lDec.padding(toLength: maxLen, withPad: "0", startingAt: 0)
        let rPad = rDec.padding(toLength: maxLen, withPad: "0", startingAt: 0)
        let absLess = lPad < rPad
        return lNeg ? !absLess : absLess
    }
}

extension AZDecimal: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) { self.init(value) }
}

extension AZDecimal: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) { self.init(String(value)) }
}

extension AZDecimal: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        guard value.isFinite else { self.init("0"); return }
        // String(Double) は極端な値で科学的記数法("1e-20"など)を生成する。
        // allowedChars フィルタが 'e' を除去すると全く別の値になるため、
        // Decimal を経由して平叙記法("0.00000000000000000001")に変換する。
        let plain = Decimal(string: String(value))?.description ?? "0"
        self.init(plain)
    }
}

extension AZDecimal: CustomStringConvertible {
    public var description: String { value }
}
