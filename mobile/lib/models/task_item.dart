import 'json_dates.dart';

// Görev durumu; API'de sayı olarak (0, 1, 2) tutulur
enum TaskStatus {
  todo(0, 'Yapılacak'),
  inProgress(1, 'Devam Ediyor'),
  done(2, 'Tamamlandı');

  const TaskStatus(this.value, this.label);

  // API'deki sayısal karşılığı
  final int value;

  // Ekranda gösterilecek Türkçe ad (Kanban sütun başlıkları)
  final String label;

  // API'den gelen sayıyı enum'a çevirir; bilinmeyen değerde "Yapılacak"
  static TaskStatus fromValue(int value) {
    return TaskStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TaskStatus.todo,
    );
  }
}

// Görev modeli (Task API 3. haftada; alanlar veritabanına göre)
class TaskItem {
  final int id;
  final String title;
  final String? description;
  final TaskStatus status;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final int projectId;
  final String? assignedUserId;
  final String? assignedUserName;

  const TaskItem({
    required this.id,
    required this.title,
    this.description,
    this.status = TaskStatus.todo,
    this.dueDate,
    this.createdAt,
    required this.projectId,
    this.assignedUserId,
    this.assignedUserName,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: TaskStatus.fromValue(json['status'] as int? ?? 0),
      dueDate: parseDate(json['dueDate']),
      createdAt: parseDate(json['createdAt']),
      projectId: json['projectId'] as int,
      assignedUserId: json['assignedUserId'] as String?,
      assignedUserName: json['assignedUserName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status.value,
        'dueDate': formatDateOnly(dueDate),
        'createdAt': createdAt?.toIso8601String(),
        'projectId': projectId,
        'assignedUserId': assignedUserId,
        'assignedUserName': assignedUserName,
      };
}