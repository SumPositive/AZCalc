// RoundingViewModelTests.swift

import XCTest
@testable import AZCalcDemo
import AZDecimal

@MainActor
final class RoundingViewModelTests: XCTestCase {

    func test_rowCount_is7() {
        let vm = RoundingViewModel()
        XCTAssertEqual(vm.rows.count, 7)
    }

    func test_allModes_present() {
        let vm = RoundingViewModel()
        let ids = Set(vm.rows.map(\.id))
        let expected: Set<AZDecimalConfig.RoundType> = [.rup, .rPlus, .r54, .r55, .r65, .rMinus, .truncateToDigits, .keepFull]
        XCTAssertEqual(ids, expected)
    }

    func test_r54_roundsHalfUp() {
        let vm = RoundingViewModel()
        vm.inputText = "3.456"
        vm.decimalDigits = 2
        let row = vm.rows.first { $0.id == .r54 }
        XCTAssertEqual(row?.result, "3.46")
    }

    func test_r54_roundsHalfDown_atFive() {
        let vm = RoundingViewModel()
        vm.inputText = "3.455"
        vm.decimalDigits = 2
        let row = vm.rows.first { $0.id == .r54 }
        XCTAssertEqual(row?.result, "3.46")
    }

    func test_keepFull_returnsFullPrecision() {
        let vm = RoundingViewModel()
        vm.inputText = "3.456"
        vm.decimalDigits = 1
        let row = vm.rows.first { $0.id == .keepFull }
        // keepFull = 丸めなし、生の値をそのまま返す
        XCTAssertEqual(row?.result, "3.456")
    }

    func test_truncateToDigits_truncatesValue() {
        let vm = RoundingViewModel()
        vm.inputText = "3.456"
        vm.decimalDigits = 1
        let row = vm.rows.first { $0.id == .truncateToDigits }
        // truncateToDigits = 設定桁数で値を切り捨てる
        XCTAssertEqual(row?.result, "3.4")
    }

    func test_rup_ceilsAbsoluteValue() {
        let vm = RoundingViewModel()
        vm.inputText = "3.451"
        vm.decimalDigits = 2
        let row = vm.rows.first { $0.id == .rup }
        XCTAssertEqual(row?.result, "3.46")
    }

    func test_decimalDigits_change_updatesResults() {
        let vm = RoundingViewModel()
        vm.inputText = "3.456789"
        vm.decimalDigits = 3
        let r54_3 = vm.rows.first { $0.id == .r54 }?.result

        vm.decimalDigits = 2
        let r54_2 = vm.rows.first { $0.id == .r54 }?.result

        XCTAssertNotEqual(r54_3, r54_2)
        XCTAssertEqual(r54_3, "3.457")
        XCTAssertEqual(r54_2, "3.46")
    }
}
