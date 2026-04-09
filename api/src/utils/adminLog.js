import { prisma } from '../database/prisma.js';

export async function logAdminAction(adminId, action, metadata = null) {
  try {
    await prisma.adminLog.create({
      data: {
        adminId,
        action,
        metadata: metadata === undefined ? undefined : metadata,
      },
    });
  } catch (err) {
    console.error('[adminLog]', err);
  }
}
