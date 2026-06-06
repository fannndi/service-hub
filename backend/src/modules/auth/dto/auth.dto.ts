import { IsString, IsNotEmpty, MinLength } from 'class-validator';
import { Transform } from 'class-transformer';

export function normalizePhone(phone: string): string {
  const d = phone.replace(/\D/g, '');
  if (d.startsWith('62')) return `0${d.slice(2)}`;
  if (d.startsWith('0'))  return d;
  return `0${d}`;
}

export class LoginDto {
  @IsString() @IsNotEmpty()
  @Transform(({ value }) => normalizePhone(value))
  phoneNumber: string;

  @IsString() @IsNotEmpty()
  password: string;
}

export class ChangePasswordDto {
  @IsString() @IsNotEmpty() oldPassword: string;
  @IsString() @MinLength(8) newPassword: string;
}

export class RefreshTokenDto {
  @IsString() @IsNotEmpty() refreshToken: string;
}
