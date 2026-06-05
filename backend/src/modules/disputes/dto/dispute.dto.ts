import {
  IsString, IsEnum, IsOptional, IsArray, MinLength,
} from 'class-validator';

export class CreateDisputeDto {
  @IsEnum(['warranty_claim', 'service_quality', 'wrong_diagnosis', 'other']) disputeType: string;
  @IsString() @MinLength(20) description: string;
  @IsOptional() @IsArray() @IsString({ each: true }) evidenceUrls?: string[];
}

export class RespondDisputeDto {
  @IsEnum(['store_accepted', 'store_rejected']) decision: string;
  @IsString() @MinLength(10) storeResponse: string;
}
