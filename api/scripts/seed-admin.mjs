/**
 * Creates the first super_admin when the users table is empty.
 * Usage (on server): ADMIN_EMAIL=... ADMIN_PASSWORD=... ADMIN_NAME="..." node scripts/seed-admin.mjs
 */
import 'dotenv/config';
import bcrypt from 'bcryptjs';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const email = process.env.ADMIN_EMAIL?.trim().toLowerCase();
const password = process.env.ADMIN_PASSWORD;
const name = process.env.ADMIN_NAME?.trim() || 'Super Admin';

async function main() {
  if (!email || !password) {
    console.error('Set ADMIN_EMAIL and ADMIN_PASSWORD');
    process.exit(1);
  }

  const hashed = await bcrypt.hash(password, 12);
  const existing = await prisma.user.findUnique({ where: { email } });

  if (!existing) {
    await prisma.user.create({
      data: {
        name,
        email,
        password: hashed,
        role: 'super_admin',
      },
    });
    console.log('Super admin created.');
    return;
  }

  await prisma.user.update({
    where: { email },
    data: {
      name,
      password: hashed,
      role: 'super_admin',
      isBlocked: false,
    },
  });
  console.log('Super admin updated with hashed password.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
