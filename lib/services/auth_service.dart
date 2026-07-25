import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  final _controller = StreamController<UserModel?>.broadcast();

  String? _token;
  UserModel? _user;

  String? get token => _token;
  UserModel? get currentUser => _user;
  bool get isLoggedIn => _token != null;
  Stream<UserModel?> get authStateChanges => _controller.stream;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (_token != null && userJson != null) {
      try {
        _user = UserModel.fromJson(jsonDecode(userJson));
      } catch (_) {
        _token = null;
      }
    }
  }

  Future<void> _persist(String token, UserModel user) async {
    _token = token;
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    _controller.add(user);
  }

  Future<void> setFromLogin(String token, UserModel user) async {
    await _persist(token, user);
  }

  Future<void> updateUser(UserModel user) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    _controller.add(user);
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _controller.add(null);
  }
}
