//API → mobil

namespace TaskFlowApi.Dtos.Teams;

// "Ekiplerim" listesindeki bir ekip
public class TeamDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateTime CreatedAt { get; set; }

    // Listede göstermek için üye sayısı
    public int MemberCount { get; set; }

    // İsteği yapan kullanıcının bu ekipteki rolü ("Lider" / "Üye").
    // Admin üyesi olmadığı ekibe bakıyorsa null olur.
    public string? MyRole { get; set; }
}