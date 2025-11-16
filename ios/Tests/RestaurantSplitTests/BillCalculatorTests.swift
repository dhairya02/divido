import XCTest
@testable import RestaurantSplit

final class BillCalculatorTests: XCTestCase {
    private let calculator = BillCalculator()

    func testSimpleSplit() throws {
        let participants = [Participant(id: "a", name: "Alice"), Participant(id: "b", name: "Bob")]
        let items = [Item(id: "entree", priceCents: 1000)]
        let shares = [
            ItemShare(itemId: "entree", participantId: "a", weight: 1),
            ItemShare(itemId: "entree", participantId: "b", weight: 1)
        ]
        let input = CalculationInput(
            items: items,
            participants: participants,
            shares: shares,
            taxRatePct: 10,
            tipRatePct: 20
        )

        let output = try calculator.calculateSplit(input)
        XCTAssertEqual(output.billTotals.subtotalCents, 1000)
        XCTAssertEqual(output.billTotals.taxCents, 100)
        XCTAssertEqual(output.billTotals.tipCents, 200)
        XCTAssertEqual(output.billTotals.grandTotalCents, 1300)
        XCTAssertEqual(output.participants.map { $0.totalOwedCents }.reduce(0, +), 1300)
        XCTAssertEqual(output.participants.first?.preTaxCents, 500)
        XCTAssertEqual(output.participants.last?.preTaxCents, 500)
    }

    func testRoundingDistribution() throws {
        let participants = [Participant(id: "a", name: "A"), Participant(id: "b", name: "B"), Participant(id: "c", name: "C")]
        let items = [Item(id: "dessert", priceCents: 100)]
        let shares = participants.map { participant in
            ItemShare(itemId: "dessert", participantId: participant.id, weight: 1)
        }
        let input = CalculationInput(
            items: items,
            participants: participants,
            shares: shares,
            taxRatePct: 0,
            tipRatePct: 0
        )
        let output = try calculator.calculateSplit(input)
        XCTAssertEqual(output.billTotals.subtotalCents, 100)
        XCTAssertEqual(output.participants.map { $0.preTaxCents }.reduce(0, +), 100)
        let amounts = output.participants.map { $0.preTaxCents }
        XCTAssertTrue(amounts.contains(33))
        XCTAssertTrue(amounts.contains(34))
    }

    func testItemLevelTax() throws {
        let participants = [Participant(id: "a", name: "A"), Participant(id: "b", name: "B")]
        let items = [
            Item(id: "drink", priceCents: 1000, taxable: true, taxRatePct: 5),
            Item(id: "snack", priceCents: 500, taxable: false)
        ]
        let shares = [
            ItemShare(itemId: "drink", participantId: "a", weight: 1),
            ItemShare(itemId: "drink", participantId: "b", weight: 1),
            ItemShare(itemId: "snack", participantId: "a", weight: 1)
        ]
        let input = CalculationInput(
            items: items,
            participants: participants,
            shares: shares,
            taxRatePct: 10,
            tipRatePct: 0,
            taxMode: .item
        )
        let output = try calculator.calculateSplit(input)
        XCTAssertEqual(output.billTotals.taxCents, 50)
        XCTAssertEqual(output.billTotals.subtotalCents, 1500)
    }

    func testMissingShareThrows() {
        let participants = [Participant(id: "a", name: "A")]
        let items = [Item(id: "pizza", priceCents: 1200)]
        let input = CalculationInput(
            items: items,
            participants: participants,
            shares: [],
            taxRatePct: 0,
            tipRatePct: 0
        )
        XCTAssertThrowsError(try calculator.calculateSplit(input)) { error in
            guard case BillCalculationError.itemMissingShares(let itemId) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(itemId, "pizza")
        }
    }
}
