/**
 * Cálculo de horários disponíveis (função pura, sem banco).
 *
 * disponível = funcionamento do dia − agendamentos − bloqueios − passado
 *
 * Todas as datas são instantes UTC. O "dia" e o horário de funcionamento
 * são interpretados no fuso do negócio, dado como deslocamento em minutos
 * em relação ao UTC (ex.: São Paulo = -180).
 */

export interface Interval {
  start: Date;
  end: Date;
}

export interface OpeningHours {
  openMinute: number;
  closeMinute: number;
}

export interface SlotQuery {
  /** Dia no fuso do negócio, formato YYYY-MM-DD. */
  date: string;
  /** Horário de funcionamento desse dia; null = fechado. */
  hours: OpeningHours | null;
  durationMinutes: number;
  /** Intervalo entre inícios de horários oferecidos. */
  stepMinutes: number;
  /** Agendamentos e bloqueios que ocupam a agenda. */
  busy: Interval[];
  now: Date;
  utcOffsetMinutes: number;
}

const MINUTE = 60_000;

export function parseDate(date: string): { y: number; m: number; d: number } {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(date);
  if (!match) throw new Error(`Data inválida: ${date}`);
  const [y, m, d] = match.slice(1).map(Number);
  const check = new Date(Date.UTC(y, m - 1, d));
  if (check.getUTCMonth() !== m - 1 || check.getUTCDate() !== d) {
    throw new Error(`Data inválida: ${date}`);
  }
  return { y, m, d };
}

/** Instante UTC da meia-noite do dia `date` no fuso do negócio. */
export function localMidnight(date: string, utcOffsetMinutes: number): Date {
  const { y, m, d } = parseDate(date);
  return new Date(Date.UTC(y, m - 1, d) - utcOffsetMinutes * MINUTE);
}

/** Dia da semana (0 = domingo) de `date`. */
export function weekdayOf(date: string): number {
  const { y, m, d } = parseDate(date);
  return new Date(Date.UTC(y, m - 1, d)).getUTCDay();
}

/** Converte um instante para o dia (YYYY-MM-DD) no fuso do negócio. */
export function localDateOf(instant: Date, utcOffsetMinutes: number): string {
  return new Date(instant.getTime() + utcOffsetMinutes * MINUTE)
    .toISOString()
    .slice(0, 10);
}

export function overlaps(a: Interval, b: Interval): boolean {
  return a.start < b.end && b.start < a.end;
}

export function computeSlots(q: SlotQuery): Date[] {
  if (!q.hours || q.durationMinutes <= 0 || q.stepMinutes <= 0) return [];
  const midnight = localMidnight(q.date, q.utcOffsetMinutes).getTime();
  const slots: Date[] = [];

  for (
    let minute = q.hours.openMinute;
    minute + q.durationMinutes <= q.hours.closeMinute;
    minute += q.stepMinutes
  ) {
    const start = new Date(midnight + minute * MINUTE);
    const end = new Date(start.getTime() + q.durationMinutes * MINUTE);
    if (start <= q.now) continue;
    if (q.busy.some((b) => overlaps({ start, end }, b))) continue;
    slots.push(start);
  }
  return slots;
}
