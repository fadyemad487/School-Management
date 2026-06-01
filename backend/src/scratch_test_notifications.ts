import { prisma } from "./config/prisma";

async function test() {
  const school = await prisma.school.findFirst();
  if (!school) return;
  const schoolId = school.id;
  const realUserId = "1dc28639-e5f4-4dd1-a63e-839254f5defd";

  const where: any = { schoolId };
  where.OR = [
    { recipientId: realUserId },
    { recipientId: null }
  ];

  const data = await prisma.notification.findMany({
    where,
    orderBy: { sentAt: "desc" },
    take: 200,
  });

  console.log("NOTIFICATIONS RETRIEVED:", JSON.stringify(data, null, 2));
}

test().catch(console.error);
