import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Put,
  Query,
} from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import type { PublicUser } from '../auth/auth.service';
import { Auth, CurrentUser } from '../common/auth';
import { BusinessesService } from './businesses.service';
import {
  AvailabilityQueryDto,
  CreateBusinessDto,
  CreateServiceDto,
  SearchQueryDto,
  SetHoursDto,
  UpdateBusinessDto,
  UpdateServiceDto,
} from './dto';

const uuid = new ParseUUIDPipe({ version: '4' });

@ApiTags('businesses')
@Controller('businesses')
export class BusinessesController {
  constructor(private readonly businesses: BusinessesService) {}

  @Get()
  @ApiOperation({ summary: 'Busca negócios pelo nome (público)' })
  search(@Query() { q }: SearchQueryDto) {
    return this.businesses.search(q);
  }

  @Get('mine')
  @Auth(Role.OWNER)
  @ApiOperation({ summary: 'Negócios do dono logado' })
  mine(@CurrentUser() user: PublicUser) {
    return this.businesses.mine(user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Detalhes, serviços e horários (público)' })
  findOne(@Param('id', uuid) id: string) {
    return this.businesses.findOne(id);
  }

  @Get(':id/availability')
  @ApiOperation({ summary: 'Horários livres de um serviço em um dia' })
  availability(
    @Param('id', uuid) id: string,
    @Query() q: AvailabilityQueryDto,
  ) {
    return this.businesses.availability(id, q.serviceId, q.date);
  }

  @Post()
  @Auth(Role.OWNER)
  create(@CurrentUser() user: PublicUser, @Body() dto: CreateBusinessDto) {
    return this.businesses.create(user.id, dto);
  }

  @Patch(':id')
  @Auth(Role.OWNER)
  update(
    @CurrentUser() user: PublicUser,
    @Param('id', uuid) id: string,
    @Body() dto: UpdateBusinessDto,
  ) {
    return this.businesses.update(user.id, id, dto);
  }

  @Put(':id/hours')
  @Auth(Role.OWNER)
  @ApiOperation({ summary: 'Substitui o horário de funcionamento semanal' })
  setHours(
    @CurrentUser() user: PublicUser,
    @Param('id', uuid) id: string,
    @Body() dto: SetHoursDto,
  ) {
    return this.businesses.setHours(user.id, id, dto);
  }

  @Post(':id/services')
  @Auth(Role.OWNER)
  addService(
    @CurrentUser() user: PublicUser,
    @Param('id', uuid) id: string,
    @Body() dto: CreateServiceDto,
  ) {
    return this.businesses.addService(user.id, id, dto);
  }

  @Get(':id/appointments')
  @Auth(Role.OWNER)
  @ApiOperation({ summary: 'Agendamentos do negócio (a partir de ontem)' })
  appointments(@CurrentUser() user: PublicUser, @Param('id', uuid) id: string) {
    return this.businesses.appointments(user.id, id);
  }
}

@ApiTags('services')
@Controller('services')
export class ServicesController {
  constructor(private readonly businesses: BusinessesService) {}

  @Patch(':id')
  @Auth(Role.OWNER)
  update(
    @CurrentUser() user: PublicUser,
    @Param('id', uuid) id: string,
    @Body() dto: UpdateServiceDto,
  ) {
    return this.businesses.updateService(user.id, id, dto);
  }

  @Delete(':id')
  @Auth(Role.OWNER)
  @ApiOperation({
    summary: 'Remove o serviço (ou desativa, se já tiver agendamentos)',
  })
  remove(@CurrentUser() user: PublicUser, @Param('id', uuid) id: string) {
    return this.businesses.removeService(user.id, id);
  }
}
