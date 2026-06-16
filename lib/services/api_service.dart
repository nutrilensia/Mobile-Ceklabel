import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
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
import '../models/chat_message.dart';
import '../models/health_risk.dart';
import '../models/live_scan_result.dart';
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

  // Cache ringan profil keluarga (sering dipakai scanner/diary/result).
  List<FamilyProfile>? _familyCache;

  /// Kosongkan semua cache (dipanggil saat ganti akun).
  void clearCaches() {
    _familyCache = null;
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<void> register(String name, String email, String password) async {
    try {
      final res = await _dio.post(
        '$baseUrl/api/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );
      final data = res.data['data'];
      clearCaches();
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
      clearCaches();
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
      final data = res.data['data'] as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
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
      final wrapper = res.data['data'] as Map<String, dynamic>? ?? {};
      final raw = wrapper['user'] as Map<String, dynamic>? ?? wrapper;
      // Gabungkan response API dengan data lokal untuk menangani respons parsial
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

  Future<List<FamilyProfile>> getFamilyProfiles({bool forceRefresh = false}) async {
    if (!forceRefresh && _familyCache != null) return _familyCache!;
    try {
      final res = await _dio.get('$baseUrl/api/family', options: _authHeader());
      final raw = res.data['data'];
      List list;
      if (raw is Map) {
        final inner = raw['profiles'] ?? raw['members'] ?? raw['family'];
        list = inner is List ? inner : [];
      } else if (raw is List) {
        list = raw;
      } else {
        list = [];
      }
      _familyCache = list
          .whereType<Map<String, dynamic>>()
          .map(FamilyProfile.fromJson)
          .toList();
      return _familyCache!;
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
      _familyCache = null;
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
      _familyCache = null;
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  Future<void> deleteFamilyProfile(String id) async {
    try {
      await _dio.delete('$baseUrl/api/family/$id', options: _authHeader());
      _familyCache = null;
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  // ── Diary Gizi ────────────────────────────────────────────────────────────

  Future<DiaryLogResult> logDiary({
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
      return DiaryLogResult.fromJson(res.data as Map<String, dynamic>);
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
      final list = res.data['data']['products'] as List? ?? [];
      return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  Future<List<ProductCategory>> getProductCategories() async {
    try {
      final res = await _dio.get('$baseUrl/api/products/categories');
      final list = res.data['data']['categories'] as List? ?? [];
      return list
          .map((e) => ProductCategory.fromJson(e as Map<String, dynamic>))
          .toList();
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
      final list = res.data['data']['leaderboard'] as List? ?? [];
      return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
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

  /// Bandingkan 2-3 foto label langsung — tiap foto di-scan AI di server.
  Future<CompareResult> compareByPhotos(List<File> photos) async {
    try {
      final form = FormData();
      for (final f in photos) {
        form.files.add(MapEntry(
          'photos',
          await MultipartFile.fromFile(f.path, filename: 'photo.jpg'),
        ));
      }
      final res = await _dio.post(
        '$baseUrl/api/compare/photos',
        data: form,
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
      final list = res.data['data']['questions'] as List? ?? [];
      return list.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  Future<QuizAnswer> answerQuiz(String questionId, int answerIndex) async {
    try {
      final res = await _dio.post(
        '$baseUrl/api/edu/quiz/answer',
        data: {'questionId': questionId, 'answerIndex': answerIndex},
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
      final list = res.data['data']['tips'] as List? ?? [];
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

  Future<WeeklyReport> getWeeklyReport({String? startDate, String? profileId}) async {
    try {
      final params = <String, dynamic>{};
      if (startDate != null) params['start'] = startDate;
      if (profileId != null) params['profileId'] = profileId;
      final res = await _dio.get(
        '$baseUrl/api/reports/weekly',
        queryParameters: params.isNotEmpty ? params : null,
        options: _authHeader(),
      );
      return WeeklyReport.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  // ── Live AR Mode ──────────────────────────────────────────────────────────

  Future<LiveScanResult> scanLive(File imageFile) async {
    // Downscale frame to max 640px wide — reduces Vision API input tokens ~60-70%
    File fileToUpload = imageFile;
    try {
      final tempDir = await getTemporaryDirectory();
      final outPath = p.join(tempDir.path, 'live_compressed.jpg');
      final compressed = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        outPath,
        minWidth: 640,
        minHeight: 1,
        quality: 72,
      );
      if (compressed != null) fileToUpload = File(compressed.path);
    } catch (_) {}
    try {
      final form = FormData.fromMap({
        'photo': await MultipartFile.fromFile(fileToUpload.path, filename: 'frame.jpg'),
      });
      final res = await _dio.post(
        '$baseUrl/api/live/scan',
        data: form,
        options: AuthService().isLoggedIn ? _authHeader() : null,
      );
      return LiveScanResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  // ── Chat Asisten Gizi ─────────────────────────────────────────────────────

  Future<ChatMessage> sendChatMessage(List<ChatMessage> messages, {String? profileId}) async {
    try {
      final body = <String, dynamic>{
        'messages': messages.map((m) => m.toJson()).toList(),
        if (profileId != null) 'profileId': profileId,
      };
      final res = await _dio.post(
        '$baseUrl/api/chat/message',
        data: body,
        options: _authHeader(),
      );
      return ChatMessage.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_parseError(e));
    }
  }

  // ── Prediksi Risiko Kesehatan ─────────────────────────────────────────────

  Future<HealthRiskReport> getHealthRisk({String? profileId}) async {
    try {
      final res = await _dio.get(
        '$baseUrl/api/health/risk',
        queryParameters: profileId != null ? {'profileId': profileId} : null,
        options: _authHeader(),
      );
      return HealthRiskReport.fromJson(res.data as Map<String, dynamic>);
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
