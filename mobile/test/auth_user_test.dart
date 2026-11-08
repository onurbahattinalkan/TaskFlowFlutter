import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow_mobile/models/auth_user.dart';

// Test için sahte JWT: başlık.içerik.imza (imza kontrol edilmez)
String fakeToken(Map<String, dynamic> payload) {
  String encode(Map<String, dynamic> part) =>
      base64Url.encode(utf8.encode(jsonEncode(part))).replaceAll('=', '');
  return '${encode({'alg': 'HS256', 'typ': 'JWT'})}.${encode(payload)}.imza';
}

void main() {
  test('Login cevabı AuthResponse olarak okunuyor', () {
    final response = AuthResponse.fromJson({
      'token': 'abc',
      'expiresAt': '2026-11-15T10:00:00Z',
      'userId': 'u1',
      'userName': 'zeynep',
      'email': 'zeynep@test.com',
      'fullName': 'Zeynep Akçay',
      'roles': ['User'],
    });

    expect(response.token, 'abc');
    expect(response.expiresAt.isUtc, isTrue);
    expect(response.user.fullName, 'Zeynep Akçay');
    expect(response.user.isAdmin, isFalse);
  });

  test('Tek rollü token okunuyor (role metin olarak)', () {
    final user = AuthUser.fromToken(fakeToken({
      'sub': 'u1',
      'name': 'admin',
      'email': 'admin@test.com',
      'fullName': 'Sistem Yöneticisi',
      'role': 'Admin',
    }));

    expect(user.id, 'u1');
    expect(user.fullName, 'Sistem Yöneticisi');
    expect(user.roles, ['Admin']);
    expect(user.isAdmin, isTrue);
  });

  test('Çok rollü token okunuyor (role liste olarak)', () {
    final user = AuthUser.fromToken(fakeToken({
      'sub': 'u2',
      'role': ['Admin', 'User'],
    }));

    expect(user.roles, ['Admin', 'User']);
    expect(user.isAdmin, isTrue);
  });
}