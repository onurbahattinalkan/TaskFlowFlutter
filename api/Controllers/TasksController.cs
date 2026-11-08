using System.Linq.Expressions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TaskFlowApi.Data;
using TaskFlowApi.Dtos.Tasks;
using TaskFlowApi.Models;

namespace TaskFlowApi.Controllers;

// Adresler:
//   /api/projects/{projectId}/tasks  → projenin görevlerini listele / projeye görev ekle
//   /api/tasks/{id}                  → tek görev: getir / güncelle / sil
//   /api/tasks/{id}/status           → sadece durumu değiştir (Kanban)
// [Authorize] yazmaya gerek yok: varsayılan politika tüm uç noktalarda giriş istiyor.
// TODO (Hafta 5): isteği yapanın projenin ekibinde olması ve
//                 atanan kişinin ekip üyesi olması kontrolleri.
[ApiController]
[Route("api")]
public class TasksController : ControllerBase
{
    private readonly AppDbContext _context;

    public TasksController(AppDbContext context)
    {
        _context = context;
    }

    // Entity → DTO dönüşümü; EF Core bunu SQL'e çevirir
    // (atanan kişinin adı için LEFT JOIN, yorum sayısı için COUNT)
    private static readonly Expression<Func<TaskItem, TaskDto>> ToDto = t => new TaskDto
    {
        Id = t.Id,
        Title = t.Title,
        Description = t.Description,
        Status = t.Status,
        DueDate = t.DueDate,
        CreatedAt = t.CreatedAt,
        ProjectId = t.ProjectId,
        AssignedUserId = t.AssignedUserId,
        // Görev atanmamış olabilir
        AssignedUserName = t.AssignedUser != null ? t.AssignedUser.FullName : null,
        CommentCount = t.Comments.Count
    };

    // GET /api/projects/5/tasks
    [HttpGet("projects/{projectId:int}/tasks")]
    [ProducesResponseType(typeof(IEnumerable<TaskDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<IEnumerable<TaskDto>>> GetByProject(int projectId)
    {
        // Proje yoksa boş liste yerine 404: "görev yok" ile "proje yok" karışmasın
        if (!await _context.Projects.AnyAsync(p => p.Id == projectId))
        {
            return NotFound(new { message = "Proje bulunamadı." });
        }

        var tasks = await _context.Tasks
            .AsNoTracking()
            .Where(t => t.ProjectId == projectId)
            .OrderBy(t => t.CreatedAt)
            .Select(ToDto)
            .ToListAsync();

        return Ok(tasks);
    }

    // GET /api/tasks/7
    [HttpGet("tasks/{id:int}")]
    [ProducesResponseType(typeof(TaskDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TaskDto>> GetById(int id)
    {
        var task = await FindDtoAsync(id);

        if (task is null)
        {
            return NotFound(new { message = "Görev bulunamadı." });
        }

        return Ok(task);
    }

    // POST /api/projects/5/tasks
    [HttpPost("projects/{projectId:int}/tasks")]
    [ProducesResponseType(typeof(TaskDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TaskDto>> Create(int projectId, TaskCreateDto dto)
    {
        // Olmayan projeye görev eklenmesin (yoksa veritabanı hatası → 500 olurdu)
        if (!await _context.Projects.AnyAsync(p => p.Id == projectId))
        {
            return NotFound(new { message = "Proje bulunamadı." });
        }

        var assignedUserId = NormalizeUserId(dto.AssignedUserId);
        if (!await AssignedUserExistsAsync(assignedUserId))
        {
            ModelState.AddModelError(nameof(dto.AssignedUserId), "Atanan kullanıcı bulunamadı.");
            return ValidationProblem(ModelState);
        }

        // DTO'dan yeni entity; Id ve CreatedAt'i sistem üretir
        var task = new TaskItem
        {
            Title = dto.Title.Trim(),
            Description = NormalizeDescription(dto.Description),
            Status = dto.Status,
            DueDate = dto.DueDate,
            ProjectId = projectId,
            AssignedUserId = assignedUserId
        };

        _context.Tasks.Add(task);
        await _context.SaveChangesAsync();

        // 201 Created + Location: /api/tasks/{yeniId}
        var created = await FindDtoAsync(task.Id);
        return CreatedAtAction(nameof(GetById), new { id = task.Id }, created);
    }

    // PUT /api/tasks/7  (tüm alanlar güncellenir)
    [HttpPut("tasks/{id:int}")]
    [ProducesResponseType(typeof(TaskDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TaskDto>> Update(int id, TaskUpdateDto dto)
    {
        // Güncellenecek kayıt takip edilerek çekilir (AsNoTracking yok)
        var task = await _context.Tasks.FindAsync(id);

        if (task is null)
        {
            return NotFound(new { message = "Görev bulunamadı." });
        }

        var assignedUserId = NormalizeUserId(dto.AssignedUserId);
        if (!await AssignedUserExistsAsync(assignedUserId))
        {
            ModelState.AddModelError(nameof(dto.AssignedUserId), "Atanan kullanıcı bulunamadı.");
            return ValidationProblem(ModelState);
        }

        // Sadece izin verilen alanlar; ProjectId ve CreatedAt değişmez
        task.Title = dto.Title.Trim();
        task.Description = NormalizeDescription(dto.Description);
        // [Required] sayesinde buraya gelindiyse Status doludur
        task.Status = dto.Status!.Value;
        task.DueDate = dto.DueDate;
        task.AssignedUserId = assignedUserId;

        await _context.SaveChangesAsync();

        return Ok(await FindDtoAsync(id));
    }

    // PATCH /api/tasks/7/status  (sadece durum; Kanban sürükle-bırak)
    [HttpPatch("tasks/{id:int}/status")]
    [ProducesResponseType(typeof(TaskDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TaskDto>> UpdateStatus(int id, TaskStatusUpdateDto dto)
    {
        var task = await _context.Tasks.FindAsync(id);

        if (task is null)
        {
            return NotFound(new { message = "Görev bulunamadı." });
        }

        // Diğer alanlara dokunulmaz; EF sadece Status sütunu için UPDATE üretir
        task.Status = dto.Status!.Value;
        await _context.SaveChangesAsync();

        return Ok(await FindDtoAsync(id));
    }

    // DELETE /api/tasks/7
    [HttpDelete("tasks/{id:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int id)
    {
        var task = await _context.Tasks.FindAsync(id);

        if (task is null)
        {
            return NotFound(new { message = "Görev bulunamadı." });
        }

        // Cascade ayarı sayesinde görevin yorumları da silinir
        _context.Tasks.Remove(task);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    // Tek görevi DTO olarak getirir; yoksa null
    private Task<TaskDto?> FindDtoAsync(int id)
    {
        return _context.Tasks
            .AsNoTracking()
            .Where(t => t.Id == id)
            .Select(ToDto)
            .FirstOrDefaultAsync();
    }

    // Atama yoksa (null) geçerli sayılır; varsa kullanıcı veritabanında olmalı
    private async Task<bool> AssignedUserExistsAsync(string? userId)
    {
        if (userId is null)
        {
            return true;
        }

        return await _context.Users.AnyAsync(u => u.Id == userId);
    }

    // Boş veya sadece boşluk olan açıklamayı null olarak sakla
    private static string? NormalizeDescription(string? description)
    {
        return string.IsNullOrWhiteSpace(description) ? null : description.Trim();
    }

    // Mobil atamayı kaldırırken "" gönderebilir; bunu "atanmamış" (null) say
    private static string? NormalizeUserId(string? userId)
    {
        return string.IsNullOrWhiteSpace(userId) ? null : userId.Trim();
    }
}