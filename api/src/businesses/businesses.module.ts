import { Module } from '@nestjs/common';
import {
  BusinessesController,
  ServicesController,
} from './businesses.controller';
import { BusinessesService } from './businesses.service';

@Module({
  controllers: [BusinessesController, ServicesController],
  providers: [BusinessesService],
  exports: [BusinessesService],
})
export class BusinessesModule {}
