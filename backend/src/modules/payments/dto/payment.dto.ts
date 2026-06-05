import {
  IsNumber, IsEnum, IsOptional, IsString, Min,
} from 'class-validator';

export class CreatePaymentDto {
  @IsNumber() @Min(1000) amount: number;
  @IsEnum(['transfer_bank', 'qris', 'cash', 'ewallet']) paymentMethod: string;
  @IsEnum(['deposit', 'final_payment']) paymentType: string;
  @IsOptional() @IsString() proofUrl?: string;
}

export class ConfirmPaymentDto {
  @IsOptional() @IsString() note?: string;
}
