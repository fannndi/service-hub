import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { UploadService } from './uploads.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { FileValidationException } from '../../common/exceptions';

const ALLOWED_MIME_TYPES = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
  'application/pdf',
];

@ApiTags('Uploads')
@Controller('uploads')
export class UploadsController {
  constructor(private readonly uploadService: UploadService) {}

  @Post('presign')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  async getPresignedUrl(
    @Body() dto: { fileName: string; mimeType?: string; contentType?: string; folder?: string },
  ) {
    const mimeType = dto.mimeType ?? dto.contentType ?? 'application/octet-stream';

    if (!ALLOWED_MIME_TYPES.includes(mimeType)) {
      throw new FileValidationException(
        `File type ${mimeType} not allowed`,
        'Tipe file tidak diizinkan. Hanya gambar dan PDF yang diperbolehkan.',
      );
    }

    return this.uploadService.generatePresignedUrl(dto.fileName, mimeType, dto.folder);
  }
}
