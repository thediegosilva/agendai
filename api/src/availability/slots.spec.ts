import {
  computeSlots,
  localDateOf,
  localMidnight,
  SlotQuery,
  weekdayOf,
} from './slots';

const SP = -180; // São Paulo, UTC-3

/** Horário local de SP → instante UTC. */
const at = (date: string, hhmm: string) =>
  new Date(`${date}T${hhmm}:00.000-03:00`);

const hhmm = (d: Date) =>
  new Date(d.getTime() + SP * 60_000).toISOString().slice(11, 16);

const base: SlotQuery = {
  date: '2030-03-04', // segunda-feira
  hours: { openMinute: 9 * 60, closeMinute: 12 * 60 },
  durationMinutes: 60,
  stepMinutes: 30,
  busy: [],
  now: new Date('2030-01-01T00:00:00Z'),
  utcOffsetMinutes: SP,
};

describe('helpers de fuso', () => {
  it('meia-noite em SP é 03:00 UTC', () => {
    expect(localMidnight('2030-03-04', SP).toISOString()).toBe(
      '2030-03-04T03:00:00.000Z',
    );
  });

  it('calcula o dia da semana', () => {
    expect(weekdayOf('2030-03-04')).toBe(1);
    expect(weekdayOf('2030-03-03')).toBe(0);
  });

  it('converte instante para o dia local', () => {
    // 01:00 UTC do dia 5 ainda é dia 4 em SP
    expect(localDateOf(new Date('2030-03-05T01:00:00Z'), SP)).toBe(
      '2030-03-04',
    );
  });

  it('rejeita datas inválidas', () => {
    expect(() => weekdayOf('2030-02-30')).toThrow();
    expect(() => weekdayOf('amanhã')).toThrow();
  });
});

describe('computeSlots', () => {
  it('gera horários dentro do funcionamento respeitando a duração', () => {
    expect(computeSlots(base).map(hhmm)).toEqual([
      '09:00',
      '09:30',
      '10:00',
      '10:30',
      '11:00',
    ]);
  });

  it('retorna vazio quando o negócio está fechado', () => {
    expect(computeSlots({ ...base, hours: null })).toEqual([]);
  });

  it('remove horários que conflitam com agendamentos', () => {
    const slots = computeSlots({
      ...base,
      busy: [{ start: at(base.date, '10:00'), end: at(base.date, '10:30') }],
    });
    // 09:30-10:30 e 10:00-11:00 batem com 10:00-10:30
    expect(slots.map(hhmm)).toEqual(['09:00', '10:30', '11:00']);
  });

  it('permite encostar no fim de outro agendamento', () => {
    const slots = computeSlots({
      ...base,
      busy: [{ start: at(base.date, '09:00'), end: at(base.date, '10:00') }],
    });
    expect(slots.map(hhmm)).toEqual(['10:00', '10:30', '11:00']);
  });

  it('remove horários que já passaram', () => {
    const slots = computeSlots({ ...base, now: at(base.date, '10:15') });
    expect(slots.map(hhmm)).toEqual(['10:30', '11:00']);
  });

  it('respeita bloqueios que atravessam o dia inteiro', () => {
    const slots = computeSlots({
      ...base,
      busy: [
        {
          start: new Date('2030-03-03T00:00:00Z'),
          end: new Date('2030-03-06T00:00:00Z'),
        },
      ],
    });
    expect(slots).toEqual([]);
  });
});
