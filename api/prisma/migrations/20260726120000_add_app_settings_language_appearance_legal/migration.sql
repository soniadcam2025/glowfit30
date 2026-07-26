-- AlterTable: add App Settings preference fields to users
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "language" TEXT NOT NULL DEFAULT 'English';
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "appearance" TEXT NOT NULL DEFAULT 'System';

-- CreateTable: legal_documents (singleton-style content for Privacy Policy & Terms)
CREATE TABLE IF NOT EXISTS "legal_documents" (
    "id" UUID NOT NULL,
    "title" TEXT NOT NULL DEFAULT 'Privacy Policy & Terms',
    "content" TEXT NOT NULL,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "legal_documents_pkey" PRIMARY KEY ("id")
);
