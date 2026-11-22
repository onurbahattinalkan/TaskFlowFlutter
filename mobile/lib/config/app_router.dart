import 'package:go_router/go_router.dart';
import '../screens/teams_screen.dart';

import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/team_detail_screen.dart';

// Ekran adresleri; yazım hatası olmasın diye sabit
class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const home = '/';
  static const teams = '/teams';
    // Ekip Detayı adresi: /teams/3
  static String teamDetail(int id) => '$teams/$id';
}

// Oturum durumuna göre yönlendiren router.
// refreshListenable: AuthProvider değişince redirect yeniden çalışır
GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: auth,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final onAuthPage =
          location == AppRoutes.login || location == AppRoutes.register;

      switch (auth.status) {
        // Token henüz okunuyor: yükleniyor ekranında bekle
        case AuthStatus.unknown:
          return location == AppRoutes.splash ? null : AppRoutes.splash;

        // Giriş yapılmamış: sadece giriş ve kayıt ekranları açık
        case AuthStatus.unauthenticated:
          return onAuthPage ? null : AppRoutes.login;

        // Giriş yapılmış: giriş/kayıt/yükleniyor ekranında durmasın
        case AuthStatus.authenticated:
          if (onAuthPage || location == AppRoutes.splash) {
            return AppRoutes.home;
          }
          return null; // null = olduğu yerde kal
      }
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
            GoRoute(
        path: AppRoutes.teams,
        builder: (context, state) => const TeamsScreen(),
        routes: [
        // Alt adres: /teams/3 → Ekip Detayı (geri tuşu listeye döner)
        GoRoute(
          path: ':id',
          builder: (context, state) {
            // Sayı değilse 0 → API "Ekip bulunamadı." döner, ekran gösterir
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return TeamDetailScreen(teamId: id);
          },
        ),
        ],
      ),
    ],
  );
}