namespace TaskFlowApi.Dtos.Comments;

// API'nin döndürdüğü yorum bilgisi
public class CommentDto
{
    public int Id { get; set; }
    public string Text { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public int TaskItemId { get; set; }

    // Yorumu yazan; mobilde yorumun altında adı gösterilir
    public string UserId { get; set; } = string.Empty;
    public string UserFullName { get; set; } = string.Empty;
}