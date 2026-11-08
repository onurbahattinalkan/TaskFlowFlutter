using System.Linq.Expressions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.JsonWebTokens;
using TaskFlowApi.Data;
using TaskFlowApi.Dtos.Comments;
using TaskFlowApi.Models;

namespace TaskFlowApi.Controllers;

// Adresler:
//   /api/tasks/{taskId}/comments  → görevin yorumlarını listele / yorum ekle
//   /api/comments/{id}            → yorum sil (sadece yazan kişi veya Admin)
// [Authorize] yazmaya gerek yok: varsayılan politika tüm uç noktalarda giriş istiyor.
// TODO (Hafta 5): isteği yapanın görevin bulunduğu projenin ekibinde olması kontrolü.
[ApiController]
[Route("api")]
public class CommentsController : ControllerBase
{
    private readonly AppDbContext _context;

    public CommentsController(AppDbContext context)
    {
        _context = context;
    }

    // Entity → DTO dönüşümü; yazanın adı için JOIN'i EF Core üretir
    private static readonly Expression<Func<Comment, CommentDto>> ToDto = c => new CommentDto
    {
        Id = c.Id,
        Text = c.Text,
        CreatedAt = c.CreatedAt,
        TaskItemId = c.TaskItemId,
        UserId = c.UserId,
        UserFullName = c.User.FullName
    };

    // GET /api/tasks/7/comments
    [HttpGet("tasks/{taskId:int}/comments")]
    [ProducesResponseType(typeof(IEnumerable<CommentDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<IEnumerable<CommentDto>>> GetByTask(int taskId)
    {
        // Görev yoksa boş liste yerine 404: "yorum yok" ile "görev yok" karışmasın
        if (!await _context.Tasks.AnyAsync(t => t.Id == taskId))
        {
            return NotFound(new { message = "Görev bulunamadı." });
        }

        // Sohbet gibi okunsun diye eskiden yeniye
        var comments = await _context.Comments
            .AsNoTracking()
            .Where(c => c.TaskItemId == taskId)
            .OrderBy(c => c.CreatedAt)
            .Select(ToDto)
            .ToListAsync();

        return Ok(comments);
    }

    // POST /api/tasks/7/comments
    [HttpPost("tasks/{taskId:int}/comments")]
    [ProducesResponseType(typeof(CommentDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CommentDto>> Create(int taskId, CommentCreateDto dto)
    {
        if (!await _context.Tasks.AnyAsync(t => t.Id == taskId))
        {
            return NotFound(new { message = "Görev bulunamadı." });
        }

        // Yazan kişi istemciden değil, doğrulanmış token'dan alınır
        var userId = GetCurrentUserId();
        if (userId is null)
        {
            return Unauthorized(new { message = "Kullanıcı bilgisi okunamadı." });
        }

        var comment = new Comment
        {
            Text = dto.Text.Trim(),
            TaskItemId = taskId,
            UserId = userId
        };

        _context.Comments.Add(comment);
        await _context.SaveChangesAsync();

        // 201 Created; Location başlığı görevin yorum listesini gösterir
        // (tek yorumu getiren ayrı bir uç nokta yok)
        var created = await _context.Comments
            .AsNoTracking()
            .Where(c => c.Id == comment.Id)
            .Select(ToDto)
            .FirstAsync();

        return CreatedAtAction(nameof(GetByTask), new { taskId }, created);
    }

    // DELETE /api/comments/12
    [HttpDelete("comments/{id:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int id)
    {
        var comment = await _context.Comments.FindAsync(id);

        if (comment is null)
        {
            return NotFound(new { message = "Yorum bulunamadı." });
        }

        // Kimliği biliniyor ama yetkisi yoksa 403 (401 değil)
        var isOwner = comment.UserId == GetCurrentUserId();
        var isAdmin = User.IsInRole(AppRoles.Admin);

        if (!isOwner && !isAdmin)
        {
            return StatusCode(StatusCodes.Status403Forbidden,
                new { message = "Sadece kendi yorumunuzu silebilirsiniz." });
        }

        _context.Comments.Remove(comment);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    // Token'daki "sub" claim'i = kullanıcının Id'si
    // (Program.cs'te MapInboundClaims = false olduğu için adı değişmeden gelir)
    private string? GetCurrentUserId()
    {
        return User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
    }
}