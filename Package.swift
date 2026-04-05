// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AZCalc",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "AZDecimal", targets: ["AZDecimal"]),
        .library(name: "AZFormula", targets: ["AZFormula"]),
    ],
    targets: [
        // C++/Objective-C++ 演算コア
        .target(
            name: "AZDecimalC",
            path: "Sources/AZDecimalC",
            publicHeadersPath: "include"
        ),
        // 十進演算 Swift API
        .target(
            name: "AZDecimal",
            dependencies: ["AZDecimalC"],
            path: "Sources/AZDecimal"
        ),
        // 数式エンジン Swift API
        .target(
            name: "AZFormula",
            dependencies: ["AZDecimal"],
            path: "Sources/AZFormula"
        ),
        .testTarget(
            name: "AZDecimalTests",
            dependencies: ["AZDecimal"]
        ),
        .testTarget(
            name: "AZFormulaTests",
            dependencies: ["AZFormula"]
        ),
    ]
)
