/**
 * Dados de demonstração do AgendaÍ.
 *
 *   npx prisma db seed
 *
 * Idempotente: usuários são identificados pelo e-mail e os negócios pelo
 * nome + dono, então rodar de novo não duplica nada. Todas as contas usam
 * a senha "senhaForte123".
 */
import { AppointmentStatus, PrismaClient, Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();
const PASSWORD = 'senhaForte123';
const UTC_OFFSET_MIN = Number(process.env.BUSINESS_UTC_OFFSET_MINUTES ?? -180);
const MINUTE = 60_000;

const weekdays = (from: number, to: number, open: number, close: number) =>
  Array.from({ length: to - from + 1 }, (_, i) => ({
    weekday: from + i,
    openMinute: open * 60,
    closeMinute: close * 60,
  }));

const businesses = [
  {
    owner: {
      name: 'Zé Barbeiro',
      email: 'ze@barbearia.com',
      phone: '21999990000',
    },
    name: 'Barbearia do Zé',
    description: 'Cortes clássicos e modernos, com café e boa conversa.',
    address: 'Rua das Flores, 123 - Centro',
    hours: weekdays(0, 6, 8, 20),
    services: [
      { name: 'Corte masculino', durationMinutes: 30, priceCents: 4500 },
      { name: 'Barba premium', durationMinutes: 40, priceCents: 3500 },
      { name: 'Corte + barba', durationMinutes: 60, priceCents: 7000 },
    ],
  },
  {
    owner: { name: 'Bella Martins', email: 'bella@studiobella.com' },
    name: 'Studio Bella',
    description:
      'Salão de beleza: cabelo, coloração e maquiagem para todas as ocasiões.',
    address: 'Av. Atlântica, 450 - Copacabana',
    hours: weekdays(2, 6, 9, 19),
    services: [
      { name: 'Escova modelada', durationMinutes: 45, priceCents: 6000 },
      { name: 'Coloração completa', durationMinutes: 120, priceCents: 18000 },
      { name: 'Maquiagem social', durationMinutes: 60, priceCents: 12000 },
    ],
  },
  {
    owner: { name: 'Rafa Ink', email: 'rafa@inklab.com' },
    name: 'Ink Lab Tattoo',
    description: 'Estúdio de tatuagem autoral, fineline e old school.',
    address: 'Rua Augusta, 900 - Consolação',
    hours: weekdays(1, 5, 11, 20),
    services: [
      {
        name: 'Tattoo fineline pequena',
        durationMinutes: 90,
        priceCents: 25000,
      },
      { name: 'Sessão de orçamento', durationMinutes: 30, priceCents: 5000 },
    ],
  },
  {
    owner: { name: 'Carla Nunes', email: 'carla@unhasdacarla.com' },
    name: 'Unhas da Carla',
    description: 'Manicure e pedicure com esmaltação em gel.',
    address: 'Rua do Catete, 77 - Catete',
    hours: weekdays(1, 6, 9, 18),
    services: [
      { name: 'Manicure', durationMinutes: 40, priceCents: 3000 },
      { name: 'Pedicure', durationMinutes: 45, priceCents: 3500 },
      { name: 'Unha em gel', durationMinutes: 90, priceCents: 9000 },
    ],
  },
];

const clients = [
  { name: 'Maria Silva', email: 'maria@email.com', phone: '21988887777' },
  { name: 'Carlos Silva', email: 'carlos@email.com', phone: '21987654321' },
  { name: 'Ana Souza', email: 'ana@email.com', phone: '21998765432' },
  { name: 'Lucas Pereira', email: 'lucas@email.com', phone: '21976543210' },
];

async function upsertUser(
  u: { name: string; email: string; phone?: string },
  role: Role,
  passwordHash: string,
) {
  return prisma.user.upsert({
    where: { email: u.email },
    update: {},
    create: { ...u, role, passwordHash },
  });
}

/** Instante UTC de "hoje + dias, às hh:mm" no fuso do negócio. */
function localAt(daysFromToday: number, minuteOfDay: number) {
  const nowLocal = new Date(Date.now() + UTC_OFFSET_MIN * MINUTE);
  const midnightLocal = Date.UTC(
    nowLocal.getUTCFullYear(),
    nowLocal.getUTCMonth(),
    nowLocal.getUTCDate() + daysFromToday,
  );
  return new Date(midnightLocal + (minuteOfDay - UTC_OFFSET_MIN) * MINUTE);
}

async function main() {
  const passwordHash = await bcrypt.hash(PASSWORD, 10);

  const clientUsers = [];
  for (const c of clients) {
    clientUsers.push(await upsertUser(c, Role.CLIENT, passwordHash));
  }

  for (const b of businesses) {
    const owner = await upsertUser(b.owner, Role.OWNER, passwordHash);
    let business = await prisma.business.findFirst({
      where: { name: b.name, ownerId: owner.id },
    });
    if (!business) {
      business = await prisma.business.create({
        data: {
          name: b.name,
          description: b.description,
          address: b.address,
          ownerId: owner.id,
          hours: { create: b.hours },
        },
      });
    }
    for (const s of b.services) {
      const exists = await prisma.service.findFirst({
        where: { businessId: business.id, name: s.name },
      });
      if (!exists) {
        await prisma.service.create({
          data: { ...s, businessId: business.id },
        });
      }
    }
  }

  // Agenda do Zé: alguns atendimentos hoje (a partir da próxima hora cheia)
  // e nos próximos dias, para o painel não ficar vazio.
  const ze = await prisma.business.findFirstOrThrow({
    where: { name: 'Barbearia do Zé' },
    include: { services: true },
  });
  const svc = (name: string) => ze.services.find((s) => s.name === name)!;
  const nowLocalMin = (() => {
    const d = new Date(Date.now() + UTC_OFFSET_MIN * MINUTE);
    return d.getUTCHours() * 60 + d.getUTCMinutes();
  })();
  const firstToday = Math.max(9 * 60, Math.ceil((nowLocalMin + 30) / 60) * 60);

  const [, carlos, ana, lucas] = clientUsers;
  const plan = [
    { client: carlos, service: 'Corte masculino', day: 0, minute: firstToday },
    { client: ana, service: 'Barba premium', day: 0, minute: firstToday + 60 },
    {
      client: lucas,
      service: 'Corte + barba',
      day: 0,
      minute: firstToday + 120,
    },
    { client: carlos, service: 'Barba premium', day: 2, minute: 10 * 60 },
    { client: ana, service: 'Corte masculino', day: 3, minute: 16 * 60 },
  ].filter((p) => p.minute + svc(p.service).durationMinutes <= 20 * 60);

  for (const p of plan) {
    const service = svc(p.service);
    const startsAt = localAt(p.day, p.minute);
    const endsAt = new Date(
      startsAt.getTime() + service.durationMinutes * MINUTE,
    );
    const clash = await prisma.appointment.findFirst({
      where: {
        businessId: ze.id,
        status: AppointmentStatus.SCHEDULED,
        startsAt: { lt: endsAt },
        endsAt: { gt: startsAt },
      },
    });
    if (clash) continue;
    await prisma.appointment.create({
      data: {
        businessId: ze.id,
        serviceId: service.id,
        clientId: p.client.id,
        startsAt,
        endsAt,
        priceCents: service.priceCents,
      },
    });
  }

  console.log(
    `Seed ok: ${businesses.length} negócios, ${clients.length} clientes. ` +
      `Senha de todas as contas: ${PASSWORD}`,
  );
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
