using System.ComponentModel.DataAnnotations;
using TaskFlowApi.Models;

namespace TaskFlowApi.Dtos.Tasks;

// POST /api/projects/{projectId}/tasks isteğinin gövdesi.
// ProjectId yok: adresten (URL) alınır.
public class TaskCreateDto : TaskInputDto
{
    // Gönderilmezse görev "Yapılacak" sütununda açılır.
    // EnumDataType: 7 gibi tanımsız bir sayı gelirse 400 döner.
    [EnumDataType(typeof(TaskItemStatus), ErrorMessage = "Geçersiz görev durumu.")]
    public TaskItemStatus Status { get; set; } = TaskItemStatus.Todo;
}