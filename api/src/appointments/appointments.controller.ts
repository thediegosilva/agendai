import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
} from '@nestjs/common';
import { ApiOperation, ApiProperty, ApiTags } from '@nestjs/swagger';
import { IsISO8601, IsUUID } from 'class-validator';
import type { PublicUser } from '../auth/auth.service';
import { Auth, CurrentUser } from '../common/auth';
import { AppointmentsService } from './appointments.service';

export class CreateAppointmentDto {
  @ApiProperty()
  @IsUUID()
  serviceId!: string;

  @ApiProperty({ example: '2026-11-20T12:00:00.000Z' })
  @IsISO8601({ strict: true })
  startsAt!: string;
}

@ApiTags('appointments')
@Controller('appointments')
export class AppointmentsController {
  constructor(private readonly appointments: AppointmentsService) {}

  @Post()
  @Auth()
  @ApiOperation({ summary: 'Marca um horário (409 se já estiver ocupado)' })
  create(@CurrentUser() user: PublicUser, @Body() dto: CreateAppointmentDto) {
    return this.appointments.create(user.id, dto.serviceId, dto.startsAt);
  }

  @Get('mine')
  @Auth()
  @ApiOperation({ summary: 'Agendamentos do usuário logado' })
  mine(@CurrentUser() user: PublicUser) {
    return this.appointments.mine(user.id);
  }

  @Patch(':id/cancel')
  @Auth()
  cancel(
    @CurrentUser() user: PublicUser,
    @Param('id', new ParseUUIDPipe({ version: '4' })) id: string,
  ) {
    return this.appointments.cancel(user, id);
  }
}
