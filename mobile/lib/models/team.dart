import 'json_dates.dart';

// Ekip modeli (Teams API 4. haftada; alanlar veritabanına göre)
class Team {
  final int id;
  final String name;
  final String? description;
  final DateTime? createdAt;

  const Team({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'createdAt': createdAt?.toIso8601String(),
      };
}