// mobil → API

using System.ComponentModel.DataAnnotations;

namespace TaskFlowApi.Dtos.Teams;

// POST /api/teams/{id}/transfer-leadership gövdesi.
// Yeni lider ekibin mevcut üyelerinden seçilir (mobilde listeden), bu yüzden Id ile gelir.
public class TransferLeadershipDto
{
    [Required(ErrorMessage = "Yeni lider seçilmelidir.")]
    public string NewLeaderUserId { get; set; } = string.Empty;
}