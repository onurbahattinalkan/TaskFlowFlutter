namespace TaskFlowApi.Dtos.Projects;

// API'nin döndürdüğü proje bilgisi (entity yerine)
public class ProjectDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateOnly? StartDate { get; set; }
    public DateOnly? EndDate { get; set; }

    // Ekip nesnesinin tamamı yerine sadece Id ve ad (döngüsel referans olmasın)
    public int TeamId { get; set; }
    public string TeamName { get; set; } = string.Empty;

    // Listede göstermek için projedeki görev sayısı
    public int TaskCount { get; set; }
}