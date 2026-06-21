import { IsString, IsNotEmpty, IsOptional, IsBoolean, MinLength, IsEnum } from 'class-validator';

export class AdminLoginDto {
  @IsString()
  @IsNotEmpty()
  username: string;

  @IsString()
  @IsNotEmpty()
  password: string;
}

export class ChangePasswordDto {
  @IsString()
  @MinLength(6)
  newPassword: string;
}

export class CreateStoreDto {
  @IsString()
  @IsNotEmpty()
  storeName: string;

  @IsString()
  @IsNotEmpty()
  address: string;

  @IsString()
  @IsNotEmpty()
  storePhone: string;

  @IsString()
  @IsNotEmpty()
  adminName: string;

  @IsString()
  @IsNotEmpty()
  adminPhone: string;

  @IsString()
  @MinLength(8)
  password: string;

  @IsBoolean()
  handlesAndroid: boolean;

  @IsBoolean()
  handlesIos: boolean;

  @IsOptional()
  operationalHours?: Record<string, string>;
}

export class UpdateUserDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  fullName?: string;

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  phoneNumber?: string;

  @IsOptional()
  @IsString()
  address?: string | null;

  @IsOptional()
  @IsEnum(['active', 'suspended', 'deleted'])
  accountStatus?: string;

  @IsOptional()
  @IsBoolean()
  isFirstLogin?: boolean;

  @IsOptional()
  @IsBoolean()
  isCredentialSent?: boolean;
}

export class UpdateStoreDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  storeName?: string;

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  address?: string;

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  phoneNumber?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  operationalHours?: Record<string, string>;
}
