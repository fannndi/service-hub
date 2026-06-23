import { IsString, IsEnum, IsArray, ValidateNested, IsOptional, IsUUID, IsNumber, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class DiagnosisItemDto {
  @IsUUID()
  orderItemId: string;

  @IsEnum(['confirmed', 'replaced', 'cancelled'])
  status: string;

  @IsOptional()
  @IsUUID()
  replacedSparepartId?: string;

  @IsNumber()
  @Min(0)
  finalItemPrice: number;

  @IsOptional()
  @IsString()
  technicianNote?: string;
}

export class SubmitDiagnosisDto {
  @IsOptional()
  @IsString()
  diagnosisNote?: string;

  @IsNumber()
  @Min(0)
  serviceFee: number;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => DiagnosisItemDto)
  items: DiagnosisItemDto[];
}
