using System.ComponentModel.DataAnnotations;

namespace TaskFlowApi.Dtos.Projects;

// POST /api/projects isteğinin gövdesi
public class ProjectCreateDto : ProjectInputDto
{
    // int için [Required] işe yaramaz (gönderilmezse 0 olur),
    // bu yüzden 1 ve üstünü zorunlu kılıyoruz
    [Range(1, int.MaxValue, ErrorMessage = "Geçerli bir ekip seçin.")]
    public int TeamId { get; set; }
}