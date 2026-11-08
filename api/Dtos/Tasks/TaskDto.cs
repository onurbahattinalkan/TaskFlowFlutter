using TaskFlowApi.Models;

namespace TaskFlowApi.Dtos.Tasks;

// API'nin döndürdüğü görev bilgisi (entity yerine)
public class TaskDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }

    // JSON'da sayı olarak döner: 0 Yapılacak, 1 Devam Ediyor, 2 Tamamlandı
    public TaskItemStatus Status { get; set; }

    public DateOnly? DueDate { get; set; }
    public DateTime CreatedAt { get; set; }

    public int ProjectId { get; set; }

    // Kullanıcı nesnesinin tamamı yerine sadece Id ve ad (döngüsel referans olmasın)
    public string? AssignedUserId { get; set; }
    public string? AssignedUserName { get; set; }

    // Kanban kartında "3 yorum" göstermek için
    public int CommentCount { get; set; }
}