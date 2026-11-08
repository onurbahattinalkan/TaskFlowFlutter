import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/app_router.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'services/api_client.dart';
import 'services/token_storage.dart';

// Uygulamanın başlangıç noktası
void main() {
  // Interceptor ve AuthProvider aynı token deposunu kullanır
  final storage = TokenStorage();
  final auth = AuthProvider(storage: storage);

  // Her isteğe token eklensin; 401 gelirse oturum kapansın
  ApiClient.attachAuth(storage: storage, onUnauthorized: auth.logout);

  // Kayıtlı token varsa oturumu geri yükle
  auth.init();

  runApp(
    // Oturum bilgisi tüm ekranlardan erişilebilsin diye en üstte.
    // .value: nesneyi yukarıda kendimiz oluşturduk
    ChangeNotifierProvider.value(
      value: auth,
      child: const TaskFlowApp(),
    ),
  );
}

// Uygulamanın kök widget'ı: tema ve router burada belirlenir
class TaskFlowApp extends StatefulWidget {
  const TaskFlowApp({super.key});

  @override
  State<TaskFlowApp> createState() => _TaskFlowAppState();
}

class _TaskFlowAppState extends State<TaskFlowApp> {
  // Router bir kez oluşturulur; her build'de yeniden oluşursa gezinme sıfırlanır
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(context.read<AuthProvider>());
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TaskFlow Mobil',

      // Sağ üstteki "DEBUG" etiketini gizle
      debugShowCheckedModeBanner: false,

      // Açık ve koyu tema; hangisinin kullanılacağına telefonun ayarı karar verir
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // Hangi adreste hangi ekranın açılacağına router karar verir
      routerConfig: _router,
    );
  }
}