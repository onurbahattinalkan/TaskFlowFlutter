import 'package:dio/dio.dart';

import 'token_storage.dart';

// Her isteğe JWT ekler; token geçersizse (401) oturumu kapattırır
class AuthInterceptor extends Interceptor {
  final TokenStorage _storage;

  // 401 gelince çağrılacak işlem (AuthProvider.logout)
  final Future<void> Function() _onUnauthorized;

  AuthInterceptor({
    required TokenStorage storage,
    required Future<void> Function() onUnauthorized,
  })  : _storage = storage,
        _onUnauthorized = onUnauthorized;

  // İstek gönderilmeden önce: token varsa başlığa ekle
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    String? token;
    try {
      token = await _storage.readToken();
    } catch (_) {
      // Depo okunamazsa istek token'sız gider (sunucu 401 döner)
      token = null;
    }

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // İsteği yoluna devam ettir
    handler.next(options);
  }

  // Hata cevabı geldiğinde: token'lı istek 401 aldıysa oturum geçersizdir
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final sentToken = err.requestOptions.headers.containsKey('Authorization');

    // Token'sız 401 (ör. yanlış şifreyle giriş) oturumu kapatmaz
    if (err.response?.statusCode == 401 && sentToken) {
      await _onUnauthorized();
    }

    // Hata yine ApiService'e iletilir, ekran mesajı gösterebilir
    handler.next(err);
  }
}