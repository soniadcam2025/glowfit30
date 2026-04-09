import 'dotenv/config';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const result = await prisma.$queryRaw`SELECT NOW() as now`;
  console.log('DB connection successful');
  console.log(result);
}

main()
  .catch((error) => {
    console.error('DB connection failed');
    console.error(error?.message || error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
