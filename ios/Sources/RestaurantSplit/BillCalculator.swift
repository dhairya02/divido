import Foundation

private func roundHalfUp(_ value: Double) -> Int {
    Int(value.rounded(.toNearestOrAwayFromZero))
}

private func fractionalPart(_ value: Double) -> Double {
    value - floor(value)
}

private struct RoundedShare {
    var participantId: String
    var rounded: Int
    var fraction: Double
}

public struct BillCalculator {
    public init() {}

    public func calculateSplit(_ input: CalculationInput) throws -> CalculationOutput {
        let subtotalCents = input.items.reduce(0) { $0 + $1.priceCents }
        var preTaxByParticipant = Dictionary(uniqueKeysWithValues: input.participants.map { ($0.id, 0) })
        var byItem: [ItemCalculation] = []

        for item in input.items {
            let itemShares = input.shares.filter { $0.itemId == item.id && $0.weight > 0 }
            guard !itemShares.isEmpty else {
                throw BillCalculationError.itemMissingShares(itemId: item.id)
            }
            let totalWeight = itemShares.reduce(0.0) { $0 + $1.weight }
            guard totalWeight > 0 else {
                throw BillCalculationError.invalidShareWeight(itemId: item.id)
            }

            let exactAllocations: [(share: ItemShare, exact: Double)] = itemShares.map { share in
                let exact = (Double(item.priceCents) * share.weight) / totalWeight
                return (share, exact)
            }

            var rounded = exactAllocations.map { allocation in
                RoundedShare(
                    participantId: allocation.share.participantId,
                    rounded: roundHalfUp(allocation.exact),
                    fraction: fractionalPart(allocation.exact)
                )
            }
            var sumRounded = rounded.reduce(0) { $0 + $1.rounded }
            let delta = item.priceCents - sumRounded
            if delta != 0 {
                let direction = delta > 0 ? 1 : -1
                var sorted = rounded.sorted { lhs, rhs in
                    if direction > 0 {
                        if lhs.fraction == rhs.fraction { return lhs.participantId < rhs.participantId }
                        return lhs.fraction > rhs.fraction
                    } else {
                        if lhs.fraction == rhs.fraction { return lhs.participantId < rhs.participantId }
                        return lhs.fraction < rhs.fraction
                    }
                }
                for index in 0..<abs(delta) {
                    let target = index % sorted.count
                    sorted[target].rounded += direction
                }
                let replacement = Dictionary(uniqueKeysWithValues: sorted.map { ($0.participantId, $0.rounded) })
                rounded = rounded.map { share in
                    var updated = share
                    updated.rounded = replacement[share.participantId] ?? share.rounded
                    return updated
                }
                sumRounded = rounded.reduce(0) { $0 + $1.rounded }
            }

            var allocations: [ItemAllocation] = []
            for entry in rounded {
                preTaxByParticipant[entry.participantId, default: 0] += entry.rounded
                allocations.append(ItemAllocation(participantId: entry.participantId, cents: entry.rounded))
            }
            byItem.append(ItemCalculation(itemId: item.id, allocations: allocations))
        }

        let taxCents: Int
        switch input.taxMode {
        case .global:
            taxCents = roundHalfUp(Double(subtotalCents) * input.taxRatePct / 100)
        case .item:
            taxCents = input.items.reduce(0) { partial, item in
                guard item.taxable else { return partial }
                let rate = item.taxRatePct ?? input.taxRatePct
                return partial + roundHalfUp(Double(item.priceCents) * rate / 100)
            }
        }

        let tipCents = roundHalfUp(Double(subtotalCents) * input.tipRatePct / 100)
        let feeCents = roundHalfUp(Double(subtotalCents) * input.convenienceFeeRatePct / 100)

        let preTaxTotals = input.participants.map { participant in
            preTaxByParticipant[participant.id] ?? 0
        }

        func allocate(pool: Int) -> [Int] {
            guard pool > 0 && subtotalCents > 0 else {
                return Array(repeating: 0, count: preTaxTotals.count)
            }
            let exacts = preTaxTotals.map { Double(pool) * Double($0) / Double(subtotalCents) }
            var floors = exacts.map { Int(floor($0)) }
            var sumFloors = floors.reduce(0, +)
            var leftover = pool - sumFloors
            if leftover > 0 {
                let order = exacts.enumerated().sorted { lhs, rhs in
                    if lhs.element == rhs.element {
                        return input.participants[lhs.offset].id < input.participants[rhs.offset].id
                    }
                    return fractionalPart(lhs.element) > fractionalPart(rhs.element)
                }
                for i in 0..<leftover {
                    floors[order[i % order.count].offset] += 1
                }
                sumFloors = floors.reduce(0, +)
                leftover = pool - sumFloors
            }
            if leftover < 0 {
                let order = exacts.enumerated().sorted { lhs, rhs in
                    if lhs.element == rhs.element {
                        return input.participants[lhs.offset].id < input.participants[rhs.offset].id
                    }
                    return fractionalPart(lhs.element) < fractionalPart(rhs.element)
                }
                for i in 0..<abs(leftover) {
                    floors[order[i % order.count].offset] -= 1
                }
            }
            return floors
        }

        let taxAlloc = allocate(pool: taxCents)
        let tipAlloc = allocate(pool: tipCents)
        let feeAlloc = allocate(pool: feeCents)

        let participantsOutput: [ParticipantBreakdown] = input.participants.enumerated().map { index, participant in
            let preTax = preTaxByParticipant[participant.id] ?? 0
            let tax = taxAlloc[index]
            let tip = tipAlloc[index]
            let fee = feeAlloc[index]
            let total = preTax + tax + tip + fee
            return ParticipantBreakdown(
                participantId: participant.id,
                name: participant.name,
                preTaxCents: preTax,
                taxCents: tax,
                tipCents: tip,
                convenienceFeeCents: fee,
                totalOwedCents: total
            )
        }

        let billTotals = BillTotals(
            subtotalCents: subtotalCents,
            taxCents: taxCents,
            tipCents: tipCents,
            convenienceFeeCents: feeCents,
            grandTotalCents: subtotalCents + taxCents + tipCents + feeCents
        )

        let sumOwed = participantsOutput.reduce(0) { $0 + $1.totalOwedCents }
        guard sumOwed == billTotals.grandTotalCents else {
            throw BillCalculationError.totalsDoNotMatch
        }

        return CalculationOutput(
            billTotals: billTotals,
            participants: participantsOutput,
            byItem: byItem
        )
    }
}
