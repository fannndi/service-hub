import { IsString, IsNotEmpty, MinLength } from 'class-validator';
import { Transform } from 'class-transformer';
import { normalizePhone } from '../../auth/dto/auth.dto';

export class StoreLoginDto {
  @IsString() @IsNotEmpty()
  @Transform(({ value }) => normalizePhone(value))
  phoneNumber: string;

  @IsString() @IsNotEmpty()
  password: string;
}

export class StoreChangePasswordDto {
  @IsString() @IsNotEmpty() oldPassword: string;
  @IsString() @MinLength(8) newPassword: string;
}
