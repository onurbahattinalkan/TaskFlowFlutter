import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow_mobile/models/project.dart';
import 'package:taskflow_mobile/models/task_item.dart';

void main() {
  // API'nin döndürdüğü JSON doğru nesneye dönüşüyor mu?
  test('Project.fromJson API cevabını doğru okur', () {
    final project = Project.fromJson({
      'id': 1,
      'name': 'Mobil Uygulama',
      'description': null,
      'startDate': '2026-11-10',
      'endDate': '2026-12-23',
      'teamId': 1,
      'teamName': 'Deneme Ekibi',
      'taskCount': 3,
    });

    expect(project.name, 'Mobil Uygulama');
    expect(project.startDate, DateTime(2026, 11, 10));
    expect(project.teamName, 'Deneme Ekibi');

    // Geri çevirirken tarih yine "yyyy-MM-dd" olmalı
    expect(project.toJson()['endDate'], '2026-12-23');
  });

  // Sayısal durum doğru enum'a ve Türkçe etikete dönüşüyor mu?
  test('TaskStatus sayıdan doğru duruma çevrilir', () {
    expect(TaskStatus.fromValue(1), TaskStatus.inProgress);
    expect(TaskStatus.fromValue(1).label, 'Devam Ediyor');
    expect(TaskStatus.fromValue(99), TaskStatus.todo);
  });
}