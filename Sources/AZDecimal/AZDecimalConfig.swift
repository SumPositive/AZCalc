// AZDecimalConfig.swift
// AZDecimal の書式・丸め設定

/// AZDecimal の書式・丸め設定。
///
/// `Sendable` な値型なので、スレッドをまたいで安全に渡せます。
public struct AZDecimalConfig: Sendable {

    // MARK: - 丸め

    /// 丸めタイプ
    public enum RoundType: Int, Sendable {
        case rup      = 0  // 切り上げ（絶対値型）
        case rPlus    = 1  // 正方向丸め
        case r54      = 2  // 四捨五入
        case r55      = 3  // 五捨五超入（偶数丸め・銀行家の丸め）
        case r65      = 4  // 五捨六入
        case rMinus   = 5  // 負方向丸め
        case truncate = 6  // 切り捨て（丸めない）
    }

    /// 小数桁数（丸め後の表示桁数）
    public var decimalDigits: Int

    /// 小数点記号（例: `"."` / `"，"`）
    public var decimalSeparator: String

    /// 丸めタイプ
    public var roundType: RoundType

    /// `true` = 末尾ゼロ補充 / `false` = 末尾ゼロ削除
    public var trailZero: Bool

    // MARK: - 桁区切り

    /// 桁区切りタイプ
    public enum GroupType: Int, Sendable {
        case none   = 0  // なし
        case threes = 1  // 3桁区切り（1,234,567）
        case fours  = 2  // 4桁区切り（1234,5678）
        case indian = 3  // インド式（12,34,56,789）
    }

    /// 桁区切りタイプ
    public var groupType: GroupType

    /// 桁区切り記号（例: `","` / `"，"`）
    public var groupSeparator: String

    // MARK: - Init

    public init(
        decimalDigits: Int = 3,
        decimalSeparator: String = ".",
        roundType: RoundType = .r54,
        trailZero: Bool = false,
        groupType: GroupType = .threes,
        groupSeparator: String = ","
    ) {
        self.decimalDigits = decimalDigits
        self.decimalSeparator = decimalSeparator
        self.roundType = roundType
        self.trailZero = trailZero
        self.groupType = groupType
        self.groupSeparator = groupSeparator
    }

    /// デフォルト設定（小数3桁・四捨五入・3桁区切り）
    public static let `default` = AZDecimalConfig()

    // MARK: - フルエントモディファイア

    /// 小数桁数を設定して返す。
    public func digits(_ n: Int) -> AZDecimalConfig {
        var c = self; c.decimalDigits = n; return c
    }

    /// 丸めタイプを設定して返す。
    public func rounding(_ type: RoundType) -> AZDecimalConfig {
        var c = self; c.roundType = type; return c
    }

    /// 末尾ゼロ補充を設定して返す。
    public func trailingZero(_ enabled: Bool) -> AZDecimalConfig {
        var c = self; c.trailZero = enabled; return c
    }

    /// 桁区切りを設定して返す。
    public func grouping(_ type: GroupType, separator: String = ",") -> AZDecimalConfig {
        var c = self; c.groupType = type; c.groupSeparator = separator; return c
    }

    /// 小数点記号を設定して返す。
    public func decimalSep(_ separator: String) -> AZDecimalConfig {
        var c = self; c.decimalSeparator = separator; return c
    }
}
