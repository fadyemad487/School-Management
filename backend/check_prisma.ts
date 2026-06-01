import { prisma } from "./src/config/prisma";
import * as fs from "fs";
import * as path from "path";

async function main() {
  const students = await prisma.student.findMany({
    where: {
      OR: [
        { nameAr: { contains: "magy", mode: "insensitive" } },
        { nameEn: { contains: "magy", mode: "insensitive" } },
        { user: { fullName: { contains: "magy", mode: "insensitive" } } }
      ]
    },
    include: {
      user: true,
      busAssignment: {
        include: {
          bus: true,
          route: true
        }
      }
    }
  });

  const dir = path.join(__dirname, "scratch");
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir);
  }
  fs.writeFileSync(path.join(dir, "student_debug.json"), JSON.stringify(students, null, 2), "utf8");
  console.log("Successfully wrote student_debug.json");
  process.exit(0);
}

main();
