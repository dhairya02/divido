module.exports = {

"[project]/.next-internal/server/app/api/bills/[id]/calc/route/actions.js [app-rsc] (server actions loader, ecmascript)": ((__turbopack_context__) => {

var { m: module, e: exports } = __turbopack_context__;
{
}}),
"[externals]/next/dist/compiled/next-server/app-route-turbo.runtime.dev.js [external] (next/dist/compiled/next-server/app-route-turbo.runtime.dev.js, cjs)": ((__turbopack_context__) => {

var { m: module, e: exports } = __turbopack_context__;
{
const mod = __turbopack_context__.x("next/dist/compiled/next-server/app-route-turbo.runtime.dev.js", () => require("next/dist/compiled/next-server/app-route-turbo.runtime.dev.js"));

module.exports = mod;
}}),
"[externals]/next/dist/compiled/@opentelemetry/api [external] (next/dist/compiled/@opentelemetry/api, cjs)": ((__turbopack_context__) => {

var { m: module, e: exports } = __turbopack_context__;
{
const mod = __turbopack_context__.x("next/dist/compiled/@opentelemetry/api", () => require("next/dist/compiled/@opentelemetry/api"));

module.exports = mod;
}}),
"[externals]/next/dist/compiled/next-server/app-page-turbo.runtime.dev.js [external] (next/dist/compiled/next-server/app-page-turbo.runtime.dev.js, cjs)": ((__turbopack_context__) => {

var { m: module, e: exports } = __turbopack_context__;
{
const mod = __turbopack_context__.x("next/dist/compiled/next-server/app-page-turbo.runtime.dev.js", () => require("next/dist/compiled/next-server/app-page-turbo.runtime.dev.js"));

module.exports = mod;
}}),
"[externals]/next/dist/server/app-render/work-unit-async-storage.external.js [external] (next/dist/server/app-render/work-unit-async-storage.external.js, cjs)": ((__turbopack_context__) => {

var { m: module, e: exports } = __turbopack_context__;
{
const mod = __turbopack_context__.x("next/dist/server/app-render/work-unit-async-storage.external.js", () => require("next/dist/server/app-render/work-unit-async-storage.external.js"));

module.exports = mod;
}}),
"[externals]/next/dist/server/app-render/work-async-storage.external.js [external] (next/dist/server/app-render/work-async-storage.external.js, cjs)": ((__turbopack_context__) => {

var { m: module, e: exports } = __turbopack_context__;
{
const mod = __turbopack_context__.x("next/dist/server/app-render/work-async-storage.external.js", () => require("next/dist/server/app-render/work-async-storage.external.js"));

module.exports = mod;
}}),
"[externals]/next/dist/shared/lib/no-fallback-error.external.js [external] (next/dist/shared/lib/no-fallback-error.external.js, cjs)": ((__turbopack_context__) => {

var { m: module, e: exports } = __turbopack_context__;
{
const mod = __turbopack_context__.x("next/dist/shared/lib/no-fallback-error.external.js", () => require("next/dist/shared/lib/no-fallback-error.external.js"));

module.exports = mod;
}}),
"[externals]/next/dist/server/app-render/after-task-async-storage.external.js [external] (next/dist/server/app-render/after-task-async-storage.external.js, cjs)": ((__turbopack_context__) => {

var { m: module, e: exports } = __turbopack_context__;
{
const mod = __turbopack_context__.x("next/dist/server/app-render/after-task-async-storage.external.js", () => require("next/dist/server/app-render/after-task-async-storage.external.js"));

module.exports = mod;
}}),
"[externals]/@prisma/client [external] (@prisma/client, cjs)": ((__turbopack_context__) => {

var { m: module, e: exports } = __turbopack_context__;
{
const mod = __turbopack_context__.x("@prisma/client", () => require("@prisma/client"));

module.exports = mod;
}}),
"[project]/lib/db.ts [app-route] (ecmascript)": ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s({
    "prisma": ()=>prisma
});
var __TURBOPACK__imported__module__$5b$externals$5d2f40$prisma$2f$client__$5b$external$5d$__$2840$prisma$2f$client$2c$__cjs$29$__ = __turbopack_context__.i("[externals]/@prisma/client [external] (@prisma/client, cjs)");
;
// Ensure a single PrismaClient instance across hot reloads in dev
const globalForPrisma = globalThis;
const prisma = globalForPrisma.prisma ?? new __TURBOPACK__imported__module__$5b$externals$5d2f40$prisma$2f$client__$5b$external$5d$__$2840$prisma$2f$client$2c$__cjs$29$__["PrismaClient"]({
    log: [
        "error",
        "warn"
    ]
});
if ("TURBOPACK compile-time truthy", 1) globalForPrisma.prisma = prisma;
}),
"[project]/lib/utils.ts [app-route] (ecmascript)": ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s({
    "assert": ()=>assert,
    "fractionalPart": ()=>fractionalPart,
    "roundHalfUp": ()=>roundHalfUp,
    "stableSortBy": ()=>stableSortBy
});
function roundHalfUp(value) {
    if (Number.isNaN(value) || !Number.isFinite(value)) return 0;
    return value >= 0 ? Math.floor(value + 0.5) : Math.ceil(value - 0.5);
}
function fractionalPart(value) {
    const floorValue = Math.floor(value);
    return value - floorValue;
}
function assert(condition, message) {
    if (!condition) throw new Error(message);
}
function stableSortBy(arr, selector) {
    return arr.map((v, idx)=>({
            v,
            idx
        })).sort((a, b)=>{
        const aa = selector(a.v);
        const bb = selector(b.v);
        if (aa < bb) return -1;
        if (aa > bb) return 1;
        return a.idx - b.idx;
    }).map((x)=>x.v);
}
}),
"[project]/lib/calc.ts [app-route] (ecmascript)": ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s({
    "calculateSplit": ()=>calculateSplit
});
var __TURBOPACK__imported__module__$5b$project$5d2f$lib$2f$utils$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/lib/utils.ts [app-route] (ecmascript)");
;
function calculateSplit(input) {
    const { items, participants, shares, taxRatePct, tipRatePct, taxMode = "GLOBAL", convenienceFeeRatePct = 0 } = input;
    // 1. Subtotal
    const subtotalCents = items.reduce((acc, it)=>acc + it.priceCents, 0);
    // 2-3. Item splits with weights, round-half-up per participant and fix rounding drift
    const participantIdToPreTaxCents = new Map();
    for (const p of participants)participantIdToPreTaxCents.set(p.id, 0);
    const byItem = [];
    for (const item of items){
        const itemShares = shares.filter((s)=>s.itemId === item.id && s.weight > 0);
        if (itemShares.length === 0) {
            throw new Error(`Item "${item.id}" has no shares assigned.`);
        }
        const totalWeight = itemShares.reduce((acc, s)=>acc + s.weight, 0);
        // Normalized allocations
        const exactAllocations = itemShares.map((s)=>({
                participantId: s.participantId,
                exact: item.priceCents * s.weight / totalWeight
            }));
        const rounded = exactAllocations.map((ea)=>({
                participantId: ea.participantId,
                exact: ea.exact,
                rounded: (0, __TURBOPACK__imported__module__$5b$project$5d2f$lib$2f$utils$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["roundHalfUp"])(ea.exact),
                frac: (0, __TURBOPACK__imported__module__$5b$project$5d2f$lib$2f$utils$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["fractionalPart"])(ea.exact)
            }));
        let sumRounded = rounded.reduce((acc, r)=>acc + r.rounded, 0);
        const delta = item.priceCents - sumRounded; // how many pennies to adjust
        if (delta !== 0) {
            const direction = Math.sign(delta); // +1 add pennies, -1 remove pennies
            const count = Math.abs(delta);
            const sorted = rounded.slice().sort((a, b)=>{
                // For adding pennies: larger fractional parts first
                // For removing pennies: smaller fractional parts first
                const primary = direction > 0 ? b.frac - a.frac : a.frac - b.frac;
                if (primary !== 0) return primary;
                // tiebreak by participantId for determinism
                return a.participantId.localeCompare(b.participantId);
            });
            for(let i = 0; i < count; i++){
                sorted[i % sorted.length].rounded += direction;
            }
            // Recompute sum after distribution
            sumRounded = sorted.reduce((acc, r)=>acc + r.rounded, 0);
            // Place back into rounded map
            const byId = new Map(sorted.map((r)=>[
                    r.participantId,
                    r.rounded
                ]));
            for (const r of rounded)r.rounded = byId.get(r.participantId) ?? r.rounded;
        }
        // Accumulate pre-tax per participant
        const itemAllocations = [];
        for (const r of rounded){
            const prev = participantIdToPreTaxCents.get(r.participantId) ?? 0;
            participantIdToPreTaxCents.set(r.participantId, prev + r.rounded);
            itemAllocations.push({
                participantId: r.participantId,
                cents: r.rounded
            });
        }
        byItem.push({
            itemId: item.id,
            allocations: itemAllocations
        });
    }
    // 5. Pools
    let taxCents = 0;
    if (taxMode === "GLOBAL") {
        const taxableSubtotal = subtotalCents;
        taxCents = (0, __TURBOPACK__imported__module__$5b$project$5d2f$lib$2f$utils$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["roundHalfUp"])(taxableSubtotal * taxRatePct / 100);
    } else {
        // Sum item-level tax based on each item's specific tax rate (or 0)
        taxCents = items.reduce((acc, it)=>{
            if (it.taxable === false) return acc;
            const rate = typeof it.taxRatePct === "number" ? it.taxRatePct : taxRatePct;
            return acc + (0, __TURBOPACK__imported__module__$5b$project$5d2f$lib$2f$utils$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["roundHalfUp"])(it.priceCents * rate / 100);
        }, 0);
    }
    const tipCents = (0, __TURBOPACK__imported__module__$5b$project$5d2f$lib$2f$utils$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["roundHalfUp"])(subtotalCents * tipRatePct / 100);
    const preTaxTotals = participants.map((p)=>({
            participantId: p.id,
            name: p.name,
            preTaxCents: participantIdToPreTaxCents.get(p.id) ?? 0
        }));
    // 6. Allocate pools proportionally using floor + remainder distribution
    const poolAllocate = (pool)=>{
        if (pool === 0 || subtotalCents === 0) {
            return preTaxTotals.map(()=>0);
        }
        const exacts = preTaxTotals.map((pt)=>pool * pt.preTaxCents / subtotalCents);
        const floors = exacts.map((e)=>Math.floor(e));
        let sumFloors = floors.reduce((a, b)=>a + b, 0);
        let leftover = pool - sumFloors;
        if (leftover > 0) {
            const order = preTaxTotals.map((pt, idx)=>({
                    idx,
                    frac: (0, __TURBOPACK__imported__module__$5b$project$5d2f$lib$2f$utils$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["fractionalPart"])(exacts[idx])
                })).sort((a, b)=>b.frac - a.frac || preTaxTotals[a.idx].participantId.localeCompare(preTaxTotals[b.idx].participantId));
            for(let i = 0; i < leftover; i++)floors[order[i % order.length].idx] += 1;
            sumFloors = floors.reduce((a, b)=>a + b, 0);
        }
        return floors;
    };
    const feeCents = (0, __TURBOPACK__imported__module__$5b$project$5d2f$lib$2f$utils$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["roundHalfUp"])(subtotalCents * convenienceFeeRatePct / 100);
    const taxAlloc = poolAllocate(taxCents);
    const tipAlloc = poolAllocate(tipCents);
    const feeAlloc = poolAllocate(feeCents);
    const participantsOut = preTaxTotals.map((pt, idx)=>{
        const tax = taxAlloc[idx];
        const tip = tipAlloc[idx];
        const fee = feeAlloc[idx];
        const total = pt.preTaxCents + tax + tip + fee;
        return {
            participantId: pt.participantId,
            name: pt.name,
            preTaxCents: pt.preTaxCents,
            taxCents: tax,
            tipCents: tip,
            convenienceFeeCents: fee,
            totalOwedCents: total
        };
    });
    // 8. Assert exactness
    const sumOwed = participantsOut.reduce((acc, p)=>acc + p.totalOwedCents, 0);
    const grandTotal = subtotalCents + taxCents + tipCents + feeCents;
    (0, __TURBOPACK__imported__module__$5b$project$5d2f$lib$2f$utils$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["assert"])(sumOwed === grandTotal, "Totals do not add up exactly.");
    return {
        billTotals: {
            subtotalCents,
            taxCents,
            tipCents,
            convenienceFeeCents: feeCents,
            grandTotalCents: grandTotal
        },
        participants: participantsOut,
        byItem
    };
}
}),
"[project]/app/api/bills/[id]/calc/route.ts [app-route] (ecmascript)": ((__turbopack_context__) => {
"use strict";

__turbopack_context__.s({
    "GET": ()=>GET
});
var __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f2e$pnpm$2f$next$40$15$2e$4$2e$6_react$2d$dom$40$19$2e$1$2e$0_react$40$19$2e$1$2e$0_$5f$react$40$19$2e$1$2e$0$2f$node_modules$2f$next$2f$server$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/node_modules/.pnpm/next@15.4.6_react-dom@19.1.0_react@19.1.0__react@19.1.0/node_modules/next/server.js [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$lib$2f$db$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/lib/db.ts [app-route] (ecmascript)");
var __TURBOPACK__imported__module__$5b$project$5d2f$lib$2f$calc$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__ = __turbopack_context__.i("[project]/lib/calc.ts [app-route] (ecmascript)");
;
;
;
async function GET(_, { params }) {
    const { id } = await params;
    const bill = await __TURBOPACK__imported__module__$5b$project$5d2f$lib$2f$db$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["prisma"].bill.findUnique({
        where: {
            id
        },
        include: {
            participants: {
                include: {
                    contact: true
                }
            },
            items: true
        }
    });
    if (!bill) return __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f2e$pnpm$2f$next$40$15$2e$4$2e$6_react$2d$dom$40$19$2e$1$2e$0_react$40$19$2e$1$2e$0_$5f$react$40$19$2e$1$2e$0$2f$node_modules$2f$next$2f$server$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["NextResponse"].json({
        error: "Not found"
    }, {
        status: 404
    });
    const shares = await __TURBOPACK__imported__module__$5b$project$5d2f$lib$2f$db$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["prisma"].itemShare.findMany({
        where: {
            item: {
                billId: id
            }
        }
    });
    if (bill.items.length === 0) {
        return __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f2e$pnpm$2f$next$40$15$2e$4$2e$6_react$2d$dom$40$19$2e$1$2e$0_react$40$19$2e$1$2e$0_$5f$react$40$19$2e$1$2e$0$2f$node_modules$2f$next$2f$server$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["NextResponse"].json({
            error: "No items in bill."
        }, {
            status: 400
        });
    }
    // Check that items sum matches the bill's declared subtotal
    const itemsTotal = bill.items.reduce((a, i)=>a + i.priceCents, 0);
    if (itemsTotal !== bill.subtotalCents) {
        return __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f2e$pnpm$2f$next$40$15$2e$4$2e$6_react$2d$dom$40$19$2e$1$2e$0_react$40$19$2e$1$2e$0_$5f$react$40$19$2e$1$2e$0$2f$node_modules$2f$next$2f$server$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["NextResponse"].json({
            error: `Items total (${itemsTotal}) does not match bill subtotal (${bill.subtotalCents}). Update items or bill subtotal.`,
            itemsTotalCents: itemsTotal,
            billSubtotalCents: bill.subtotalCents
        }, {
            status: 400
        });
    }
    // Ensure every item has at least one share
    for (const item of bill.items){
        const itemShares = shares.filter((s)=>s.itemId === item.id && s.weight > 0);
        if (itemShares.length === 0) {
            return __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f2e$pnpm$2f$next$40$15$2e$4$2e$6_react$2d$dom$40$19$2e$1$2e$0_react$40$19$2e$1$2e$0_$5f$react$40$19$2e$1$2e$0$2f$node_modules$2f$next$2f$server$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["NextResponse"].json({
                error: `Item "${item.name}" has no shares.`
            }, {
                status: 400
            });
        }
    }
    const result = (0, __TURBOPACK__imported__module__$5b$project$5d2f$lib$2f$calc$2e$ts__$5b$app$2d$route$5d$__$28$ecmascript$29$__["calculateSplit"])({
        items: bill.items.map((i)=>({
                id: i.id,
                priceCents: i.priceCents,
                taxable: i.taxable,
                taxRatePct: i.taxRatePct
            })),
        participants: bill.participants.map((bp)=>({
                id: bp.id,
                name: bp.contact.name
            })),
        shares: shares.map((s)=>({
                itemId: s.itemId,
                participantId: s.participantId,
                weight: s.weight
            })),
        taxRatePct: bill.taxRatePct,
        tipRatePct: bill.tipRatePct,
        taxMode: bill.taxMode,
        convenienceFeeRatePct: bill.convenienceFeeRatePct ?? 0
    });
    // Attach contactId to participants in the response so downstream consumers
    // can resolve who is who without an extra query.
    const participantIdToContactId = new Map(bill.participants.map((bp)=>[
            bp.id,
            bp.contactId
        ]));
    const participantsWithContactId = result.participants.map((p)=>({
            ...p,
            contactId: participantIdToContactId.get(p.participantId)
        }));
    return __TURBOPACK__imported__module__$5b$project$5d2f$node_modules$2f2e$pnpm$2f$next$40$15$2e$4$2e$6_react$2d$dom$40$19$2e$1$2e$0_react$40$19$2e$1$2e$0_$5f$react$40$19$2e$1$2e$0$2f$node_modules$2f$next$2f$server$2e$js__$5b$app$2d$route$5d$__$28$ecmascript$29$__["NextResponse"].json({
        ...result,
        participants: participantsWithContactId
    });
}
}),

};

//# sourceMappingURL=%5Broot-of-the-server%5D__fd32cc3b._.js.map