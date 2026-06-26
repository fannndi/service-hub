import { IsString, IsNotEmpty } from 'class-validator';
import { Transform } from 'class-transformer';
import { normalizePhone } from '../../../common/utils';

export class GuestTrackDto {
  @IsString()
  @IsNotEmpty()
  orderNumber: string;

  @IsString()
  @IsNotEmpty()
  @Transform(({ value }: { value: string }) => normalizePhone(value))
  phoneNumber: string;
}

export class GuestCredentialsDto {
  @IsString()
  @IsNotEmpty()
  orderId: string;

  @IsString()
  @IsNotEmpty()
  @Transform(({ value }: { value: string }) => normalizePhone(value))
  phoneNumber: string;
}
