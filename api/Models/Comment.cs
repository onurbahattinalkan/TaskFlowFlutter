using System.ComponentModel.DataAnnotations;

namespace TaskFlowApi.Models;

public class Comment
{
    public int Id { get; set; }

    [Required(ErrorMessage = "Yorum metni zorunludur.")]
    [StringLength(1000, ErrorMessage = "Yorum en fazla 1000 karakter olabilir.")]
    public string Text { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Yorum hangi göreve ait (N–1)
    public int TaskItemId { get; set; }
    public TaskItem TaskItem { get; set; } = null!;

    // Yorumu yazan kullanıcı (N–1)
    [Required]
    public string UserId { get; set; } = string.Empty;
    public ApplicationUser User { get; set; } = null!;
}