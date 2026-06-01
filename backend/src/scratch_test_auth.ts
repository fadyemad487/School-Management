import { prisma } from "./config/prisma";

async function test() {
  const cred = await prisma.appCredential.findFirst({
    where: { loginId: "2669937" },
    include: { teacher: true }
  });
  
  if (!cred) {
    console.log("No credential found for loginId 2669937");
    return;
  }
  
  console.log("Credential found:", cred.id, "Role:", cred.role);
  
  const id = cred.id;
  const dbCred = await prisma.appCredential.findUnique({
    where: { id },
    include: { teacher: true, parent: true, student: true }
  });
  
  if (dbCred) {
    console.log("dbCred found!");
    console.log("Teacher linked:", !!dbCred.teacher);
    if (dbCred.teacher) {
      console.log("Teacher userId:", dbCred.teacher.userId);
    }
  } else {
    console.log("dbCred NOT found!");
  }
}

test().catch(console.error);
