import { IsString, IsNotEmpty, MinLength, IsOptional, IsObject } from 'class-validator';
import { Transform } from 'class-transformer';
import { normalizePhone } from '../../../common/utils';

export class RegisterStoreDto {
  @IsString()
  @IsNotEmpty()
  storeName: string;

  @IsString()
  @IsNotEmpty()
  address: string;

  @IsString()
  @IsNotEmpty()
  @Transform(({ value }) => normalizePhone(value))
  storePhone: string;

  @IsOptional()
  @IsObject()
  operationalHours?: Record<string, any>;

  @IsString()
  @IsNotEmpty()
  applicantName: string;

  @IsString()
  @IsNotEmpty()
  @Transform(({ value }) => normalizePhone(value))
  applicantPhone: string;

  @IsString()
  @MinLength(8)
  password: string;
}
