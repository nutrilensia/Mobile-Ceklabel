import 'dart:io';
import 'package:dio/dio.dart';
import '../models/scan_result.dart';
import '../models/user_model.dart';
import '../models/history_item.dart';
import '../models/health_profile.dart';
import '../models/family_profile.dart';
import '../models/diary_day.dart';
import '../models/product.dart';
import '../models/quiz.dart';
import '../models/tip.dart';
import '../models/gamification.dart';
import '../models/weekly_report.dart';
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

  Future<UserModel> getProfile() async {
    try {
      final res = await _dio.get('$baseUrl/api/auth/me', options: _authHeader());
      final user = UserModel.fromJson(res.data['data'] as Map<String, dynamic>);
      AuthService().updateUser(user);
      return user;
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  Future<UserModel> updateProfile({String? name, String? email, HealthProfile? healthProfile}) async {
    try {
      final body = <String, dynamic>{};
      if (name != null && name.isNotEmpty) body['name'] = name;
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (healthProfile != null) body['healthProfile'] = healthProfile.toJson();

      final res = await _dio.patch(
        '$baseUrl/api/auth/me',
        data: body,
        options: _authHeader(),
      );

      final existing = AuthService().currentUser;
      final raw = res.data['data'] as Map<String, dynamic>? ?? {};
      // Merge API response with existing data to handle partial responses
      final merged = UserModel(
        id: raw['id']?.toString().isNotEmpty == true
            ? raw['id'].toString()
            : existing?.id ?? '',
        name: raw['name']?.toString().isNotEmpty == true
            ? raw['name'].toString()
            : name ?? existing?.name ?? '',
        email: raw['email']?.toString().isNotEmpty == true
            ? raw['email'].toString()
            : email ?? existing?.email ?? '',
        healthProfile: raw['healthProfile'] != null
            ? HealthProfile.fromJson(raw['healthProfile'] as Map<String, dynamic>)
            : healthProfile ?? existing?.healthProfile,
      );
      AuthService().updateUser(merged);
      return merged;
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
      await _dio.delete('$baseUrl/api/scan/history/$id', options: _authHeader());
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  // ── Profil Keluarga ───────────────────────────────────────────────────────

  Future<List<FamilyProfile>> getFamilyProfiles() async {
    try {
      final res = await _dio.get('$baseUrl/api/family', options: _authHeader());
      final raw = res.data['data'];
      List list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map) {
        final inner = raw['profiles'] ?? raw['members'] ?? raw['family'] ?? raw['data'];
        list = inner is List ? inner : [];
      } else if (res.data is List) {
        list = res.data as List;
      } else {
        // Try top-level keys as last resort
        final top = res.data;
        if (top is Map) {
          final inner = top['profiles'] ?? top['members'] ?? top['family'];
          list = inner is List ? inner : [];
        } else {
          list = [];
        }
      }
      return list
          .whereType<Map<String, dynamic>>()
          .map(FamilyProfile.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  Future<void> addFamilyProfile({
    required String name,
    required String relation,
    required String ageGroup,
    Map<String, dynamic>? conditions,
  }) async {
    try {
      await _dio.post(
        '$baseUrl/api/family',
        data: {
          'name': name,
          'relation': relation,
          'ageGroup': ageGroup,
          if (conditions != null) 'conditions': conditions,
        },
        options: _authHeader(),
      );
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  Future<void> updateFamilyProfile(String id, Map<String, dynamic> data) async {
    try {
      await _dio.patch(
        '$baseUrl/api/family/$id',
        data: data,
        options: _authHeader(),
      );
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  Future<void> deleteFamilyProfile(String id) async {
    try {
      await _dio.delete('$baseUrl/api/family/$id', options: _authHeader());
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  // ── Diary Gizi ────────────────────────────────────────────────────────────

  Future<DiaryEntry> logDiary({
    String? scanId,
    String? productId,
    double servings = 1.0,
    String? date,
    String? profileId,
  }) async {
    try {
      final body = <String, dynamic>{
        'servings': servings,
        if (scanId != null) 'scanId': scanId,
        if (productId != null) 'productId': productId,
        if (date != null) 'date': date,
        if (profileId != null) 'profileId': profileId,
      };
      final res = await _dio.post(
        '$baseUrl/api/diary',
        data: body,
        options: _authHeader(),
      );
      return DiaryEntry.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  Future<DiaryDay> getDiary({String? date, String? profileId}) async {
    try {
      final params = <String, dynamic>{};
      if (date != null) params['date'] = date;
      if (profileId != null) params['profileId'] = profileId;
      final res = await _dio.get(
        '$baseUrl/api/diary',
        queryParameters: params.isNotEmpty ? params : null,
        options: _authHeader(),
      );
      return DiaryDay.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  Future<void> deleteDiaryEntry(String id) async {
    try {
      await _dio.delete('$baseUrl/api/diary/$id', options: _authHeader());
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  // ── Database Produk ───────────────────────────────────────────────────────

  Future<List<Product>> searchProducts({
    required String query,
    String? category,
    int page = 1,
  }) async {
    try {
      final res = await _dio.get(
        '$baseUrl/api/products/search',
        queryParameters: {
          'q': query,
          if (category != null) 'category': category,
          'page': page,
        },
      );
      final list = res.data['data']['products'] as List? ?? res.data['data'] as List? ?? [];
      return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  Future<List<String>> getProductCategories() async {
    try {
      final res = await _dio.get('$baseUrl/api/products/categories');
      final list = res.data['data'] as List? ?? [];
      return list.map((e) => e.toString()).toList();
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  Future<List<Product>> getLeaderboard({
    String? category,
    String order = 'best',
    int limit = 20,
  }) async {
    try {
      final res = await _dio.get(
        '$baseUrl/api/products/leaderboard',
        queryParameters: {
          if (category != null) 'category': category,
          'order': order,
          'limit': limit,
        },
      );
      final list = res.data['data'] as List? ?? [];
      return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  Future<Product> getProductByBarcode(String barcode) async {
    try {
      final res = await _dio.get('$baseUrl/api/products/barcode/$barcode');
      return Product.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  // ── Belanja Pintar / Compare ──────────────────────────────────────────────

  Future<CompareResult> compareProducts(List<CompareItem> items) async {
    try {
      final res = await _dio.post(
        '$baseUrl/api/compare',
        data: {'items': items.map((i) => i.toJson()).toList()},
        options: AuthService().isLoggedIn ? _authHeader() : null,
      );
      return CompareResult.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  // ── Edukasi & Gamifikasi ──────────────────────────────────────────────────

  Future<List<QuizQuestion>> getQuiz({int count = 5}) async {
    try {
      final res = await _dio.get(
        '$baseUrl/api/edu/quiz',
        queryParameters: {'count': count},
        options: AuthService().isLoggedIn ? _authHeader() : null,
      );
      final list = res.data['data'] as List? ?? [];
      return list.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  Future<QuizAnswer> answerQuiz(String questionId, int answerIndex) async {
    try {
      final res = await _dio.post(
        '$baseUrl/api/edu/quiz/$questionId/answer',
        data: {'answerIndex': answerIndex},
        options: AuthService().isLoggedIn ? _authHeader() : null,
      );
      return QuizAnswer.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  Future<List<Tip>> getTips({String? category}) async {
    try {
      final res = await _dio.get(
        '$baseUrl/api/edu/tips',
        queryParameters: category != null ? {'category': category} : null,
      );
      final list = res.data['data'] as List? ?? [];
      return list.map((e) => Tip.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  Future<GamificationStats> getGamificationStats() async {
    try {
      final res = await _dio.get('$baseUrl/api/edu/stats', options: _authHeader());
      return GamificationStats.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  // ── Laporan Mingguan ──────────────────────────────────────────────────────

  Future<WeeklyReport> getWeeklyReport({String? startDate}) async {
    try {
      final res = await _dio.get(
        '$baseUrl/api/reports/weekly',
        queryParameters: startDate != null ? {'start': startDate} : null,
        options: _authHeader(),
      );
      return WeeklyReport.fromJson(res.data);
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
