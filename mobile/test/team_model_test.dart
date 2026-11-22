import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow_mobile/models/team.dart';

void main() {
  test('TeamDetail.fromJson API cevabını doğru okur', () {
    final json = {
      'id': 3,
      'name': 'Test Ekibi',
      'description': 'deneme',
      'createdAt': '2026-11-22T10:00:00Z',
      'memberCount': 2,
      'myRole': 'Lider',
      'projectCount': 1,
      'members': [
        {
          'userId': 'a1',
          'userName': 'testa',
          'fullName': 'Test Kullanıcı A',
          'email': 'testa@taskflow.com',
          'teamRole': 'Lider',
          'joinedAt': '2026-11-22T10:00:00Z',
        },
        {
          'userId': 'b2',
          'userName': 'testb',
          'fullName': 'Test Kullanıcı B',
          'email': 'testb@taskflow.com',
          'teamRole': 'Üye',
          'joinedAt': '2026-11-22T10:05:00Z',
        },
      ],
    };

    final team = TeamDetail.fromJson(json);

    expect(team.name, 'Test Ekibi');
    expect(team.isLeader, isTrue);
    expect(team.members.length, 2);
    expect(team.members.first.isLeader, isTrue);
    expect(team.members.last.teamRole, TeamRoles.member);
  });

  test('Admin üye değilse myRole null ve lider sayılmaz', () {
    final team = Team.fromJson({'id': 1, 'name': 'X', 'myRole': null});

    expect(team.myRole, isNull);
    expect(team.isLeader, isFalse);
    expect(team.memberCount, 0);
  });
}