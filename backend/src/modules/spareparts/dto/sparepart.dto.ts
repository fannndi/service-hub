import {
  IsString, IsEnum, IsOptional, IsNumber, IsNotEmpty, Min,
} from 'class-validator';

export class CreateSparepartDto {
  @IsString() @IsNotEmpty() brand: string;
  @IsString() @IsNotEmpty() deviceModel: string;
  @IsEnum(['screen_replacement', 'battery_replacement', 'charging_port', 'camera', 'other'])
  partType: string;
  @IsString() @IsNotEmpty() partName: string;
  @IsNumber() @Min(0) price: number;
  @IsNumber() @Min(0) qty: number;
  @IsOptional() @IsEnum(['available', 'preorder', 'discontinued']) status?: string;
}

export class UpdateSparepartDto {
  @IsOptional() @IsString() brand?: string;
  @IsOptional() @IsString() deviceModel?: string;
  @IsOptional() @IsEnum(['screen_replacement', 'battery_replacement', 'charging_port', 'camera', 'other'])
  partType?: string;
  @IsOptional() @IsString() partName?: string;
  @IsOptional() @IsNumber() @Min(0) price?: number;
  @IsOptional() @IsNumber() @Min(0) qty?: number;
  @IsOptional() @IsEnum(['available', 'preorder', 'discontinued']) status?: string;
}

export class AdjustStockDto {
  @IsNumber() @IsNotEmpty() delta: number;
}
