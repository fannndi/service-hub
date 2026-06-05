import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { UploadService } from './uploads.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

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
    return this.uploadService.generatePresignedUrl(
      dto.fileName, dto.mimeType ?? dto.contentType ?? 'application/octet-stream', dto.folder,
    );
  }
}
