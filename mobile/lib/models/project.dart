import 'json_dates.dart';

// API'deki ProjectDto'nun Dart karşılığı
class Project {
  final int id;
  final String name;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final int teamId;
  final String teamName;
  final int taskCount;

  const Project({
    required this.id,
    required this.name,
    this.description,
    this.startDate,
    this.endDate,
    required this.teamId,
    required this.teamName,
    this.taskCount = 0,
  });

  // API'den gelen JSON'dan nesne oluştur
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      teamId: json['teamId'] as int,
      teamName: json['teamName'] as String? ?? '',
      taskCount: json['taskCount'] as int? ?? 0,
    );
  }

  // Nesneyi JSON'a çevir (tarihler "yyyy-MM-dd")
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'startDate': formatDateOnly(startDate),
        'endDate': formatDateOnly(endDate),
        'teamId': teamId,
        'teamName': teamName,
        'taskCount': taskCount,
      };
}