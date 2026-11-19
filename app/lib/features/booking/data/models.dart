class OpeningHours {
  const OpeningHours({
    required this.weekday,
    required this.openMinute,
    required this.closeMinute,
  });

  /// 0 = domingo ... 6 = sábado
  final int weekday;
  final int openMinute;
  final int closeMinute;

  factory OpeningHours.fromJson(Map<String, dynamic> j) => OpeningHours(
    weekday: j['weekday'] as int,
    openMinute: j['openMinute'] as int,
    closeMinute: j['closeMinute'] as int,
  );

  Map<String, dynamic> toJson() => {
    'weekday': weekday,
    'openMinute': openMinute,
    'closeMinute': closeMinute,
  };
}

class BusinessService {
  const BusinessService({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.priceCents,
    required this.active,
  });

  final String id;
  final String name;
  final int durationMinutes;
  final int priceCents;
  final bool active;

  factory BusinessService.fromJson(Map<String, dynamic> j) => BusinessService(
    id: j['id'] as String,
    name: j['name'] as String,
    durationMinutes: j['durationMinutes'] as int,
    priceCents: j['priceCents'] as int,
    active: j['active'] as bool? ?? true,
  );
}

class Business {
  const Business({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.services = const [],
    this.hours = const [],
    this.serviceCount,
    this.minPriceCents,
  });

  final String id;
  final String name;
  final String? description;
  final String? address;
  final List<BusinessService> services;
  final List<OpeningHours> hours;

  /// Só vêm na listagem/busca.
  final int? serviceCount;
  final int? minPriceCents;

  OpeningHours? hoursFor(int weekday) =>
      hours.where((h) => h.weekday == weekday).firstOrNull;

  factory Business.fromJson(Map<String, dynamic> j) => Business(
    id: j['id'] as String,
    name: j['name'] as String,
    description: j['description'] as String?,
    address: j['address'] as String?,
    services: [
      for (final s in (j['services'] as List?) ?? const [])
        if (s is Map<String, dynamic> && s.containsKey('id'))
          BusinessService.fromJson(s),
    ],
    hours: [
      for (final h in (j['hours'] as List?) ?? const [])
        OpeningHours.fromJson(h as Map<String, dynamic>),
    ],
    serviceCount: j['serviceCount'] as int?,
    minPriceCents: j['minPriceCents'] as int?,
  );
}

enum AppointmentStatus { scheduled, canceled, completed }

class Appointment {
  const Appointment({
    required this.id,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.priceCents,
    required this.serviceName,
    this.businessId,
    this.businessName,
    this.businessAddress,
    this.clientName,
    this.clientPhone,
  });

  final String id;
  final DateTime startsAt;
  final DateTime endsAt;
  final AppointmentStatus status;
  final int priceCents;
  final String serviceName;
  final String? businessId;
  final String? businessName;
  final String? businessAddress;
  final String? clientName;
  final String? clientPhone;

  bool get isUpcoming =>
      status == AppointmentStatus.scheduled && startsAt.isAfter(DateTime.now());

  factory Appointment.fromJson(Map<String, dynamic> j) {
    final business = j['business'] as Map<String, dynamic>?;
    final client = j['client'] as Map<String, dynamic>?;
    return Appointment(
      id: j['id'] as String,
      startsAt: DateTime.parse(j['startsAt'] as String).toLocal(),
      endsAt: DateTime.parse(j['endsAt'] as String).toLocal(),
      status: switch (j['status']) {
        'CANCELED' => AppointmentStatus.canceled,
        'COMPLETED' => AppointmentStatus.completed,
        _ => AppointmentStatus.scheduled,
      },
      priceCents: j['priceCents'] as int,
      serviceName: (j['service'] as Map<String, dynamic>)['name'] as String,
      businessId: business?['id'] as String?,
      businessName: business?['name'] as String?,
      businessAddress: business?['address'] as String?,
      clientName: client?['name'] as String?,
      clientPhone: client?['phone'] as String?,
    );
  }
}
