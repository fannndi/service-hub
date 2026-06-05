import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { S3Client } from '@aws-sdk/client-s3';
import { PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { customAlphabet } from 'nanoid';

const nid = customAlphabet('0123456789abcdefghijklmnopqrstuvwxyz', 16);

@Injectable()
export class UploadService {
  private s3: S3Client;

  constructor(private config: ConfigService) {
    this.s3 = new S3Client({
      endpoint: this.config.get('storage.endpoint'),
      region: 'auto',
      credentials: {
        accessKeyId: this.config.get('storage.accessKey')!,
        secretAccessKey: this.config.get('storage.secretKey')!,
      },
      forcePathStyle: true,
    });
  }

  async generatePresignedUrl(
    fileName: string,
    contentType: string,
    folder: string = 'uploads',
  ): Promise<{ uploadUrl: string; publicUrl: string; key: string }> {
    const ext = fileName.split('.').pop() ?? 'bin';
    const key = `${folder}/${Date.now()}-${nid()}.${ext}`;
    const bucket = this.config.get<string>('storage.bucket')!;

    const command = new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      ContentType: contentType,
    });

    const uploadUrl = await getSignedUrl(this.s3, command, { expiresIn: 600 });

    const publicUrl = `${this.config.get('storage.publicUrl')}/${key}`;
    return { uploadUrl, publicUrl, key };
  }
}
