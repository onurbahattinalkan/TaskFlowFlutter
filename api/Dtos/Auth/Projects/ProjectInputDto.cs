using System.ComponentModel.DataAnnotations;

namespace TaskFlowApi.Dtos.Projects;

// Ekleme ve güncellemede ortak olan alanlar ve kurallar.
// abstract: tek başına kullanılmaz, sadece türetilir.
public abstract class ProjectInputDto : IValidatableObject
{
    [Required(ErrorMessage = "Proje adı zorunludur.")]
    [StringLength(150, ErrorMessage = "Proje adı en fazla 150 karakter olabilir.")]
    public string Name { get; set; } = string.Empty;

    [StringLength(1000, ErrorMessage = "Açıklama en fazla 1000 karakter olabilir.")]
    public string? Description { get; set; }

    // Sadece tarih; JSON'da "2026-11-08" biçiminde
    public DateOnly? StartDate { get; set; }
    public DateOnly? EndDate { get; set; }

    // Birden fazla alanı birlikte kontrol eden kurallar.
    // Alan bazlı kurallar (Required, StringLength) geçtikten sonra çağrılır.
    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        // İki tarih de girildiyse bitiş, başlangıçtan önce olamaz
        if (StartDate.HasValue && EndDate.HasValue && EndDate < StartDate)
        {
            yield return new ValidationResult(
                "Bitiş tarihi başlangıç tarihinden önce olamaz.",
                new[] { nameof(EndDate) });
        }
    }
}