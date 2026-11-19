import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../booking/data/models.dart';

final ownerRepositoryProvider = Provider(
  (ref) => OwnerRepository(ref.watch(dioProvider)),
);

/// Negócio do dono logado (o primeiro). null = ainda não cadastrou.
final myBusinessProvider = FutureProvider.autoDispose<Business?>(
  (ref) => ref.watch(ownerRepositoryProvider).myBusiness(),
);

final businessAppointmentsProvider = FutureProvider.autoDispose
    .family<List<Appointment>, String>(
      (ref, id) => ref.watch(ownerRepositoryProvider).appointments(id),
    );

class OwnerRepository {
  OwnerRepository(this._dio);

  final Dio _dio;

  Future<Business?> myBusiness() async {
    final res = await _dio.get<List<dynamic>>('/businesses/mine');
    final list = res.data!;
    return list.isEmpty
        ? null
        : Business.fromJson(list.first as Map<String, dynamic>);
  }

  Future<void> createBusiness({
    required String name,
    String? description,
    String? address,
  }) => _dio.post<void>(
    '/businesses',
    data: {'name': name, 'description': description, 'address': address},
  );

  Future<void> updateBusiness(
    String id, {
    required String name,
    String? description,
    String? address,
  }) => _dio.patch<void>(
    '/businesses/$id',
    data: {
      'name': name,
      'description': description ?? '',
      'address': address ?? '',
    },
  );

  Future<void> setHours(String id, List<OpeningHours> days) => _dio.put<void>(
    '/businesses/$id/hours',
    data: {'days': days.map((d) => d.toJson()).toList()},
  );

  Future<void> addService(
    String businessId, {
    required String name,
    required int durationMinutes,
    required int priceCents,
  }) => _dio.post<void>(
    '/businesses/$businessId/services',
    data: {
      'name': name,
      'durationMinutes': durationMinutes,
      'priceCents': priceCents,
    },
  );

  Future<void> updateService(
    String id, {
    String? name,
    int? durationMinutes,
    int? priceCents,
    bool? active,
  }) => _dio.patch<void>(
    '/services/$id',
    data: {
      'name': ?name,
      'durationMinutes': ?durationMinutes,
      'priceCents': ?priceCents,
      'active': ?active,
    },
  );

  Future<void> removeService(String id) => _dio.delete<void>('/services/$id');

  Future<List<Appointment>> appointments(String businessId) async {
    final res = await _dio.get<List<dynamic>>(
      '/businesses/$businessId/appointments',
    );
    return [
      for (final a in res.data!)
        Appointment.fromJson(a as Map<String, dynamic>),
    ];
  }
}
