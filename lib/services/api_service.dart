import 'dart:io';
import 'package:dio/dio.dart';
import '../models/scan_result.dart';
import '../models/user_model.dart';
import '../models/history_item.dart';
import '../services/auth_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const baseUrl = 'https://ceklabel-api.vercel.app';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));

  Options _authHeader() {
    final token = AuthService().token;
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<void> register(String name, String email, String password) async {
    try {
      final res = await _dio.post(
        '$baseUrl/api/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );
      final data = res.data['data'];
      AuthService().setFromLogin(
        data['token'] as String,
        UserModel.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final res = await _dio.post(
        '$baseUrl/api/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = res.data['data'];
      AuthService().setFromLogin(
        data['token'] as String,
        UserModel.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  // ── Scan ──────────────────────────────────────────────────────────────────

  Future<ScanResult> scanLabel(File imageFile) async {
    final isLoggedIn = AuthService().isLoggedIn;
    final endpoint = isLoggedIn ? '/api/scan/save' : '/api/scan/quick';
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(imageFile.path, filename: 'photo.jpg'),
      });
      final res = await _dio.post(
        '$baseUrl$endpoint',
        data: formData,
        options: isLoggedIn ? _authHeader() : null,
      );
      if (res.data['success'] == true && res.data['data'] != null) {
        return ScanResult.fromJson(res.data['data']);
      }
      throw ApiException(res.data['message'] ?? 'Scan gagal.');
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan: $e');
    }
  }

  // ── History ───────────────────────────────────────────────────────────────

  Future<List<HistoryItem>> getHistory({int page = 1, int limit = 50}) async {
    try {
      final res = await _dio.get(
        '$baseUrl/api/scan/history',
        queryParameters: {'page': page, 'limit': limit},
        options: _authHeader(),
      );
      final list = res.data['data']['history'] as List;
      return list.map((e) => HistoryItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  Future<ScanResult> getHistoryDetail(String id) async {
    try {
      final res = await _dio.get(
        '$baseUrl/api/scan/history/$id',
        options: _authHeader(),
      );
      return ScanResult.fromHistoryDetail(res.data['data']);
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  Future<void> deleteHistoryScan(String id) async {
    try {
      await _dio.delete(
        '$baseUrl/api/scan/history/$id',
        options: _authHeader(),
      );
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  // ── Error helper ──────────────────────────────────────────────────────────

  String _parseError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Koneksi timeout. Periksa jaringan Anda.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server.';
    }
    final msg = e.response?.data?['message'];
    if (msg != null) return msg.toString();
    return 'Terjadi kesalahan: ${e.message}';
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
