import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

// Modèle Utilisateur Admin
class AdminUser {
  final int id;
  final String email;
  final String role;
  final bool isActive;
  final String? firstName;
  final String? lastName;

  AdminUser({
    required this.id,
    required this.email,
    required this.role,
    required this.isActive,
    this.firstName,
    this.lastName,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      email: json['email'],
      role: json['role'],
      isActive: json['is_active'],
      firstName: json['first_name'],
      lastName: json['last_name'],
    );
  }
}

// Service Admin
class AdminService {
  final ApiClient apiClient;

  AdminService(this.apiClient);

  Future<List<AdminUser>> fetchUsers({String? role}) async {
    final Map<String, dynamic> query = role != null ? {'role': role} : {};
    final response = await apiClient.get(ApiEndpoints.adminUsers, queryParameters: query);
    return (response.data as List).map((u) => AdminUser.fromJson(u)).toList();
  }

  Future<Map<String, dynamic>> fetchStats() async {
    final response = await apiClient.get(ApiEndpoints.adminStats);
    return Map<String, dynamic>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> fetchAssurances() async {
    final response = await apiClient.get(ApiEndpoints.adminAssurances);
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> fetchLogs() async {
    final response = await apiClient.get(ApiEndpoints.adminLogs);
    return List<Map<String, dynamic>>.from(response.data);
  }

  // CRUD Utilisateurs
  Future<void> createUser(Map<String, dynamic> data) async {
    await apiClient.post(ApiEndpoints.adminUsers, data: data);
  }

  Future<void> updateUser(int id, Map<String, dynamic> data) async {
    await apiClient.patch(ApiEndpoints.adminUserDetail(id), data: data);
  }

  Future<void> deleteUser(int id) async {
    await apiClient.delete(ApiEndpoints.adminUserDetail(id));
  }

  // CRUD Assurances
  Future<void> createAssurance(Map<String, dynamic> data) async {
    await apiClient.post(ApiEndpoints.adminAssurances, data: data);
  }

  Future<void> deleteAssurance(int id) async {
    await apiClient.delete('${ApiEndpoints.adminAssurances}$id/');
  }

  Future<void> updateUserRole(int id, String role) async {
    await apiClient.patch(ApiEndpoints.adminUserDetail(id), data: {'role': role});
  }

  Future<void> deactivateUser(int id) async {
    // PATCH is_active to false — do NOT delete the account
    await apiClient.patch(ApiEndpoints.adminUserDetail(id), data: {'is_active': false});
  }

  Future<void> addProduct(Map<String, dynamic> data) async {
    final formData = FormData.fromMap(data);
    await apiClient.post(ApiEndpoints.getProducts, data: formData);
  }

  Future<void> updateProduct(int id, Map<String, dynamic> data) async {
    final formData = FormData.fromMap(data);
    await apiClient.dio.patch(ApiEndpoints.productDetail(id), data: formData);
  }

  Future<void> deleteProduct(int id) async {
    await apiClient.delete(ApiEndpoints.productDetail(id));
  }

  Future<List<Map<String, dynamic>>> fetchAllOrders() async {
    final response = await apiClient.get(ApiEndpoints.adminOrders);
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> updateOrderStatus(int id, String status) async {
    await apiClient.dio.patch(ApiEndpoints.adminOrderDetail(id), data: {'statut': status});
  }

  Future<List<Map<String, dynamic>>> fetchAllPrescriptions({String? search}) async {
    final response = await apiClient.get(
      ApiEndpoints.adminPrescriptions,
      queryParameters: search != null ? {'search': search} : null,
    );
    return List<Map<String, dynamic>>.from(response.data);
  }
}

final adminServiceProvider = Provider((ref) {
  final client = ref.watch(apiClientProvider);
  return AdminService(client);
});

// Providers State
final adminUsersProvider = FutureProvider.family<List<AdminUser>, String?>((ref, role) async {
  return ref.watch(adminServiceProvider).fetchUsers(role: role);
});

final adminOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminServiceProvider).fetchAllOrders();
});

final adminPrescriptionsProvider = FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, search) async {
  return ref.watch(adminServiceProvider).fetchAllPrescriptions(search: search);
});

// Provider pour les statistiques réelles
final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(adminServiceProvider).fetchStats();
});

final adminAssurancesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminServiceProvider).fetchAssurances();
});

final adminLogsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminServiceProvider).fetchLogs();
});
