import { prisma } from '../../database/prisma.js';

const DEFAULT_CONTENT =
  'This is a placeholder Privacy Policy & Terms document. Update this content from the Admin Panel.';

export async function getLegalDocument() {
  const existing = await prisma.legalDocument.findFirst();
  if (existing) return existing;
  return prisma.legalDocument.create({
    data: { content: DEFAULT_CONTENT },
  });
}

export async function updateLegalDocument(data) {
  const existing = await prisma.legalDocument.findFirst();
  if (!existing) {
    return prisma.legalDocument.create({
      data: {
        title: data.title ?? undefined,
        content: data.content,
      },
    });
  }
  return prisma.legalDocument.update({
    where: { id: existing.id },
    data: {
      title: data.title ?? undefined,
      content: data.content,
    },
  });
}
