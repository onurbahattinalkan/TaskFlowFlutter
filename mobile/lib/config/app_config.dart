// Uygulama genelindeki ayarlar
class AppConfig {
  // Bu sınıftan nesne oluşturulmasın; sadece sabitleri kullanıyoruz
  AppConfig._();

  // API adresi derleme sırasında --dart-define ile verilir:
  //   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5216
  // Verilmezse emülatördeki varsayılan adres kullanılır
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5216',
  );
}