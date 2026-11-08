import 'package:jwt_decoder/jwt_decoder.dart';

// Giriş yapmış kullanıcının bilgileri (şifre yok)
class AuthUser {
  final String id;
  final String userName;
  final String email;
  final String fullName;
  final List<String> roles;

  const AuthUser({
    required this.id,
    required this.userName,
    required this.email,
    required this.fullName,
    this.roles = const [],
  });

  // Rol bazlı menü için (Admin paneli ileride)
  bool get isAdmin => roles.contains('Admin');

  // Login/register cevabından (AuthResponseDto) üretir
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((role) => role.toString())
          .toList(),
    );
  }

  // Saklanan token'dan üretir (uygulama yeniden açıldığında).
  // Claim adları API'deki TokenService ile aynı: sub, name, email, fullName, role
  factory AuthUser.fromToken(String token) {
    final claims = JwtDecoder.decode(token);

    // Tek rol varsa metin, birden fazlaysa liste olarak gelir
    final role = claims['role'];
    final roles = switch (role) {
      List<dynamic> list => list.map((r) => r.toString()).toList(),
      String single => [single],
      _ => <String>[],
    };

    return AuthUser(
      id: claims['sub'] as String? ?? '',
      userName: claims['name'] as String? ?? '',
      email: claims['email'] as String? ?? '',
      fullName: claims['fullName'] as String? ?? '',
      roles: roles,
    );
  }
}

// POST /api/auth/login ve /register cevabı
class AuthResponse {
  final String token;
  final DateTime expiresAt;
  final AuthUser user;

  const AuthResponse({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      // Kullanıcı alanları cevabın kendisinde (iç içe nesne değil)
      user: AuthUser.fromJson(json),
    );
  }
}