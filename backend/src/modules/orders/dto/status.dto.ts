import { IsString, IsEnum, IsOptional } from 'class-validator';

export class UpdateOrderStatusDto {
  @IsEnum([
    'device_received',
    'diagnosing',
    'waiting_sparepart',
    'repairing',
    'quality_check',
    'waiting_payment',
    'cancelled',
  ])
  status: string;

  @IsOptional()
  @IsString()
  note?: string;
}
