import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_endpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auth_provider.dart';

class ApiClient {
  final Dio dio;
  final Ref? ref;
  bool _isRefreshing = false;

  ApiClient({this.ref})
      : dio = Dio(
          BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            responseType: ResponseType.json,
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401 && !e.requestOptions.path.contains('token/refresh')) {
            if (_isRefreshing) {
              // Wait or retry? For simplicity, we just block here or wait for the first one to finish
              // A better implementation would queue the requests.
            }

            _isRefreshing = true;
            try {
              final prefs = await SharedPreferences.getInstance();
              final refreshToken = prefs.getString('refresh_token');

              if (refreshToken != null) {
                // Try to refresh the token using a separate Dio instance to avoid interceptor loop
                final refreshDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
                final response = await refreshDio.post(ApiEndpoints.tokenRefresh, data: {
                  'refresh': refreshToken,
                });

                if (response.statusCode == 200) {
                  final newAccessToken = response.data['access'];
                  await prefs.setString('access_token', newAccessToken);
                  _isRefreshing = false;

                  // Retry the original request
                  final options = e.requestOptions;
                  options.headers['Authorization'] = 'Bearer $newAccessToken';
                  final cloneReq = await dio.fetch(options);
                  return handler.resolve(cloneReq);
                }
              }
            } catch (refreshError) {
              _isRefreshing = false;
              // Refresh failed, logout user
              if (ref != null) {
                ref!.read(authProvider.notifier).logout();
              } else {
                // Fallback for global instance
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('access_token');
                await prefs.remove('refresh_token');
                await prefs.remove('user_data');
              }
              return handler.next(e);
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  // Helper methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) => dio.get(path, queryParameters: queryParameters);
  Future<Response> post(String path, {dynamic data}) => dio.post(path, data: data);
  Future<Response> put(String path, {dynamic data}) => dio.put(path, data: data);
  Future<Response> patch(String path, {dynamic data}) => dio.patch(path, data: data);
  Future<Response> delete(String path) => dio.delete(path);
}

// The global instance is maintained for backward compatibility during transition
final apiClient = ApiClient();

// The new preferred way via Riverpod
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref: ref);
});
