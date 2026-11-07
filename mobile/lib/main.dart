import 'package:flutter/material.dart';

import 'config/app_theme.dart';
import 'screens/home_screen.dart';

// Uygulamanın başlangıç noktası
void main() {
  runApp(const TaskFlowApp());
}

// Uygulamanın kök widget'ı: tema ve ilk ekran burada belirlenir
class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskFlow Mobil',

      // Sağ üstteki "DEBUG" etiketini gizle
      debugShowCheckedModeBanner: false,

      // Açık ve koyu tema; hangisinin kullanılacağına telefonun ayarı karar verir
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // Açılışta gösterilecek ekran (ileride go_router ile değişecek)
      home: const HomeScreen(),
    );
  }
}