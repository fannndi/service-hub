import { IsString, IsNotEmpty, IsOptional, IsBoolean, MinLength } from 'class-validator';

export class AdminLoginDto {
  @IsString() @IsNotEmpty()
  username: string;

  @IsString() @IsNotEmpty()
  password: string;
}

export class CreateStoreDto {
  @IsString() @IsNotEmpty()
  storeName: string;

  @IsString() @IsNotEmpty()
  address: string;

  @IsString() @IsNotEmpty()
  storePhone: string;

  @IsString() @IsNotEmpty()
  adminName: string;

  @IsString() @IsNotEmpty()
  adminPhone: string;

  @IsString() @MinLength(8)
  password: string;

  @IsBoolean()
  handlesAndroid: boolean;

  @IsBoolean()
  handlesIos: boolean;

  @IsOptional()
  operationalHours?: Record<string, string>;
}
