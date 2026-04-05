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

### Rounding

```swift
var config = AZDecimalConfig()
config.decimalDigits = 2
config.roundType = .r54   // 四捨五入

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

```swift
var config = AZDecimalConfig()
config.decimalDigits  = 2
config.roundType      = .r54
config.trailZero      = true       // pad to 2 decimal places
config.groupType      = .threes    // 3-digit grouping
config.groupSeparator = ","
config.decimalSeparator = "."

let value = AZDecimal("1234567.045")
print(value.rounded(config: config).formatted(config: config))
// "1,234,567.05"
```

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
case .success(let value): print(value)  // "0.333333..."
case .failure(let error): print(error)
}
```

### With rounding config

```swift
var config = AZDecimalConfig()
config.decimalDigits = 2
config.roundType = .r54

let result = AZFormula.evaluate("1 ÷ 3", config: config)
// → .success("0.33")
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
    case tooLong          // formula exceeds 200 characters
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
│   ├── AZDecimalTests/      ← 39 tests
│   └── AZFormulaTests/      ← 28 tests
└── Demo/
    └── AZCalcDemo.xcodeproj ← SwiftUI demo app (iOS 17+)
```

Open `Demo/AZCalcDemo.xcodeproj` in Xcode to run the interactive demo.

## License

MIT License. See [LICENSE](LICENSE) for details.
