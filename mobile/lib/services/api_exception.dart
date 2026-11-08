import 'package:dio/dio.dart';

// API'den gelen hataları kullanıcıya gösterilecek Türkçe mesaja çevirir
class ApiException implements Exception {
  // Ekranda gösterilecek genel mesaj
  final String message;

  // HTTP durum kodu (bağlantı hatasında null)
  final int? statusCode;

  // Alan bazlı doğrulama hataları: {"Name": ["Proje adı zorunludur."]}
  final Map<String, List<String>> fieldErrors;

  const ApiException(
    this.message, {
    this.statusCode,
    this.fieldErrors = const {},
  });

  // Dio hatasından ApiException üretir
  factory ApiException.fromDio(DioException error) {
    final response = error.response;

    // Sunucuya hiç ulaşılamadıysa (cevap yok)
    if (response == null) {
      return const ApiException(
        'Sunucuya bağlanılamadı. İnternet bağlantınızı ve API adresini kontrol edin.',
      );
    }

    final statusCode = response.statusCode;
    final data = response.data;

    // 400 doğrulama hatası: {"errors": {"Name": ["..."], "TeamId": ["..."]}}
    if (data is Map && data['errors'] is Map) {
      final errors = <String, List<String>>{};
      (data['errors'] as Map).forEach((key, value) {
        errors[key.toString()] =
            (value as List).map((e) => e.toString()).toList();
      });

      return ApiException(
        // Tüm hata mesajlarını alt alta tek metin yap
        errors.values.expand((list) => list).join('\n'),
        statusCode: statusCode,
        fieldErrors: errors,
      );
    }

    // API'nin kendi mesajı: {"message": "Proje bulunamadı."}
    if (data is Map && data['message'] is String) {
      return ApiException(data['message'] as String, statusCode: statusCode);
    }

    // Gövdede mesaj yoksa durum koduna göre genel mesaj
    final message = switch (statusCode) {
      401 => 'Oturumunuz sona erdi. Lütfen tekrar giriş yapın.',
      403 => 'Bu işlem için yetkiniz yok.',
      404 => 'İstenen kayıt bulunamadı.',
      _ => 'Beklenmeyen bir hata oluştu (HTTP $statusCode).',
    };
    return ApiException(message, statusCode: statusCode);
  }

  @override
  String toString() => message;
}