using System.ComponentModel.DataAnnotations;

namespace TaskFlowApi.Dtos.Auth;

// Kayıt isteğinde istemciden gelen veriler
public class RegisterDto
{
    [Required(ErrorMessage = "Ad soyad zorunludur.")]
    [StringLength(100, ErrorMessage = "Ad soyad en fazla 100 karakter olabilir.")]
    public string FullName { get; set; } = string.Empty;

    // Uygulamada görünen ad; Identity'nin izin verdiği karakterlerle sınırlı
    [Required(ErrorMessage = "Kullanıcı adı zorunludur.")]
    [StringLength(50, MinimumLength = 3,
        ErrorMessage = "Kullanıcı adı 3 ile 50 karakter arasında olmalıdır.")]
    [RegularExpression("^[a-zA-Z0-9._-]+$",
        ErrorMessage = "Kullanıcı adı yalnızca İngilizce harf, rakam, nokta, alt çizgi ve tire içerebilir.")]
    public string UserName { get; set; } = string.Empty;

    [Required(ErrorMessage = "E-posta zorunludur.")]
    [EmailAddress(ErrorMessage = "Geçerli bir e-posta adresi girin.")]
    [StringLength(256, ErrorMessage = "E-posta en fazla 256 karakter olabilir.")]
    public string Email { get; set; } = string.Empty;

    // Rakam ve küçük harf kuralını Identity kontrol eder (Adım 3)
    [Required(ErrorMessage = "Şifre zorunludur.")]
    [StringLength(100, MinimumLength = 6,
        ErrorMessage = "Şifre en az 6 karakter olmalıdır.")]
    public string Password { get; set; } = string.Empty;

    // Sadece istekte var, veritabanına yazılmaz
    [Required(ErrorMessage = "Şifre tekrarı zorunludur.")]
    [Compare(nameof(Password), ErrorMessage = "Şifreler eşleşmiyor.")]
    public string ConfirmPassword { get; set; } = string.Empty;
}