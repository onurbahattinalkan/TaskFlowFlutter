using System.ComponentModel.DataAnnotations;

namespace TaskFlowApi.Models;

public class Project
{
    public int Id { get; set; }

    [Required(ErrorMessage = "Proje adı zorunludur.")]
    [StringLength(150, ErrorMessage = "Proje adı en fazla 150 karakter olabilir.")]
    public string Name { get; set; } = string.Empty;

    [StringLength(1000, ErrorMessage = "Açıklama en fazla 1000 karakter olabilir.")]
    public string? Description { get; set; }

    // Sadece tarih (saat yok); PostgreSQL'de "date" sütunu olur
    public DateOnly? StartDate { get; set; }
    public DateOnly? EndDate { get; set; }

    // Her proje bir ekibe aittir (N–1)
    public int TeamId { get; set; }
    public Team Team { get; set; } = null!;

    // Bir projenin birden çok görevi var (1–N)
    public ICollection<TaskItem> Tasks { get; set; } = new List<TaskItem>();
}