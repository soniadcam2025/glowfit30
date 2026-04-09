import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { env } from '../../config/env.js';
import { prisma } from '../../database/prisma.js';

const SALT_ROUNDS = 12;

export function hashPassword(plain) {
  return bcrypt.hash(plain, SALT_ROUNDS);
}

export function verifyPassword(plain, hash) {
  return bcrypt.compare(plain, hash);
}

export function signToken(user) {
  return jwt.sign(
    { sub: user.id, role: user.role },
    env.JWT_SECRET,
    { expiresIn: env.JWT_EXPIRES_IN },
  );
}

export async function findByEmail(email) {
  const normalized = String(email).trim().toLowerCase();
  return prisma.user.findUnique({ where: { email: normalized } });
}

export async function createUser({ name, email, password, role = 'user' }) {
  const hashed = await hashPassword(password);
  return prisma.user.create({
    data: {
      name,
      email: email.toLowerCase(),
      password: hashed,
      role,
    },
  });
}
