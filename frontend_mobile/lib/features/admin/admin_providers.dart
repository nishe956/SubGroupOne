import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../products/products_providers.dart';

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
  Future<List<AdminUser>> fetchUsers() async {
    final response = await apiClient.get(ApiEndpoints.adminUsers);
    return (response.data as List).map((u) => AdminUser.fromJson(u)).toList();
  }

  Future<void> updateUserRole(int id, String role) async {
    await apiClient.dio.patch(ApiEndpoints.adminUserDetail(id), data: {'role': role});
  }

  Future<void> deactivateUser(int id) async {
    await apiClient.delete(ApiEndpoints.adminUserDetail(id));
  }

  Future<void> addProduct(Map<String, dynamic> data) async {
    // Utiliser FormData pour l'envoi d'images
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

final adminServiceProvider = Provider((ref) => AdminService());

// Providers State
final adminUsersProvider = FutureProvider<List<AdminUser>>((ref) async {
  return ref.watch(adminServiceProvider).fetchUsers();
});

final adminOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminServiceProvider).fetchAllOrders();
});

final adminPrescriptionsProvider = FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, search) async {
  return ref.watch(adminServiceProvider).fetchAllPrescriptions(search: search);
});

// Provider pour les statistiques du tableau de bord
final adminStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  try {
    final users = await ref.watch(adminUsersProvider.future);
    final orders = await ref.watch(adminOrdersProvider.future);
    final prescriptions = await ref.watch(adminPrescriptionsProvider(null).future);
    final products = await ref.watch(productsCatalogProvider.future);

    return {
      'users': users.length,
      'orders': orders.length,
      'products': products.length,
      'prescriptions': prescriptions.length,
    };
  } catch (e) {
    return {
      'users': 0,
      'orders': 0,
      'products': 0,
      'prescriptions': 0,
    };
  }
});
