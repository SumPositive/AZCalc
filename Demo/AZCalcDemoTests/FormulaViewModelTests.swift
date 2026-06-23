// FormulaViewModelTests.swift

import XCTest
@testable import AZCalcDemo
import AZFormula

@MainActor
final class FormulaViewModelTests: XCTestCase {

    func test_emptyFormula_displaysPlaceholder() {
        let vm = FormulaViewModel()
        XCTAssertNil(vm.evaluationResult)
        XCTAssertEqual(vm.displayResult, "—")
        XCTAssertFalse(vm.hasError)
    }

    func test_simpleAddition() {
        let vm = FormulaViewModel()
        vm.formula = "1+2"
        vm.roundType = .keepFull
        XCTAssertEqual(vm.displayResult, "3")
    }

    func test_percentAdd() {
        let vm = FormulaViewModel()
        vm.formula = "100+5%"
        vm.decimalDigits = 0
        vm.roundType = .r54
        XCTAssertEqual(vm.displayResult, "105")
    }

    func test_percentSub() {
        let vm = FormulaViewModel()
        vm.formula = "100-5%"
        vm.decimalDigits = 0
        vm.roundType = .r54
        XCTAssertEqual(vm.displayResult, "95")
    }

    func test_division_withRounding() {
        let vm = FormulaViewModel()
        vm.formula = "1÷3"
        vm.decimalDigits = 3
        vm.roundType = .r54
        XCTAssertEqual(vm.displayResult, "0.333")
    }

    func test_negativeSqrt_showsError() {
        let vm = FormulaViewModel()
        vm.formula = "√(0-1)"
        XCTAssertTrue(vm.hasError)
        XCTAssertFalse(vm.displayResult.isEmpty)
    }

    func test_tooLong_showsError() {
        let vm = FormulaViewModel()
        vm.formula = String(repeating: "1", count: 201)
        XCTAssertTrue(vm.hasError)
    }

    func test_configUpdates_affectResult() {
        let vm = FormulaViewModel()
        vm.formula = "1÷3"
        vm.decimalDigits = 2
        vm.roundType = .r54
        XCTAssertEqual(vm.displayResult, "0.33")

        vm.decimalDigits = 4
        XCTAssertEqual(vm.displayResult, "0.3333")
    }
}
