import { prisma } from '../../database/prisma.js';

export async function getProfile(userId) {
  return prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      name: true,
      email: true,
      role: true,
      photoUrl: true,
      fitnessLevel: true,
      goal: true,
      dietStyle: true,
      targetWeight: true,
      focusAreas: true,
      dob: true,
      height: true,
      weight: true,
      createdAt: true,
    },
  });
}

export async function saveFcmToken(userId, fcmToken) {
  return prisma.user.update({
    where: { id: userId },
    data: { fcmToken },
    select: { id: true },
  });
}

export async function updateProfile(userId, data) {
  const payload = {};

  if (data.name         !== undefined) payload.name         = data.name;
  if (data.fitnessLevel !== undefined) payload.fitnessLevel = data.fitnessLevel;
  if (data.goal         !== undefined) payload.goal         = data.goal;
  if (data.dietStyle    !== undefined) payload.dietStyle    = data.dietStyle;
  if (data.targetWeight !== undefined) payload.targetWeight = data.targetWeight;
  if (data.focusAreas   !== undefined) payload.focusAreas   = data.focusAreas;
  if (data.height       !== undefined) payload.height       = data.height;
  if (data.weight       !== undefined) payload.weight       = data.weight;
  if (data.dob          !== undefined) payload.dob          = new Date(data.dob);

  return prisma.user.update({
    where: { id: userId },
    data: payload,
    select: {
      id: true,
      name: true,
      email: true,
      role: true,
      photoUrl: true,
      fitnessLevel: true,
      goal: true,
      dietStyle: true,
      targetWeight: true,
      focusAreas: true,
      dob: true,
      height: true,
      weight: true,
      createdAt: true,
    },
  });
}
