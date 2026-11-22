import 'json_dates.dart';

// Ekip içi rol adları; API'deki TeamRoles ile aynı yazım
class TeamRoles {
  TeamRoles._();

  static const leader = 'Lider';
  static const member = 'Üye';
}

// GET /api/teams listesindeki bir ekip (API'deki TeamDto)
class Team {
  final int id;
  final String name;
  final String? description;
  final DateTime? createdAt;
  final int memberCount;

  // Giriş yapan kullanıcının bu ekipteki rolü; Admin üye değilse null
  final String? myRole;

  const Team({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
    this.memberCount = 0,
    this.myRole,
  });

  // Kullanıcı bu ekibin lideri mi? (Admin yetkisi ekranda ayrıca kontrol edilir)
  bool get isLeader => myRole == TeamRoles.leader;

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: parseDate(json['createdAt']),
      memberCount: json['memberCount'] as int? ?? 0,
      myRole: json['myRole'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'createdAt': createdAt?.toIso8601String(),
        'memberCount': memberCount,
        'myRole': myRole,
      };
}

// Ekip detayındaki bir üye (API'deki TeamMemberDto)
class TeamMember {
  final String userId;
  final String userName;
  final String fullName;
  final String email;
  final String teamRole;
  final DateTime? joinedAt;

  const TeamMember({
    required this.userId,
    required this.userName,
    required this.fullName,
    required this.email,
    required this.teamRole,
    this.joinedAt,
  });

  bool get isLeader => teamRole == TeamRoles.leader;

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      userId: json['userId'] as String,
      userName: json['userName'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      teamRole: json['teamRole'] as String? ?? TeamRoles.member,
      joinedAt: parseDate(json['joinedAt']),
    );
  }
}

// GET /api/teams/{id} cevabı: ekip bilgileri + üyeler (API'deki TeamDetailDto)
class TeamDetail extends Team {
  final List<TeamMember> members;
  final int projectCount;

  const TeamDetail({
    required super.id,
    required super.name,
    super.description,
    super.createdAt,
    super.memberCount,
    super.myRole,
    this.members = const [],
    this.projectCount = 0,
  });

  factory TeamDetail.fromJson(Map<String, dynamic> json) {
    // Ortak alanları Team.fromJson okusun, tekrar yazmayalım
    final team = Team.fromJson(json);

    return TeamDetail(
      id: team.id,
      name: team.name,
      description: team.description,
      createdAt: team.createdAt,
      memberCount: team.memberCount,
      myRole: team.myRole,
      members: (json['members'] as List<dynamic>? ?? [])
          .map((m) => TeamMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      projectCount: json['projectCount'] as int? ?? 0,
    );
  }
}