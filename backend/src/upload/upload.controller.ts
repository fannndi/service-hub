import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { UploadService } from './upload.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';

@Controller('uploads')
export class UploadController {
  constructor(private readonly uploadService: UploadService) {}

  @UseGuards(JwtAuthGuard)
  @Post('presign')
  getPresignedUrl(@Body() body: { fileName: string; mimeType: string; folder: string }) {
    return this.uploadService.getPresignedUrl(body.fileName, body.mimeType, body.folder);
  }
}
