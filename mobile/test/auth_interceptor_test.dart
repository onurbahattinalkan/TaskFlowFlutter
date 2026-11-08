import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow_mobile/services/auth_interceptor.dart';
import 'package:taskflow_mobile/services/token_storage.dart';

// Bellekte çalışan sahte depo
class FakeTokenStorage extends TokenStorage {
  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String value) async => token = value;

  @override
  Future<void> deleteToken() async => token = null;
}

// Sahte sunucu: gelen isteği saklar, verilen durum koduyla cevap döner
class FakeAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;
  int statusCode = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      '{}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late FakeTokenStorage storage;
  late FakeAdapter adapter;
  late Dio dio;
  late int logoutCount;

  setUp(() {
    storage = FakeTokenStorage();
    adapter = FakeAdapter();
    logoutCount = 0;

    dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(AuthInterceptor(
        storage: storage,
        onUnauthorized: () async => logoutCount++,
      ));
  });

  test('Token varsa Authorization başlığı eklenir', () async {
    storage.token = 'abc';
    await dio.get('/api/projects');

    expect(adapter.lastRequest!.headers['Authorization'], 'Bearer abc');
  });

  test('Token yoksa başlık eklenmez', () async {
    await dio.get('/api/projects');

    expect(adapter.lastRequest!.headers.containsKey('Authorization'), isFalse);
  });

  test('Token\'lı istek 401 alırsa oturum kapatılır', () async {
    storage.token = 'suresi-dolmus';
    adapter.statusCode = 401;

    await expectLater(dio.get('/api/projects'), throwsA(isA<DioException>()));
    expect(logoutCount, 1);
  });

  test('Token\'sız 401 (yanlış şifre) oturumu kapatmaz', () async {
    adapter.statusCode = 401;

    await expectLater(
      dio.post('/api/auth/login', data: {}),
      throwsA(isA<DioException>()),
    );
    expect(logoutCount, 0);
  });
}