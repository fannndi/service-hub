import { Type, Transform } from 'class-transformer';
import {
  IsString,
  IsEnum,
  IsArray,
  ValidateNested,
  IsNotEmpty,
  IsOptional,
  IsNumber,
  Min,
  MinLength,
  ArrayMinSize,
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
  @IsString()
  sparepartId?: string;

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
