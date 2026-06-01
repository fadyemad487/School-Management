import { PrismaClient } from "@prisma/client";
import crypto from "crypto";

const prisma = new PrismaClient();

function generateRandomPassword(length = 6): string {
  const chars = "1234567890ABCDEFGHJKLMNPQRSTUVWXYZ";
  let pw = "";
  for (let i = 0; i < length; i++) {
    pw += chars.charAt(crypto.randomInt(chars.length));
  }
  return pw;
}

function hashPassword(pw: string): string {
  return crypto.createHash("sha256").update(pw).digest("hex");
}

async function main() {
  const studentsWithoutCreds = await prisma.student.findMany({
    where: {
      credentials: {
        none: {}
      }
    }
  });

  for (const student of studentsWithoutCreds) {
    if (!student.studentCode) continue;

    const plainPw = generateRandomPassword(6);
    let loginId = student.studentCode;

    // Check if loginId exists
    const existing = await prisma.appCredential.findUnique({ where: { loginId } });
    if (existing) {
      loginId = `${loginId}-${crypto.randomInt(100, 999)}`;
    }
    
    await prisma.appCredential.create({
      data: {
        loginId: loginId,
        passwordHash: hashPassword(plainPw),
        plainTextPw: plainPw,
        role: "STUDENT",
        schoolId: student.schoolId,
        studentId: student.id,
      }
    });
    console.log(`Created credential for student: ${student.nameAr} (Code: ${loginId})`);
  }

  console.log("Backfill complete!");
}

main().catch(console.error).finally(() => prisma.$disconnect());
