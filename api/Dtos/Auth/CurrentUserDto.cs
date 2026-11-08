namespace TaskFlowApi.Dtos.Auth;

// GET /api/auth/me cevabı: token'daki kullanıcı bilgileri
public class CurrentUserDto
{
    public string UserId { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public IList<string> Roles { get; set; } = new List<string>();
}