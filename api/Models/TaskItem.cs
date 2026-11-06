using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TaskFlowApi.Models;

// Sınıf adı TaskItem, çünkü "Task" C#'ta System.Threading.Tasks.Task ile çakışır.
// Tablo adını ise "Tasks" olarak belirliyoruz.
[Table("Tasks")]
public class TaskItem
{
    public int Id { get; set; }

    [Required(ErrorMessage = "Görev başlığı zorunludur.")]
    [StringLength(200, ErrorMessage = "Başlık en fazla 200 karakter olabilir.")]
    public string Title { get; set; } = string.Empty;

    [StringLength(2000, ErrorMessage = "Açıklama en fazla 2000 karakter olabilir.")]
    public string? Description { get; set; }

    // Yeni görev varsayılan olarak "Yapılacak" sütununda başlar
    public TaskItemStatus Status { get; set; } = TaskItemStatus.Todo;

    public DateOnly? DueDate { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Her görev bir projeye aittir (N–1)
    public int ProjectId { get; set; }
    public Project Project { get; set; } = null!;

    // Görev birine atanmamış olabilir, bu yüzden ikisi de nullable
    public string? AssignedUserId { get; set; }
    public ApplicationUser? AssignedUser { get; set; }

    // Bir görevin birden çok yorumu var (1–N)
    public ICollection<Comment> Comments { get; set; } = new List<Comment>();
}