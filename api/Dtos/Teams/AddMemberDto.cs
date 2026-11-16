// mobil → API

using System.ComponentModel.DataAnnotations;

namespace TaskFlowApi.Dtos.Teams;

// POST /api/teams/{id}/members gövdesi.
// Kullanıcı Id'sini kimse bilmez; bu yüzden kullanıcı adı veya e-posta ile aranır.
// Eklenen kişi her zaman "Üye" olur, rol istemciden alınmaz.
public class AddMemberDto
{
    [Required(ErrorMessage = "Kullanıcı adı veya e-posta zorunludur.")]
    [StringLength(256, ErrorMessage = "Kullanıcı adı veya e-posta en fazla 256 karakter olabilir.")]
    public string UserNameOrEmail { get; set; } = string.Empty;
}