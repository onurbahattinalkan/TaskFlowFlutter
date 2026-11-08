import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'auth_interceptor.dart';
import 'token_storage.dart';

// Uygulamanın tüm HTTP istekleri bu tek Dio nesnesi üzerinden gider.
// JWT interceptor bir kez buraya eklenir ve tüm isteklere uygulanır.
class ApiClient {
  ApiClient._();

  // Ortak ayarlar: temel adres, zaman aşımları, JSON başlığı
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // Uygulama açılırken bir kez çağrılır (main.dart)
  static void attachAuth({
    required TokenStorage storage,
    required Future<void> Function() onUnauthorized,
  }) {
    // İki kez eklenirse her isteğe iki kez işlem yapılmasın
    dio.interceptors.removeWhere((i) => i is AuthInterceptor);
    dio.interceptors.add(
      AuthInterceptor(storage: storage, onUnauthorized: onUnauthorized),
    );
  }
}