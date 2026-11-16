//mobil → API

using System.ComponentModel.DataAnnotations;

namespace TaskFlowApi.Dtos.Teams;

// POST /api/teams gövdesi. Lider bilgisi gönderilmez: ekibi kuran otomatik lider olur.
public class TeamCreateDto
{
    [Required(ErrorMessage = "Ekip adı zorunludur.")]
    [StringLength(100, ErrorMessage = "Ekip adı en fazla 100 karakter olabilir.")]
    public string Name { get; set; } = string.Empty;

    [StringLength(500, ErrorMessage = "Açıklama en fazla 500 karakter olabilir.")]
    public string? Description { get; set; }
}