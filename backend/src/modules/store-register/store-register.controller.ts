import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { StoreRegisterService } from './store-register.service';
import { RegisterStoreDto } from './dto/register-store.dto';

@ApiTags('Store Register')
@Controller('store')
export class StoreRegisterController {
  constructor(private readonly storeRegisterService: StoreRegisterService) {}

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  async register(@Body() dto: RegisterStoreDto) {
    return this.storeRegisterService.register(dto);
  }
}
