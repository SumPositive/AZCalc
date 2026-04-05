# AZCalc

BCD decimal arithmetic and formula evaluation for Swift.

![Platforms](https://img.shields.io/badge/platforms-iOS%2016%20%7C%20macOS%2013-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/license-MIT-green)

Two products in one package:

| Product | Description |
|---|---|
| **AZDecimal** | Signed BCD decimal arithmetic — 60-digit precision, 7 rounding modes |
| **AZFormula** | Formula string evaluator — parses and evaluates infix expressions |

---

## AZDecimal

Floating-point-free arithmetic using Binary Coded Decimal (BCD).
Up to 30 integer digits + 30 decimal digits (60 digits total).

### Basic usage

```swift
import AZDecimal

let a: AZDecimal = "1.1"
let b: AZDecimal = "2.0456"
print(a + b)   // "3.1456"
print(a - b)   // "-0.9456"
print(a * b)   // "2.25016"
print(a / b)   // "0.537815..."
```

### Convenience API

```swift
AZDecimal.zero          // AZDecimal("0")
AZDecimal.one           // AZDecimal("1")

let x: AZDecimal = "-3.14"
x.isZero                // false
x.isNegative            // true
x.abs                   // AZDecimal("3.14")

var a: AZDecimal = "10"
a += "3"   // 13
a -= "5"   // 8
a *= "2"   // 16
a /= "4"   // 4
```

### Rounding

```swift
let config = AZDecimalConfig(decimalDigits: 2, roundType: .r54)
let result = AZDecimal("3.456").rounded(config: config)
print(result)  // "3.46"
```

### Rounding modes

| Mode | Name | Description |
|---|---|---|
| `.rup` | 切り上げ | Round away from zero |
| `.rPlus` | 正方向丸め | Round toward +∞ |
| `.r54` | 四捨五入 | Round half up [JIS Z 8401 Rule B] |
| `.r55` | 五捨五超入 | Round half to even [JIS Z 8401 Rule A] |
| `.r65` | 五捨六入 | Round half down |
| `.rMinus` | 負方向丸め | Round toward −∞ |
| `.truncate` | 切り捨て | No rounding — return raw value |

### Formatting

`formatted(config:)` applies grouping separators, decimal separator, and trailing-zero padding.
It also truncates the decimal part to `decimalDigits`. Call `rounded(config:)` first for precise rounding.

```swift
let config = AZDecimalConfig.default
    .digits(2)
    .rounding(.r54)
    .trailingZero(true)
    .grouping(.threes)

let value = AZDecimal("1234567.045")
print(value.rounded(config: config).formatted(config: config))
// "1,234,567.05"
```

### Fluent configuration

`AZDecimalConfig` supports method chaining. The default config uses `.r54`, 3 decimal digits, 3-digit grouping, no trailing zeros.

```swift
// verbose style
var config = AZDecimalConfig()
config.decimalDigits = 2
config.roundType = .r54

// fluent style (equivalent)
let config = AZDecimalConfig.default.digits(2).rounding(.r54)
```

| Method | Description |
|---|---|
| `.digits(_ n: Int)` | Set decimal digits |
| `.rounding(_ type: RoundType)` | Set rounding mode |
| `.trailingZero(_ enabled: Bool)` | Pad / strip trailing zeros |
| `.grouping(_ type: GroupType, separator: String)` | Set digit grouping |
| `.decimalSep(_ separator: String)` | Set decimal separator |

### Grouping types

| Type | Example |
|---|---|
| `.none` | `1234567` |
| `.threes` | `1,234,567` |
| `.fours` | `123,4567` |
| `.indian` | `12,34,567` |

---

## AZFormula

Evaluates infix formula strings using the Shunting Yard algorithm.

### Basic usage

```swift
import AZFormula

let result = AZFormula.evaluate("(100 + 5%) × 1.08")
// → .success("113.4")

switch AZFormula.evaluate("1 ÷ 3") {
case .success(let value): print(value)  // "0.333"  (default: .r54, 3 digits)
case .failure(let error): print(error)
}
```

### With rounding config

```swift
let config = AZDecimalConfig.default.digits(2).rounding(.r54)

let result = AZFormula.evaluate("1 ÷ 3", config: config)
// → .success("0.33")
```

### evaluateDecimal — returns AZDecimal

When you need to perform further arithmetic on the result:

```swift
if case .success(let a) = AZFormula.evaluateDecimal("10+5"),
   case .success(let b) = AZFormula.evaluateDecimal("2+1") {
    print(a * b)  // AZDecimal("45")
}
```

### Supported operators

| Operator | Description |
|---|---|
| `+` `-` `×` `÷` | Basic arithmetic (`*` `/` also accepted) |
| `√` | Square root |
| `∛` | Cube root |
| `( )` | Parentheses |
| `%` | Percent — context-sensitive (see below) |
| `割` `分` `厘` | Japanese percent notation |

### Percent operator behavior

| Expression | Expands to | Result |
|---|---|---|
| `100+5%` | `100×(100+5)÷100` | `105` |
| `100-5%` | `100×(100-5)÷100` | `95` |
| `100×5%` | `100×5÷100` | `5` |
| `100÷5%` | `100÷5×100` | `2000` |

### Error cases

```swift
public enum AZFormulaError: Error {
    case tooLong          // formula exceeds AZFormula.maxFormulaLength (200) characters
    case negativeSqrt     // √ applied to a negative number
    case invalidExpression
}
```

### Sub-step API (for testing / custom pipelines)

```swift
let tokens = AZFormula.tokenize("100+5%")
// ["100", "×", "(", "100", "+", "5", ")", "÷", "100"]

let rpn = AZFormula.toRPN(tokens)
// ["100", "100", "5", "+", "×", "100", "÷"]
```

---

## Installation

### Swift Package Manager

In Xcode: **File → Add Package Dependencies**

```
https://github.com/SumPositive/AZCalc
```

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/SumPositive/AZCalc", from: "1.0.0")
]
```

Add products to your target:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "AZDecimal", package: "AZCalc"),
        .product(name: "AZFormula", package: "AZCalc"),
    ]
)
```

## Requirements

- iOS 16.0+ / macOS 13.0+
- Swift 5.9+
- Xcode 15+

---

## Development

```
AZCalc/
├── Package.swift
├── Sources/
│   ├── AZDecimalC/          ← BCD arithmetic core (C++)
│   ├── AZDecimal/           ← Swift API
│   └── AZFormula/           ← Formula engine
├── Tests/
│   ├── AZDecimalTests/      ← 43 tests (arithmetic, rounding, comparable, convenience, format)
│   └── AZFormulaTests/      ← 34 tests (tokenize, RPN, evaluate, evaluateDecimal)
└── Demo/
    └── AZCalcDemo.xcodeproj ← SwiftUI demo app (iOS 17+)
```

Open `AZCalc.xcworkspace` in Xcode to run both package tests and demo app tests together.

## License

MIT License. See [LICENSE](LICENSE) for details.
