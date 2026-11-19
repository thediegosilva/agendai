import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/format.dart';
import 'models.dart';

final bookingRepositoryProvider = Provider(
  (ref) => BookingRepository(ref.watch(dioProvider)),
);

/// Busca de negócios pelo nome ('' = todos).
final businessSearchProvider = FutureProvider.autoDispose
    .family<List<Business>, String>(
      (ref, q) => ref.watch(bookingRepositoryProvider).search(q),
    );

final businessProvider = FutureProvider.autoDispose.family<Business, String>(
  (ref, id) => ref.watch(bookingRepositoryProvider).business(id),
);

typedef SlotsArgs = ({String businessId, String serviceId, DateTime day});

final slotsProvider = FutureProvider.autoDispose
    .family<List<DateTime>, SlotsArgs>(
      (ref, a) => ref
          .watch(bookingRepositoryProvider)
          .availability(a.businessId, a.serviceId, a.day),
    );

final myAppointmentsProvider = FutureProvider.autoDispose<List<Appointment>>(
  (ref) => ref.watch(bookingRepositoryProvider).myAppointments(),
);

class BookingRepository {
  BookingRepository(this._dio);

  final Dio _dio;

  Future<List<Business>> search(String q) async {
    final res = await _dio.get<List<dynamic>>(
      '/businesses',
      queryParameters: {if (q.trim().isNotEmpty) 'q': q.trim()},
    );
    return [
      for (final b in res.data!) Business.fromJson(b as Map<String, dynamic>),
    ];
  }

  Future<Business> business(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('/businesses/$id');
    return Business.fromJson(res.data!);
  }

  Future<List<DateTime>> availability(
    String businessId,
    String serviceId,
    DateTime day,
  ) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/businesses/$businessId/availability',
      queryParameters: {'serviceId': serviceId, 'date': isoDate(day)},
    );
    return [
      for (final s in res.data!['slots'] as List)
        DateTime.parse(s as String).toLocal(),
    ];
  }

  Future<Appointment> book(String serviceId, DateTime startsAt) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/appointments',
      data: {
        'serviceId': serviceId,
        'startsAt': startsAt.toUtc().toIso8601String(),
      },
    );
    return Appointment.fromJson(res.data!);
  }

  Future<List<Appointment>> myAppointments() async {
    final res = await _dio.get<List<dynamic>>('/appointments/mine');
    return [
      for (final a in res.data!)
        Appointment.fromJson(a as Map<String, dynamic>),
    ];
  }

  Future<void> cancel(String appointmentId) =>
      _dio.patch<void>('/appointments/$appointmentId/cancel');
}
