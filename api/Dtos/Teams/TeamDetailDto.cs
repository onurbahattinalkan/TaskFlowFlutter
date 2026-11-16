//API → mobil

namespace TaskFlowApi.Dtos.Teams;

// Ekip detayı: liste bilgilerinin hepsi + üyeler
public class TeamDetailDto : TeamDto
{
    public List<TeamMemberDto> Members { get; set; } = new();

    // Ekibe ait proje sayısı
    public int ProjectCount { get; set; }
}