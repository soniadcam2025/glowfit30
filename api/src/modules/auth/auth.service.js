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

export async function createUser({
  name, email, password, role = 'user',
  fitnessLevel, goal, dietStyle, targetWeight,
  focusAreas, dob, height, weight,
}) {
  const hashed = password ? await hashPassword(password) : null;
  return prisma.user.create({
    data: {
      name,
      email: email.toLowerCase(),
      password: hashed,
      role,
      fitnessLevel:  fitnessLevel  ?? null,
      goal:          goal          ?? null,
      dietStyle:     dietStyle     ?? null,
      targetWeight:  targetWeight  ?? null,
      focusAreas:    focusAreas    ?? [],
      dob:           dob ? new Date(dob) : null,
      height:        height        ?? null,
      weight:        weight        ?? null,
    },
  });
}

export async function findOrCreateFirebaseUser({ uid, email, name, photoUrl }) {
  const normalizedEmail = email.toLowerCase();

  const existing = await prisma.user.findUnique({ where: { email: normalizedEmail } });
  if (existing) return { user: existing, isNew: false };

  const user = await prisma.user.create({
    data: {
      name: name || normalizedEmail.split('@')[0],
      email: normalizedEmail,
      password: null,
      firebaseUid: uid,
      photoUrl,
    },
  });
  return { user, isNew: true };
}
