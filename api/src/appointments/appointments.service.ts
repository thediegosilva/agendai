import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AppointmentStatus } from '@prisma/client';
import type { PublicUser } from '../auth/auth.service';
import { localDateOf, weekdayOf } from '../availability/slots';
import { BusinessesService } from '../businesses/businesses.service';
import { PrismaService } from '../prisma/prisma.service';

const MINUTE = 60_000;

const appointmentInclude = {
  service: { select: { name: true, durationMinutes: true } },
  business: { select: { id: true, name: true, address: true } },
};

@Injectable()
export class AppointmentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly businesses: BusinessesService,
  ) {}

  /**
   * Cria um agendamento sem risco de conflito.
   *
   * Dentro de uma transação, um advisory lock por negócio serializa as
   * reservas concorrentes: duas pessoas tentando o mesmo horário ao mesmo
   * tempo são processadas uma de cada vez, e a segunda recebe 409.
   */
  async create(clientId: string, serviceId: string, startsAtIso: string) {
    const startsAt = new Date(startsAtIso);
    if (Number.isNaN(startsAt.getTime())) {
      throw new BadRequestException('Horário inválido');
    }

    const service = await this.prisma.service.findFirst({
      where: { id: serviceId, active: true },
    });
    if (!service) throw new NotFoundException('Serviço não encontrado');

    const offset = this.businesses.utcOffsetMinutes;
    const date = localDateOf(startsAt, offset);

    return this.prisma.$transaction(async (tx) => {
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${service.businessId}))`;

      const free = await this.businesses.slotsFor(tx, {
        businessId: service.businessId,
        date,
        weekday: weekdayOf(date),
        durationMinutes: service.durationMinutes,
      });
      if (!free.some((s) => s.getTime() === startsAt.getTime())) {
        throw new ConflictException(
          'Esse horário não está mais disponível. Escolha outro.',
        );
      }

      return tx.appointment.create({
        data: {
          businessId: service.businessId,
          serviceId: service.id,
          clientId,
          startsAt,
          endsAt: new Date(
            startsAt.getTime() + service.durationMinutes * MINUTE,
          ),
          priceCents: service.priceCents,
        },
        include: appointmentInclude,
      });
    });
  }

  mine(clientId: string) {
    return this.prisma.appointment.findMany({
      where: { clientId },
      include: appointmentInclude,
      orderBy: { startsAt: 'desc' },
      take: 100,
    });
  }

  /** Cancela: permitido ao cliente que marcou ou ao dono do negócio. */
  async cancel(user: PublicUser, id: string) {
    const appt = await this.prisma.appointment.findUnique({
      where: { id },
      include: { business: { select: { ownerId: true } } },
    });
    if (!appt) throw new NotFoundException('Agendamento não encontrado');
    if (appt.clientId !== user.id && appt.business.ownerId !== user.id) {
      throw new ForbiddenException('Você não pode cancelar este agendamento');
    }
    if (appt.status !== AppointmentStatus.SCHEDULED) {
      throw new BadRequestException('Este agendamento não está ativo');
    }
    if (appt.startsAt <= new Date()) {
      throw new BadRequestException(
        'Não é possível cancelar um horário que já começou',
      );
    }
    return this.prisma.appointment.update({
      where: { id },
      data: { status: AppointmentStatus.CANCELED },
      include: appointmentInclude,
    });
  }
}
