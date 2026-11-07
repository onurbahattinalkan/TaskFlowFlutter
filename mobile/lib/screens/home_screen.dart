import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../services/api_client.dart';
import '../widgets/status_chip.dart';

// API bağlantı testinin olası durumları
enum ConnectionStatus { notTested, testing, success, failure }

// Açılış ekranı: geliştirme durumunu kartlar hâlinde gösterir
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Ekranın durumu: bağlantı testi nerede ve altında hangi mesaj yazacak
  ConnectionStatus _status = ConnectionStatus.notTested;
  String _detail = 'Henüz test edilmedi';

  // API'ye örnek bir istek atar ve sonucu ekrana yansıtır
  Future<void> _testConnection() async {
    setState(() {
      _status = ConnectionStatus.testing;
      _detail = 'İstek gönderiliyor...';
    });

    try {
      // baseUrl ApiClient'ta tanımlı; burada sadece yolu veriyoruz
      final response = await ApiClient.dio.get('/WeatherForecast');
      final itemCount = (response.data as List).length;
      final time = DateFormat('HH:mm:ss').format(DateTime.now());

      // İstek sürerken ekrandan çıkıldıysa setState çağırma
      if (!mounted) return;
      setState(() {
        _status = ConnectionStatus.success;
        _detail = 'HTTP ${response.statusCode}, $itemCount kayıt • $time';
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _status = ConnectionStatus.failure;
        _detail = _errorMessage(e);
      });
    }
  }

  // Dio hata türünü kullanıcının anlayacağı bir mesaja çevirir
  String _errorMessage(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout =>
        'Zaman aşımı: API çalışıyor mu?',
      DioExceptionType.connectionError =>
        'Bağlanılamadı: adres veya port yanlış olabilir',
      DioExceptionType.badResponse =>
        'Sunucu hatası: HTTP ${e.response?.statusCode}',
      _ => 'Hata: ${e.message ?? e.type.name}',
    };
  }

  // Duruma göre rozetin metni ve renkleri
  StatusChip _statusChip(ColorScheme colors) {
    return switch (_status) {
      ConnectionStatus.notTested => StatusChip(
          label: 'Test edilmedi',
          backgroundColor: colors.surfaceContainerHighest,
          foregroundColor: colors.onSurfaceVariant,
        ),
      ConnectionStatus.testing => StatusChip(
          label: 'Test ediliyor',
          backgroundColor: colors.secondaryContainer,
          foregroundColor: colors.onSecondaryContainer,
        ),
      ConnectionStatus.success => StatusChip(
          label: 'Başarılı',
          backgroundColor: Colors.green.shade100,
          foregroundColor: Colors.green.shade900,
        ),
      ConnectionStatus.failure => StatusChip(
          label: 'Başarısız',
          backgroundColor: colors.errorContainer,
          foregroundColor: colors.onErrorContainer,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isTesting = _status == ConnectionStatus.testing;

    return Scaffold(
      appBar: AppBar(title: const Text('TaskFlow Mobil')),
      body: SafeArea(
        // Tablette içerik ortada, en fazla 480 piksel genişlikte dursun
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                // Kartlar: ekran küçükse kaydırılabilir
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('Hoş geldin', style: textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Geliştirme durumu',
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),

                      // --dart-define ile verilen API adresi
                      Card(
                        child: ListTile(
                          leading: Icon(Icons.link, color: colors.primary),
                          title: const Text('API adresi'),
                          subtitle: Text(AppConfig.apiBaseUrl),
                        ),
                      ),

                      // Son bağlantı testinin sonucu
                      Card(
                        child: ListTile(
                          leading: Icon(Icons.cable, color: colors.primary),
                          title: const Text('Bağlantı'),
                          subtitle: Text(_detail),
                          trailing: _statusChip(colors),
                        ),
                      ),

                      // Uygulamanın hangi aşamada olduğu
                      Card(
                        child: ListTile(
                          leading:
                              Icon(Icons.phone_android, color: colors.primary),
                          title: const Text('Sürüm'),
                          subtitle: const Text('1. hafta iskeleti'),
                        ),
                      ),
                    ],
                  ),
                ),

                // Buton her zaman altta sabit; test sürerken pasif
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    onPressed: isTesting ? null : _testConnection,
                    icon: isTesting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering),
                    label: const Text('API bağlantısını test et'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}