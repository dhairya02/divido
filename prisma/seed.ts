import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

async function main() {
  const [alex, bea, cam] = await Promise.all([
    prisma.contact.upsert({
      where: { email: "alex@example.com" },
      update: {},
      create: { name: "Alex", email: "alex@example.com", venmo: "@alex" },
    }),
    prisma.contact.upsert({
      where: { email: "bea@example.com" },
      update: {},
      create: { name: "Bea", email: "bea@example.com", cashapp: "$bea" },
    }),
    prisma.contact.upsert({
      where: { email: "cam@example.com" },
      update: {},
      create: { name: "Cam", email: "cam@example.com" },
    }),
  ]);

  const bill = await prisma.bill.create({
    data: {
      title: "Demo Dinner",
      venue: "Cafe Demo",
      subtotalCents: 1200 + 3450, // two items below
      taxRatePct: 8.875,
      tipRatePct: 18,
      currency: "USD",
      participants: {
        create: [{ contactId: alex.id }, { contactId: bea.id }, { contactId: cam.id }],
      },
    },
    include: { participants: true },
  });

  const [item1, item2] = await Promise.all([
    prisma.item.create({ data: { billId: bill.id, name: "Appetizer", priceCents: 1200 } }),
    prisma.item.create({ data: { billId: bill.id, name: "Pizza", priceCents: 3450 } }),
  ]);

  // Map participant by contact name for convenience
  const pAlex = bill.participants.find(() => true)!; // order matches create
  const pBea = bill.participants.find((p, idx) => idx === 1)!;
  const pCam = bill.participants.find((p, idx) => idx === 2)!;

  // Shares: item1 50/50 between Alex and Bea
  await prisma.itemShare.createMany({
    data: [
      { itemId: item1.id, participantId: pAlex.id, weight: 1 },
      { itemId: item1.id, participantId: pBea.id, weight: 1 },
    ],
  });

  // item2 weights 2:1:1 Alex:Bea:Cam
  await prisma.itemShare.createMany({
    data: [
      { itemId: item2.id, participantId: pAlex.id, weight: 2 },
      { itemId: item2.id, participantId: pBea.id, weight: 1 },
      { itemId: item2.id, participantId: pCam.id, weight: 1 },
    ],
  });
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });


