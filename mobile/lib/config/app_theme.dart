import 'package:flutter/material.dart';

// Uygulamanın tüm ekranlarında kullanılan ortak tema
class AppTheme {
  // Bu sınıftan nesne oluşturulmasın; sadece statik üyeleri kullanıyoruz
  AppTheme._();

  // Ana renk (teal); diğer tüm renkler bundan türetilir
  static const Color seedColor = Color(0xFF009688);

  // Buton, kart ve form alanlarının köşe yuvarlaklığı
  static const double radius = 12;

  // Açık ve koyu tema aynı ayarlarla, sadece parlaklığı farklı üretilir
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    // Tek renkten, istenen parlaklıkta Material 3 renk paleti üret
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    // Butonlar ve kartlar için ortak yuvarlak köşeli şekil
    final roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // Üst bar: açık teal zemin, koyu teal yazı, başlık ortada, gölgesiz
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
        // Sayfa kaydırılınca bar'ın renk değiştirmesini engelle
        scrolledUnderElevation: 0,
      ),

      // Form alanları: kenarlıklı, yuvarlak köşeli, rahat iç boşluklu
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // Dolu butonlar (ana eylemler: Giriş yap, Kaydet...)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: roundedShape,
        ),
      ),

      // Çerçeveli butonlar (ikincil eylemler: İptal, Kayıt ol...)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: roundedShape,
        ),
      ),

      // Kartlar (ileride Kanban görev kartları)
      cardTheme: CardThemeData(
        elevation: 1,
        shape: roundedShape,
      ),
    );
  }
}