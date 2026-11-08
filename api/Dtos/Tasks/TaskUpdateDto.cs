using System.ComponentModel.DataAnnotations;
using TaskFlowApi.Models;

namespace TaskFlowApi.Dtos.Tasks;

// PUT /api/tasks/{id} isteğinin gövdesi; tüm alanlar yeniden gönderilir.
// ProjectId yok: görev başka bir projeye taşınamaz.
public class TaskUpdateDto : TaskInputDto
{
    // Nullable: enum için [Required] ancak böyle çalışır
    // (nullable olmasaydı gönderilmediğinde sessizce 0 = Todo olurdu)
    [Required(ErrorMessage = "Görev durumu zorunludur.")]
    [EnumDataType(typeof(TaskItemStatus), ErrorMessage = "Geçersiz görev durumu.")]
    public TaskItemStatus? Status { get; set; }
}