import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taskflow_mobile/models/project.dart';
import 'package:taskflow_mobile/models/team.dart';
import 'package:taskflow_mobile/screens/project_form_screen.dart';
import 'package:taskflow_mobile/services/api_service.dart';
import 'package:taskflow_mobile/utils/project_validators.dart';

// API'ye gitmeyen sahte servis: kaç kez çağrıldığını sayar
class FakeApiService extends ApiService {
  // Formun ekip listesi; gerçek API yerine tek ekip
  @override
  Future<List<Team>> getTeams() async =>
      const [Team(id: 1, name: 'Deneme Ekibi', myRole: 'Lider')];

  int createCalls = 0;
  int updateCalls = 0;
  int? lastTeamId;

  @override
  Future<Project> createProject({
    required String name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    required int teamId,
  }) async {
    createCalls++;
    lastTeamId = teamId;
    return Project(id: 1, name: name, teamId: teamId, teamName: 'Deneme Ekibi');
  }

  @override
  Future<Project> updateProject(
    int id, {
    required String name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    updateCalls++;
    return Project(id: id, name: name, teamId: 1, teamName: 'Deneme Ekibi');
  }
}

// Kaydet butonu ekranın altında kalabilir; önce görünür yap, sonra dokun
Future<void> tapSave(WidgetTester tester) async {
  final button = find.widgetWithText(FilledButton, 'Kaydet');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  group('ProjectValidators', () {
    test('bitiş başlangıçtan önceyse hata, aynı gün veya sonrası geçerli', () {
      final start = DateTime(2026, 11, 20);

      expect(ProjectValidators.dateRange(start, DateTime(2026, 11, 19)),
          'Bitiş tarihi başlangıç tarihinden önce olamaz.');
      expect(ProjectValidators.dateRange(start, start), isNull);
      expect(ProjectValidators.dateRange(start, DateTime(2026, 12, 1)), isNull);
      // Tarihler isteğe bağlı: biri boşsa kural uygulanmaz
      expect(ProjectValidators.dateRange(start, null), isNull);
    });

    test('proje adı zorunlu ve en fazla 150 karakter', () {
      expect(ProjectValidators.name('   '), 'Proje adı zorunludur.');
      expect(ProjectValidators.name('a' * 151),
          'Proje adı en fazla 150 karakter olabilir.');
      expect(ProjectValidators.name('Mobil Uygulama'), isNull);
    });
  });

  testWidgets('Boş form gönderilince ad zorunlu mesajı çıkar, API çağrılmaz',
      (tester) async {
    final api = FakeApiService();
    await tester.pumpWidget(MaterialApp(home: ProjectFormScreen(api: api)));
    // Ekip listesi yüklensin
    await tester.pumpAndSettle();

    expect(find.text('Yeni Proje'), findsOneWidget);
    await tapSave(tester);

    expect(find.text('Proje adı zorunludur.'), findsOneWidget);
    expect(api.createCalls, 0);
  });

  testWidgets('Düzenlemede bitiş başlangıçtan önceyse kaydedilmez',
      (tester) async {
    final api = FakeApiService();
    final project = Project(
      id: 7,
      name: 'Eski Proje',
      teamId: 1,
      teamName: 'Deneme Ekibi',
      startDate: DateTime(2026, 11, 20),
      endDate: DateTime(2026, 11, 10),
    );

    await tester.pumpWidget(MaterialApp(
      home: ProjectFormScreen(projectId: 7, initialProject: project, api: api),
    ));
    await tester.pumpAndSettle();

    // Mevcut değerler forma dolmuş olmalı
    expect(find.text('Projeyi Düzenle'), findsOneWidget);
    expect(find.text('Eski Proje'), findsOneWidget);
    expect(find.text('20.11.2026'), findsOneWidget);

    await tapSave(tester);

    expect(find.text('Bitiş tarihi başlangıç tarihinden önce olamaz.'),
        findsOneWidget);
    expect(api.updateCalls, 0);
  });

  testWidgets('Geçerli form kaydedilince API çağrılır ve ekran kapanır',
      (tester) async {
    final api = FakeApiService();
    String? result;

    // Formu gerçek uygulamadaki gibi push ile aç, dönen mesajı yakala
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async =>
                  result = await context.push<String>('/new'),
              child: const Text('Formu aç'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/new',
        builder: (context, state) => ProjectFormScreen(api: api),
      ),
    ]);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Formu aç'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Proje adı'), 'Mobil Uygulama');
    await tapSave(tester);

    expect(api.createCalls, 1);
    expect(api.lastTeamId, 1); // tek ekip olduğu için otomatik seçildi
    expect(result, 'Proje eklendi.');
    expect(find.text('Formu aç'), findsOneWidget); // forma geri dönüldü
  });
}
