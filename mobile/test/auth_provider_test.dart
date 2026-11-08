import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow_mobile/models/auth_user.dart';
import 'package:taskflow_mobile/providers/auth_provider.dart';
import 'package:taskflow_mobile/services/api_exception.dart';
import 'package:taskflow_mobile/services/api_service.dart';
import 'package:taskflow_mobile/services/token_storage.dart';

// Bellekte çalışan sahte depo (telefonun Keystore'una gitmez)
class FakeTokenStorage extends TokenStorage {
  String? token;

  @override
  Future<void> saveToken(String value) async => token = value;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> deleteToken() async => token = null;
}

// Sahte API: doğru şifre "Test123", aksi hâlde 401
class FakeApiService extends ApiService {
  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    if (password != 'Test123') {
      throw const ApiException('E-posta veya şifre hatalı.', statusCode: 401);
    }
    return AuthResponse(
      token: validToken,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      user: const AuthUser(
        id: 'u1',
        userName: 'zeynep',
        email: 'zeynep@test.com',
        fullName: 'Zeynep Akçay',
        roles: ['User'],
      ),
    );
  }
}

// Sahte JWT: başlık.içerik.imza (imza kontrol edilmez)
String fakeToken(Map<String, dynamic> payload) {
  String encode(Map<String, dynamic> part) =>
      base64Url.encode(utf8.encode(jsonEncode(part))).replaceAll('=', '');
  return '${encode({'alg': 'HS256', 'typ': 'JWT'})}.${encode(payload)}.imza';
}

// exp: saniye cinsinden bitiş zamanı
int _exp(Duration fromNow) =>
    DateTime.now().add(fromNow).millisecondsSinceEpoch ~/ 1000;

final validToken = fakeToken({
  'sub': 'u1',
  'fullName': 'Zeynep Akçay',
  'role': 'User',
  'exp': _exp(const Duration(days: 7)),
});

final expiredToken = fakeToken({
  'sub': 'u1',
  'exp': _exp(const Duration(days: -1)),
});

void main() {
  late FakeTokenStorage storage;
  late AuthProvider auth;

  setUp(() {
    storage = FakeTokenStorage();
    auth = AuthProvider(api: FakeApiService(), storage: storage);
  });

  test('Başlangıçta durum bilinmiyor', () {
    expect(auth.status, AuthStatus.unknown);
  });

  test('Kayıtlı token yoksa giriş yapılmamış sayılır', () async {
    await auth.init();
    expect(auth.status, AuthStatus.unauthenticated);
  });

  test('Geçerli token varsa oturum geri yüklenir', () async {
    storage.token = validToken;
    await auth.init();

    expect(auth.isLoggedIn, isTrue);
    expect(auth.user?.fullName, 'Zeynep Akçay');
  });

  test('Süresi dolmuş token silinir', () async {
    storage.token = expiredToken;
    await auth.init();

    expect(auth.status, AuthStatus.unauthenticated);
    expect(storage.token, isNull);
  });

  test('Başarılı girişte token kaydedilir', () async {
    await auth.login(email: 'zeynep@test.com', password: 'Test123');

    expect(auth.isLoggedIn, isTrue);
    expect(storage.token, validToken);
  });

  test('Hatalı girişte ApiException fırlar, oturum açılmaz', () async {
    await auth.init();

    await expectLater(
      auth.login(email: 'zeynep@test.com', password: 'yanlis1'),
      throwsA(isA<ApiException>()),
    );
    expect(auth.isLoggedIn, isFalse);
    expect(storage.token, isNull);
  });

  test('Çıkışta token silinir', () async {
    storage.token = validToken;
    await auth.init();
    await auth.logout();

    expect(auth.status, AuthStatus.unauthenticated);
    expect(auth.user, isNull);
    expect(storage.token, isNull);
  });
}