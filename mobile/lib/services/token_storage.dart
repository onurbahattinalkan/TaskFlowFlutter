import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// JWT'yi cihazda şifreli saklar (Android'de Keystore ile).
// SharedPreferences düz metin sakladığı için token orada tutulmaz.
class TokenStorage {
  static const _tokenKey = 'auth_token';

  final FlutterSecureStorage _storage;

  // Testte sahte depo verilebilsin diye dışarıdan alınabilir
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }

  // Kayıtlı token yoksa null
  Future<String?> readToken() {
    return _storage.read(key: _tokenKey);
  }

  // Çıkışta veya token geçersizse
  Future<void> deleteToken() {
    return _storage.delete(key: _tokenKey);
  }
}