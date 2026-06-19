import { Type, Transform } from 'class-transformer';
import {
  IsString,
  IsEnum,
  IsArray,
  ValidateNested,
  IsNotEmpty,
  IsOptional,
  IsUUID,
  MinLength,
  ArrayMinSize,
  IsNumber,
  Min,
} from 'class-validator';
import { normalizePhone } from '../../../common/utils';

export class CreateOrderItemDto {
  @IsEnum([
    'screen_replacement',
    'battery_replacement',
    'charging_port',
    'camera',
    'other',
  ])
  serviceType: string;

  @IsString()
  @MinLength(10)
  complaint: string;

  @IsOptional()
  @IsUUID()
  sparepartId?: string;

  // Backward-compatible with older app builds. Server calculates trusted price.
  @IsOptional()
  @IsNumber()
  @Min(0)
  itemPrice?: number;
}

export class CreateOrderDto {
  @IsEnum(['android', 'ios'])
  deviceType: string;

  @IsString()
  @IsNotEmpty()
  brand: string;

  @IsString()
  @IsNotEmpty()
  deviceModel: string;

  @IsString()
  @IsNotEmpty()
  storeId: string;

  @IsEnum(['walk_in', 'courier_pickup'])
  deliveryMethod: string;

  @IsOptional()
  @IsString()
  deliveryAddress?: string;

  @IsString()
  @IsNotEmpty()
  @Transform(
    ({ value, obj }: { value: string; obj: Record<string, unknown> }) =>
      value ?? obj?.fullName ?? '',
  )
  customerName: string;

  // Backward-compatible alias for older customer app payloads.
  @IsOptional()
  @IsString()
  fullName?: string;

  @IsString()
  @Transform(({ value }: { value: string }) => normalizePhone(value))
  phoneNumber: string;

  @IsOptional()
  @IsString()
  couponCode?: string;

  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => CreateOrderItemDto)
  items: CreateOrderItemDto[];
}

export class DiagnosisItemDto {
  @IsUUID()
  orderItemId: string;

  @IsEnum(['confirmed', 'replaced', 'cancelled'])
  status: string;

  @IsOptional()
  @IsUUID()
  replacedSparepartId?: string;

  @IsNumber()
  @Min(0)
  finalItemPrice: number;

  @IsOptional()
  @IsString()
  technicianNote?: string;
}

export class SubmitDiagnosisDto {
  @IsOptional()
  @IsString()
  diagnosisNote?: string;

  @IsNumber()
  @Min(0)
  serviceFee: number;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => DiagnosisItemDto)
  items: DiagnosisItemDto[];
}

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
