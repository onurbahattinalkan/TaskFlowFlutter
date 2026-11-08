using System.ComponentModel.DataAnnotations;

namespace TaskFlowApi.Dtos.Comments;

// POST /api/tasks/{taskId}/comments isteğinin gövdesi.
// UserId yok: yazan kişi istemciden değil, JWT token'dan alınır
// (yoksa biri başkası adına yorum yazabilirdi).
public class CommentCreateDto
{
    [Required(ErrorMessage = "Yorum metni boş olamaz.")]
    [StringLength(1000, ErrorMessage = "Yorum en fazla 1000 karakter olabilir.")]
    public string Text { get; set; } = string.Empty;
}