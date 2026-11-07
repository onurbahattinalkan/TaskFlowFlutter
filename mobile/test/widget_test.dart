import 'package:flutter_test/flutter_test.dart';

import 'package:taskflow_mobile/main.dart';

void main() {
  // Uygulama açıldığında açılış ekranı doğru görünüyor mu?
  testWidgets('Açılış ekranı yükleniyor', (WidgetTester tester) async {
    // Uygulamayı sanal ekranda çiz
    await tester.pumpWidget(const TaskFlowApp());

    // Üst bardaki başlık ve karşılama metni
    expect(find.text('TaskFlow Mobil'), findsOneWidget);
    expect(find.text('Hoş geldin'), findsOneWidget);

    // Kartların başlıkları
    expect(find.text('API adresi'), findsOneWidget);
    expect(find.text('Bağlantı'), findsOneWidget);
    expect(find.text('Sürüm'), findsOneWidget);

    // Henüz test yapılmadığı için başlangıç durumu
    expect(find.text('Test edilmedi'), findsOneWidget);

    // Alttaki test butonu
    expect(find.text('API bağlantısını test et'), findsOneWidget);
  });
}