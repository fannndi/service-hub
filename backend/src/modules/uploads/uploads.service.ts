import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { nid } from '../../common/utils';
import { AppConfig } from '../../config/configuration';

const ALLOWED_MIME_TYPES = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
  'application/pdf',
];

@Injectable()
export class UploadService {
  private s3: S3Client;

  constructor(private config: ConfigService<AppConfig>) {
    this.s3 = new S3Client({
      endpoint: this.config.get('storage.endpoint', { infer: true }),
      region: 'auto',
      credentials: {
        accessKeyId: this.config.get('storage.accessKey', { infer: true }) ?? '',
        secretAccessKey: this.config.get('storage.secretKey', { infer: true }) ?? '',
      },
      forcePathStyle: true,
    });
  }

  async generatePresignedUrl(
    fileName: string,
    contentType: string,
    folder: string = 'uploads',
  ): Promise<{ uploadUrl: string; fileUrl: string; key: string }> {
    if (!ALLOWED_MIME_TYPES.includes(contentType)) {
      return { uploadUrl: '', fileUrl: '', key: '' };
    }

    const ext = fileName.split('.').pop() ?? 'bin';
    const key = `${folder}/${Date.now()}-${nid()}.${ext}`;
    const bucket = this.config.get('storage.bucket', { infer: true }) ?? '';

    const command = new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      ContentType: contentType,
    });

    const uploadUrl = await getSignedUrl(this.s3, command, { expiresIn: 600 });
    const publicUrlBase = this.config.get('storage.publicUrl', { infer: true }) ?? '';
    const fileUrl = `${publicUrlBase}/${key}`;

    return { uploadUrl, fileUrl, key };
  }
}
