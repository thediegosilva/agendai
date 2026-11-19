import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppointmentStatus, Prisma } from '@prisma/client';
import {
  computeSlots,
  Interval,
  localMidnight,
  weekdayOf,
} from '../availability/slots';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreateBusinessDto,
  CreateServiceDto,
  SetHoursDto,
  UpdateBusinessDto,
  UpdateServiceDto,
} from './dto';

const DAY = 24 * 60 * 60_000;

/** Campos públicos de um negócio para listagens. */
const listInclude = {
  services: {
    where: { active: true },
    select: { priceCents: true },
  },
  hours: { orderBy: { weekday: 'asc' } },
} satisfies Prisma.BusinessInclude;

type PrismaLike = Prisma.TransactionClient | PrismaService;

@Injectable()
export class BusinessesService {
  readonly utcOffsetMinutes: number;
  readonly slotStepMinutes: number;

  constructor(
    private readonly prisma: PrismaService,
    config: ConfigService,
  ) {
    this.utcOffsetMinutes = Number(
      config.get('BUSINESS_UTC_OFFSET_MINUTES', -180),
    );
    this.slotStepMinutes = Number(config.get('SLOT_STEP_MINUTES', 30));
  }

  // ---------- Público ----------

  async search(q?: string) {
    const businesses = await this.prisma.business.findMany({
      where: q?.trim()
        ? { name: { contains: q.trim(), mode: 'insensitive' } }
        : undefined,
      include: listInclude,
      orderBy: { name: 'asc' },
      take: 50,
    });
    return businesses.map(({ services, ...b }) => ({
      ...b,
      serviceCount: services.length,
      minPriceCents: services.length
        ? Math.min(...services.map((s) => s.priceCents))
        : null,
    }));
  }

  async findOne(id: string) {
    const business = await this.prisma.business.findUnique({
      where: { id },
      include: {
        services: { where: { active: true }, orderBy: { name: 'asc' } },
        hours: { orderBy: { weekday: 'asc' } },
        owner: { select: { name: true } },
      },
    });
    if (!business) throw new NotFoundException('Negócio não encontrado');
    return business;
  }

  async availability(businessId: string, serviceId: string, date: string) {
    let weekday: number;
    try {
      weekday = weekdayOf(date);
    } catch {
      throw new BadRequestException('Data inválida');
    }
    const service = await this.prisma.service.findFirst({
      where: { id: serviceId, businessId, active: true },
    });
    if (!service) throw new NotFoundException('Serviço não encontrado');

    const slots = await this.slotsFor(this.prisma, {
      businessId,
      date,
      weekday,
      durationMinutes: service.durationMinutes,
    });
    return { date, durationMinutes: service.durationMinutes, slots };
  }

  /** Horários livres de um dia; usado também na criação de agendamento. */
  async slotsFor(
    db: PrismaLike,
    p: {
      businessId: string;
      date: string;
      weekday: number;
      durationMinutes: number;
    },
  ): Promise<Date[]> {
    const dayStart = localMidnight(p.date, this.utcOffsetMinutes);
    const dayEnd = new Date(dayStart.getTime() + DAY);
    const window = { lt: dayEnd };

    const [hours, appointments, blocks] = await Promise.all([
      db.businessHours.findUnique({
        where: {
          businessId_weekday: { businessId: p.businessId, weekday: p.weekday },
        },
      }),
      db.appointment.findMany({
        where: {
          businessId: p.businessId,
          status: AppointmentStatus.SCHEDULED,
          startsAt: window,
          endsAt: { gt: dayStart },
        },
        select: { startsAt: true, endsAt: true },
      }),
      db.timeBlock.findMany({
        where: {
          businessId: p.businessId,
          startsAt: window,
          endsAt: { gt: dayStart },
        },
        select: { startsAt: true, endsAt: true },
      }),
    ]);

    const busy: Interval[] = [...appointments, ...blocks].map((i) => ({
      start: i.startsAt,
      end: i.endsAt,
    }));
    return computeSlots({
      date: p.date,
      hours,
      durationMinutes: p.durationMinutes,
      stepMinutes: this.slotStepMinutes,
      busy,
      now: new Date(),
      utcOffsetMinutes: this.utcOffsetMinutes,
    });
  }

  // ---------- Dono ----------

  mine(ownerId: string) {
    return this.prisma.business.findMany({
      where: { ownerId },
      include: {
        services: { orderBy: [{ active: 'desc' }, { name: 'asc' }] },
        hours: { orderBy: { weekday: 'asc' } },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  create(ownerId: string, dto: CreateBusinessDto) {
    return this.prisma.business.create({
      data: {
        ...this.clean(dto),
        name: dto.name.trim(),
        ownerId,
        // Horário padrão: segunda a sábado, 9h às 18h.
        hours: {
          create: [1, 2, 3, 4, 5, 6].map((weekday) => ({
            weekday,
            openMinute: 9 * 60,
            closeMinute: 18 * 60,
          })),
        },
      },
      include: { services: true, hours: { orderBy: { weekday: 'asc' } } },
    });
  }

  async update(ownerId: string, id: string, dto: UpdateBusinessDto) {
    await this.assertOwner(ownerId, id);
    return this.prisma.business.update({
      where: { id },
      data: this.clean(dto),
    });
  }

  async setHours(ownerId: string, id: string, dto: SetHoursDto) {
    await this.assertOwner(ownerId, id);
    const weekdays = new Set<number>();
    for (const d of dto.days) {
      if (d.closeMinute <= d.openMinute) {
        throw new BadRequestException(
          'O fechamento deve ser depois da abertura',
        );
      }
      if (weekdays.has(d.weekday)) {
        throw new BadRequestException('Dia da semana repetido');
      }
      weekdays.add(d.weekday);
    }
    return this.prisma.$transaction(async (tx) => {
      await tx.businessHours.deleteMany({ where: { businessId: id } });
      await tx.businessHours.createMany({
        data: dto.days.map((d) => ({ ...d, businessId: id })),
      });
      return tx.businessHours.findMany({
        where: { businessId: id },
        orderBy: { weekday: 'asc' },
      });
    });
  }

  async addService(ownerId: string, businessId: string, dto: CreateServiceDto) {
    await this.assertOwner(ownerId, businessId);
    return this.prisma.service.create({
      data: { ...dto, name: dto.name.trim(), businessId },
    });
  }

  async updateService(ownerId: string, id: string, dto: UpdateServiceDto) {
    await this.assertServiceOwner(ownerId, id);
    return this.prisma.service.update({
      where: { id },
      data: { ...dto, name: dto.name?.trim() },
    });
  }

  /**
   * Remove o serviço. Se já tiver agendamentos, apenas desativa,
   * para preservar o histórico.
   */
  async removeService(ownerId: string, id: string) {
    await this.assertServiceOwner(ownerId, id);
    const used = await this.prisma.appointment.count({
      where: { serviceId: id },
    });
    if (used) {
      await this.prisma.service.update({
        where: { id },
        data: { active: false },
      });
      return { deleted: false, deactivated: true };
    }
    await this.prisma.service.delete({ where: { id } });
    return { deleted: true, deactivated: false };
  }

  async appointments(ownerId: string, businessId: string, from?: Date) {
    await this.assertOwner(ownerId, businessId);
    return this.prisma.appointment.findMany({
      where: {
        businessId,
        startsAt: { gte: from ?? new Date(Date.now() - DAY) },
      },
      include: {
        service: { select: { name: true, durationMinutes: true } },
        client: { select: { name: true, phone: true, email: true } },
      },
      orderBy: { startsAt: 'asc' },
      take: 100,
    });
  }

  // ---------- Helpers ----------

  async assertOwner(ownerId: string, businessId: string) {
    const business = await this.prisma.business.findUnique({
      where: { id: businessId },
      select: { ownerId: true },
    });
    if (!business) throw new NotFoundException('Negócio não encontrado');
    if (business.ownerId !== ownerId) {
      throw new ForbiddenException('Este negócio não é seu');
    }
  }

  private async assertServiceOwner(ownerId: string, serviceId: string) {
    const service = await this.prisma.service.findUnique({
      where: { id: serviceId },
      select: { business: { select: { ownerId: true } } },
    });
    if (!service) throw new NotFoundException('Serviço não encontrado');
    if (service.business.ownerId !== ownerId) {
      throw new ForbiddenException('Este serviço não é seu');
    }
  }

  /** Converte strings vazias em null para campos opcionais. */
  private clean<T extends Partial<CreateBusinessDto>>(dto: T) {
    const opt = (v?: string) =>
      v === undefined ? undefined : v.trim() || null;
    return {
      ...dto,
      name: dto.name?.trim(),
      description: opt(dto.description),
      address: opt(dto.address),
    };
  }
}
