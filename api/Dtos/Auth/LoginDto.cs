using System.ComponentModel.DataAnnotations;

namespace TaskFlowApi.Dtos.Auth;

// Giriş isteğinde istemciden gelen veriler (giriş e-posta ile yapılır)
public class LoginDto
{
    [Required(ErrorMessage = "E-posta zorunludur.")]
    [EmailAddress(ErrorMessage = "Geçerli bir e-posta adresi girin.")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Şifre zorunludur.")]
    public string Password { get; set; } = string.Empty;
}   