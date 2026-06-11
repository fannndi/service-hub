import { IsString, IsNotEmpty, MinLength } from 'class-validator';
import { Transform } from 'class-transformer';
import { normalizePhone } from '../../../common/utils';

export class StoreLoginDto {
  @IsString()
  @IsNotEmpty()
  @Transform(({ value }: { value: string }) => normalizePhone(value))
  phoneNumber: string;

  @IsString()
  @IsNotEmpty()
  password: string;
}

export class StoreChangePasswordDto {
  @IsString()
  @IsNotEmpty()
  oldPassword: string;

  @IsString()
  @MinLength(8)
  newPassword: string;
}
