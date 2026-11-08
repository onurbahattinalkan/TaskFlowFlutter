using System.ComponentModel.DataAnnotations;
using TaskFlowApi.Models;

namespace TaskFlowApi.Dtos.Tasks;

// PATCH /api/tasks/{id}/status isteğinin gövdesi.
// Kanban'da kart sürüklenince sadece yeni durum gönderilir.
public class TaskStatusUpdateDto
{
    [Required(ErrorMessage = "Görev durumu zorunludur.")]
    [EnumDataType(typeof(TaskItemStatus), ErrorMessage = "Geçersiz görev durumu.")]
    public TaskItemStatus? Status { get; set; }
}