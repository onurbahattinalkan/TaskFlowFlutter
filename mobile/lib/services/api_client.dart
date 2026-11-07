import 'package:dio/dio.dart';

import '../config/app_config.dart';

// Uygulamanın tüm HTTP istekleri bu tek Dio nesnesi üzerinden gidecek
/*
Tek bir Dio nesnesi kullanmamızın nedeni: eklenecek JWT interceptor bir kez buraya yazılacak ve tüm isteklere otomatik uygulanacak. ApiService iskeleti de bu nesneyi kullanacak.
*/

class ApiClient {
  ApiClient._();

  // Ortak ayarlar: temel adres, zaman aşımları, JSON başlığı.
  // Token ekleyen interceptor ileride buraya eklenecek.
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );
}