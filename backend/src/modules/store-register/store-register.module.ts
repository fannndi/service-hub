import { Module } from '@nestjs/common';
import { StoreRegisterService } from './store-register.service';
import { StoreRegisterController } from './store-register.controller';

@Module({
  controllers: [StoreRegisterController],
  providers: [StoreRegisterService],
})
export class StoreRegisterModule {}
