import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { randomUUID } from 'crypto';
import { env } from './env.js';

let client = null;

function getClient() {
  if (client) return client;

  const { VULTR_S3_ENDPOINT, VULTR_S3_ACCESS_KEY, VULTR_S3_SECRET_KEY } = env;
  if (!VULTR_S3_ENDPOINT || !VULTR_S3_ACCESS_KEY || !VULTR_S3_SECRET_KEY) {
    throw new Error('Vultr Object Storage is not configured (VULTR_S3_* env vars missing)');
  }

  client = new S3Client({
    endpoint: VULTR_S3_ENDPOINT,
    region: env.VULTR_S3_REGION || 'us-east-1',
    credentials: {
      accessKeyId: VULTR_S3_ACCESS_KEY,
      secretAccessKey: VULTR_S3_SECRET_KEY,
    },
    forcePathStyle: false,
  });

  return client;
}

function bucketFor(folder) {
  const bucket = folder === 'diet' ? env.VULTR_S3_BUCKET_DIET : env.VULTR_S3_BUCKET_EXERCISES;
  if (!bucket) {
    throw new Error(`Vultr Object Storage bucket is not configured for "${folder}"`);
  }
  return bucket;
}

function publicUrlFor(bucket, key) {
  const endpoint = env.VULTR_S3_ENDPOINT.replace(/^https?:\/\//, '');
  return `https://${bucket}.${endpoint}/${key}`;
}

export async function uploadFile(buffer, mimetype, folder = 'exercises') {
  const bucket = bucketFor(folder);
  const ext = mimetype.split('/')[1] || 'jpg';
  const key = `${randomUUID()}.${ext}`;

  await getClient().send(
    new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      Body: buffer,
      ContentType: mimetype,
      ACL: 'public-read',
    }),
  );

  return publicUrlFor(bucket, key);
}
