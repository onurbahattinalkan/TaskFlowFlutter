namespace TaskFlowApi.Dtos.Auth;

// Başarılı kayıt veya girişte istemciye dönen cevap
public class AuthResponseDto
{
    // Mobil uygulamanın saklayıp her istekte göndereceği JWT
    public string Token { get; set; } = string.Empty;

    // Token'ın geçerlilik bitişi (UTC)
    public DateTime ExpiresAt { get; set; }

    // Ekranda göstermek için kullanıcı bilgileri (şifre/hash yok)
    public string UserId { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;

    // Admin / User; mobilde menüyü role göre göstermek için
    public IList<string> Roles { get; set; } = new List<string>();
}