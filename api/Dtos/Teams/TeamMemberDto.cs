//API → mobil

namespace TaskFlowApi.Dtos.Teams;

// Ekip detayındaki bir üye; kullanıcının şifre/kilit gibi bilgileri yok
public class TeamMemberDto
{
    public string UserId { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string TeamRole { get; set; } = string.Empty;
    public DateTime JoinedAt { get; set; }
}