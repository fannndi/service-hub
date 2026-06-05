import { Module } from '@nestjs/common';
import { UploadService } from './uploads.service';
import { UploadsController } from './uploads.controller';

@Module({
  controllers: [UploadsController],
  providers: [UploadService],
  exports: [UploadService],
})
export class UploadsModule {}
