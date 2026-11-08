import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../models/auth_user.dart';
import '../services/api_service.dart';
import '../services/token_storage.dart';

// Oturumun olası durumları
enum AuthStatus {
  unknown, // açılışta token henüz okunmadı
  authenticated, // geçerli oturum var
  unauthenticated, // giriş yapılmamış
}

// Oturum bilgisini tek yerde tutar; değişince dinleyenlere haber verir
// (ekranlar ve go_router yönlendirmesi)
class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  final TokenStorage _storage;

  // Testte sahte servisler verilebilsin diye dışarıdan alınabilir
  AuthProvider({ApiService? api, TokenStorage? storage})
      : _api = api ?? ApiService(),
        _storage = storage ?? TokenStorage();

  AuthStatus _status = AuthStatus.unknown;
  AuthUser? _user;

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  // Uygulama açılırken bir kez çağrılır: kayıtlı oturumu geri yükler
  Future<void> init() async {
    final token = await _storage.readToken();

    if (token == null || !_isValid(token)) {
      // Süresi dolmuş/bozuk token cihazda kalmasın
      await _storage.deleteToken();
      _setLoggedOut();
      return;
    }

    _user = AuthUser.fromToken(token);
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  // Başarısızsa ApiException fırlatır; mesajı ekran gösterir
  Future<void> login({required String email, required String password}) async {
    final response = await _api.login(email: email, password: password);
    await _startSession(response);
  }

  Future<void> register({
    required String fullName,
    required String userName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await _api.register(
      fullName: fullName,
      userName: userName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
    await _startSession(response);
  }

  // Çıkış: token silinir, router giriş ekranına yönlendirir
  Future<void> logout() async {
    await _storage.deleteToken();
    _setLoggedOut();
  }

  // Başarılı giriş/kayıt sonrası ortak işlem
  Future<void> _startSession(AuthResponse response) async {
    await _storage.saveToken(response.token);
    _user = response.user;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  void _setLoggedOut() {
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // Token çözülebiliyor ve süresi dolmamış mı? (exp alanına bakar, API'ye gitmez)
  bool _isValid(String token) {
    try {
      return !JwtDecoder.isExpired(token);
    } on FormatException {
      return false;
    }
  }
}