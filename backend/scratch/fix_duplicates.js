const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const schools = await prisma.school.findMany();
  console.log('All Schools:', schools.map(s => ({ id: s.id, code: s.code, name: s.name, email: s.email })));

  const nameCounts = {};
  schools.forEach(s => {
    nameCounts[s.name] = (nameCounts[s.name] || 0) + 1;
  });

  const duplicates = Object.keys(nameCounts).filter(n => nameCounts[n] > 1);
  console.log('Duplicate Names:', duplicates);

  for (const name of duplicates) {
    const dupSchools = schools.filter(s => s.name === name);
    // Keep the first one, rename others
    for (let i = 1; i < dupSchools.length; i++) {
        const newName = `${name} (${i + 1})`;
        await prisma.school.update({
            where: { id: dupSchools[i].id },
            data: { name: newName }
        });
        console.log(`Renamed school ${dupSchools[i].id} from "${name}" to "${newName}"`);
    }
  }
}

main().catch(console.error).finally(() => prisma.$disconnect());
