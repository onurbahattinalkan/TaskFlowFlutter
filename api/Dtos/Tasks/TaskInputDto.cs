using System.ComponentModel.DataAnnotations;

namespace TaskFlowApi.Dtos.Tasks;

// Ekleme ve güncellemede ortak olan alanlar ve kurallar.
// abstract: tek başına kullanılmaz, sadece türetilir.
public abstract class TaskInputDto
{
    [Required(ErrorMessage = "Görev başlığı zorunludur.")]
    [StringLength(200, ErrorMessage = "Görev başlığı en fazla 200 karakter olabilir.")]
    public string Title { get; set; } = string.Empty;

    [StringLength(2000, ErrorMessage = "Açıklama en fazla 2000 karakter olabilir.")]
    public string? Description { get; set; }

    // Sadece tarih; JSON'da "2026-11-20" biçiminde
    public DateOnly? DueDate { get; set; }

    // Boş bırakılabilir (atanmamış görev).
    // Doluysa böyle bir kullanıcının varlığını controller kontrol eder.
    public string? AssignedUserId { get; set; }
}