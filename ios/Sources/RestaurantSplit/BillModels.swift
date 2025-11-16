import Foundation

public struct Participant: Identifiable, Equatable, Hashable, Codable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct Item: Identifiable, Equatable, Hashable, Codable {
    public let id: String
    public let priceCents: Int
    public let taxable: Bool
    public let taxRatePct: Double?

    public init(id: String, priceCents: Int, taxable: Bool = true, taxRatePct: Double? = nil) {
        self.id = id
        self.priceCents = priceCents
        self.taxable = taxable
        self.taxRatePct = taxRatePct
    }
}

public struct ItemShare: Equatable, Hashable, Codable {
    public let itemId: String
    public let participantId: String
    public let weight: Double

    public init(itemId: String, participantId: String, weight: Double) {
        self.itemId = itemId
        self.participantId = participantId
        self.weight = weight
    }
}

public enum TaxMode: String, Codable {
    case global = "GLOBAL"
    case item = "ITEM"
}

public struct CalculationInput: Equatable, Codable {
    public let items: [Item]
    public let participants: [Participant]
    public let shares: [ItemShare]
    public let taxRatePct: Double
    public let tipRatePct: Double
    public let taxMode: TaxMode
    public let convenienceFeeRatePct: Double

    public init(
        items: [Item],
        participants: [Participant],
        shares: [ItemShare],
        taxRatePct: Double,
        tipRatePct: Double,
        taxMode: TaxMode = .global,
        convenienceFeeRatePct: Double = 0
    ) {
        self.items = items
        self.participants = participants
        self.shares = shares
        self.taxRatePct = taxRatePct
        self.tipRatePct = tipRatePct
        self.taxMode = taxMode
        self.convenienceFeeRatePct = convenienceFeeRatePct
    }
}

public struct BillTotals: Equatable, Codable {
    public let subtotalCents: Int
    public let taxCents: Int
    public let tipCents: Int
    public let convenienceFeeCents: Int
    public let grandTotalCents: Int
}

public struct ParticipantBreakdown: Equatable, Codable {
    public let participantId: String
    public let name: String
    public let preTaxCents: Int
    public let taxCents: Int
    public let tipCents: Int
    public let convenienceFeeCents: Int
    public let totalOwedCents: Int
}

public struct ItemAllocation: Equatable, Codable {
    public let participantId: String
    public let cents: Int
}

public struct ItemCalculation: Equatable, Codable {
    public let itemId: String
    public let allocations: [ItemAllocation]
}

public struct CalculationOutput: Equatable, Codable {
    public let billTotals: BillTotals
    public let participants: [ParticipantBreakdown]
    public let byItem: [ItemCalculation]
}

public enum BillCalculationError: LocalizedError, Equatable {
    case itemMissingShares(itemId: String)
    case invalidShareWeight(itemId: String)
    case totalsDoNotMatch

    public var errorDescription: String? {
        switch self {
        case .itemMissingShares(let id):
            return "Item \(id) has no shares assigned."
        case .invalidShareWeight(let id):
            return "Item \(id) has a share with non-positive weight."
        case .totalsDoNotMatch:
            return "Totals do not add up exactly."
        }
    }
}
