// FormulaViewModel.swift

import Observation
import Foundation
import AZDecimal
import AZFormula

@Observable
@MainActor
final class FormulaViewModel {

    var formula: String = ""
    var decimalDigits: Int = 3
    var roundType: AZDecimalConfig.RoundType = .r54

    var config: AZDecimalConfig {
        AZDecimalConfig(decimalDigits: decimalDigits, roundType: roundType, trailZero: false)
    }

    var evaluationResult: Result<String, AZFormulaError>? {
        guard !formula.isEmpty else { return nil }
        return AZFormula.evaluate(formula, config: config)
    }

    var displayResult: String {
        switch evaluationResult {
        case .success(let value): value
        case .failure(let e):    errorMessage(e)
        case nil:                "—"
        }
    }

    var hasError: Bool {
        if case .failure = evaluationResult { return true }
        return false
    }

    private func errorMessage(_ error: AZFormulaError) -> String {
        switch error {
        case .tooLong:            String(localized: "formula.error.tooLong")
        case .negativeSqrt:       String(localized: "formula.error.negativeSqrt")
        case .zeroDivision:       String(localized: "formula.error.zeroDivision")
        case .overflow:           String(localized: "formula.error.overflow")
        case .invalidExpression:  String(localized: "formula.error.invalidExpression")
        }
    }
}
