import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:taskflow_mobile/main.dart';
import 'package:taskflow_mobile/providers/auth_provider.dart';
import 'package:taskflow_mobile/services/token_storage.dart';

// Bellekte çalışan sahte depo (telefonun Keystore'una gitmez)
class MemoryTokenStorage extends TokenStorage {
  String? token;

  MemoryTokenStorage([this.token]);

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String value) async => token = value;

  @override
  Future<void> deleteToken() async => token = null;
}

// Sahte JWT: başlık.içerik.imza (imza kontrol edilmez)
String fakeToken(Map<String, dynamic> payload) {
  String encode(Map<String, dynamic> part) =>
      base64Url.encode(utf8.encode(jsonEncode(part))).replaceAll('=', '');
  return '${encode({'alg': 'HS256', 'typ': 'JWT'})}.${encode(payload)}.imza';
}

// Uygulamayı sanal ekranda açar; token verilirse oturum açık başlar
Future<void> pumpApp(WidgetTester tester, {String? token}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) =>
          AuthProvider(storage: MemoryTokenStorage(token))..init(),
      child: const TaskFlowApp(),
    ),
  );
  // init() bitsin, router doğru ekrana yönlendirsin
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Oturum yoksa giriş ekranı açılıyor', (tester) async {
    await pumpApp(tester);

    expect(find.text('Hesabına giriş yap'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'E-posta'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Şifre'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Giriş Yap'), findsOneWidget);
  });

  testWidgets('Boş form gönderilince doğrulama mesajları çıkıyor',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Giriş Yap'));
    await tester.pump();

    expect(find.text('E-posta zorunludur.'), findsOneWidget);
    expect(find.text('Şifre zorunludur.'), findsOneWidget);
  });

  testWidgets('Geçersiz e-posta biçimi reddediliyor', (tester) async {
    await pumpApp(tester);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'E-posta'), 'zeynep');
    await tester.tap(find.widgetWithText(FilledButton, 'Giriş Yap'));
    await tester.pump();

    expect(find.text('Geçerli bir e-posta adresi girin.'), findsOneWidget);
  });

  testWidgets('Girişten kayıt ekranına geçilip doğrulama çalışıyor',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Hesabın yok mu? Kayıt ol'));
    await tester.pumpAndSettle();
    expect(find.text('Yeni hesap oluştur'), findsOneWidget);

    // Şifreler farklı, şifrede rakam yok
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Şifre'), 'abcdef');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Şifre tekrarı'), 'abcdeg');

    // Uzun form: buton görünür alana kaydırılır
    final button = find.widgetWithText(FilledButton, 'Kayıt Ol');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();

    expect(find.text('Ad soyad zorunludur.'), findsOneWidget);
    expect(find.text('Şifre en az bir rakam (0-9) içermelidir.'),
        findsOneWidget);
    expect(find.text('Şifreler eşleşmiyor.'), findsOneWidget);
  });

  testWidgets('Oturum varsa ana ekran açılıyor, çıkışta girişe dönülüyor',
      (tester) async {
    final token = fakeToken({
      'sub': 'u1',
      'fullName': 'Zeynep Akçay',
      'role': 'User',
      'exp': DateTime.now()
              .add(const Duration(days: 7))
              .millisecondsSinceEpoch ~/
          1000,
    });
    await pumpApp(tester, token: token);

    // Router giriş ekranını atlayıp doğrudan ana ekrana yönlendirdi
    expect(find.text('Hoş geldin, Zeynep Akçay'), findsOneWidget);

    // Çıkış → onay diyaloğu → onayla
    await tester.tap(find.byTooltip('Çıkış yap'));
    await tester.pumpAndSettle();
    expect(find.text('Oturumunu kapatmak istediğine emin misin?'),
        findsOneWidget);

    await tester.tap(find.text('Çıkış Yap'));
    await tester.pumpAndSettle();

    // Router oturumun kapandığını görüp giriş ekranına yönlendirdi
    expect(find.text('Hesabına giriş yap'), findsOneWidget);
  });
}