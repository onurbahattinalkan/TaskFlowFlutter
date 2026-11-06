using System.ComponentModel.DataAnnotations;

namespace TaskFlowApi.Models;

// Kullanıcı ile ekip arasındaki bağlantı + kullanıcının o ekipteki rolü
public class TeamMember
{
    public int Id { get; set; }

    // Yabancı anahtar: hangi ekip
    public int TeamId { get; set; }
    public Team Team { get; set; } = null!;

    // Yabancı anahtar: hangi kullanıcı (Identity Id'leri string'dir)
    [Required]
    public string UserId { get; set; } = string.Empty;
    public ApplicationUser User { get; set; } = null!;

    // Ekip içi rol; varsayılan "Üye"
    [Required]
    [StringLength(50)]
    public string TeamRole { get; set; } = TeamRoles.Member;

    public DateTime JoinedAt { get; set; } = DateTime.UtcNow;
}