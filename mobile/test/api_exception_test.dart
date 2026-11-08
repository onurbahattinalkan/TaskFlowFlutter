import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow_mobile/services/api_exception.dart';

// Gerçek ağ olmadan, API'nin döndürebileceği cevapları taklit ediyoruz
DioException _errorWith(int statusCode, dynamic data) {
  final options = RequestOptions(path: '/api/projects');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: statusCode, data: data),
  );
}

void main() {
  test('400 doğrulama hatası alanlara ayrılır', () {
    final ex = ApiException.fromDio(_errorWith(400, {
      'errors': {
        'Name': ['Proje adı zorunludur.'],
        'TeamId': ['Geçerli bir ekip seçin.'],
      },
    }));

    expect(ex.statusCode, 400);
    expect(ex.fieldErrors['Name'], ['Proje adı zorunludur.']);
    expect(ex.message, contains('Geçerli bir ekip seçin.'));
  });

  test('API mesajı olduğu gibi kullanılır', () {
    final ex = ApiException.fromDio(_errorWith(404, {'message': 'Proje bulunamadı.'}));
    expect(ex.message, 'Proje bulunamadı.');
  });

  test('Gövde yoksa durum koduna göre mesaj üretilir', () {
    final ex = ApiException.fromDio(_errorWith(403, null));
    expect(ex.message, 'Bu işlem için yetkiniz yok.');
  });

  test('Cevap yoksa bağlantı hatası mesajı verilir', () {
    final ex = ApiException.fromDio(DioException(
      requestOptions: RequestOptions(path: '/api/projects'),
      type: DioExceptionType.connectionError,
    ));
    expect(ex.statusCode, isNull);
    expect(ex.message, startsWith('Sunucuya bağlanılamadı'));
  });
}