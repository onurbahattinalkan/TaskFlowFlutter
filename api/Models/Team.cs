using System.ComponentModel.DataAnnotations;

namespace TaskFlowApi.Models;

public class Team
{
    // Birincil anahtar (EF Core "Id" adını otomatik tanır)
    public int Id { get; set; }

    [Required(ErrorMessage = "Ekip adı zorunludur.")]
    [StringLength(100, ErrorMessage = "Ekip adı en fazla 100 karakter olabilir.")]
    public string Name { get; set; } = string.Empty;

    // Açıklama zorunlu değil, bu yüzden string? (null olabilir)
    [StringLength(500, ErrorMessage = "Açıklama en fazla 500 karakter olabilir.")]
    public string? Description { get; set; }

    // PostgreSQL timestamptz sütunu UTC zaman ister, bu yüzden UtcNow
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Bir ekibin birden çok üyesi var (1–N)
    public ICollection<TeamMember> Members { get; set; } = new List<TeamMember>();

    // Bir ekibin birden çok projesi var (1–N)
    public ICollection<Project> Projects { get; set; } = new List<Project>();
}