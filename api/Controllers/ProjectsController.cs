using System.Linq.Expressions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TaskFlowApi.Data;
using TaskFlowApi.Dtos.Projects;
using TaskFlowApi.Models;

namespace TaskFlowApi.Controllers;

// Adres: /api/projects
// [Authorize] yazmaya gerek yok: varsayılan politika tüm uç noktalarda giriş istiyor.
// Ekip üyeliği / liderlik kontrolleri 5. haftada eklenecek.
[ApiController]
[Route("api/[controller]")]
public class ProjectsController : ControllerBase
{
    private readonly AppDbContext _context;

    public ProjectsController(AppDbContext context)
    {
        _context = context;
    }

    // Entity → DTO dönüşümü; EF Core bunu SQL'e çevirir
    // (ekip adı için JOIN, görev sayısı için COUNT)
    private static readonly Expression<Func<Project, ProjectDto>> ToDto = p => new ProjectDto
    {
        Id = p.Id,
        Name = p.Name,
        Description = p.Description,
        StartDate = p.StartDate,
        EndDate = p.EndDate,
        TeamId = p.TeamId,
        TeamName = p.Team.Name,
        TaskCount = p.Tasks.Count
    };

    // GET /api/projects  veya  /api/projects?teamId=3
    [HttpGet]
    [ProducesResponseType(typeof(IEnumerable<ProjectDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IEnumerable<ProjectDto>>> GetAll([FromQuery] int? teamId)
    {
        // Sadece okuma: değişiklik takibine gerek yok
        var query = _context.Projects.AsNoTracking();

        // Ekip filtresi verildiyse uygula
        if (teamId.HasValue)
        {
            query = query.Where(p => p.TeamId == teamId.Value);
        }

        var projects = await query
            .OrderBy(p => p.Name)
            .Select(ToDto)
            .ToListAsync();

        return Ok(projects);
    }

    // GET /api/projects/5
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ProjectDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ProjectDto>> GetById(int id)
    {
        var project = await FindDtoAsync(id);

        if (project is null)
        {
            return NotFound(new { message = "Proje bulunamadı." });
        }

        return Ok(project);
    }

    // POST /api/projects
    [HttpPost]
    [ProducesResponseType(typeof(ProjectDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<ProjectDto>> Create(ProjectCreateDto dto)
    {
        // Olmayan ekibe proje eklenmesin (yoksa veritabanı hatası → 500 olurdu)
        if (!await _context.Teams.AnyAsync(t => t.Id == dto.TeamId))
        {
            ModelState.AddModelError(nameof(dto.TeamId), "Seçilen ekip bulunamadı.");
            return ValidationProblem(ModelState);
        }

        // DTO'dan yeni entity; Id'yi veritabanı üretir
        var project = new Project
        {
            Name = dto.Name.Trim(),
            Description = NormalizeDescription(dto.Description),
            StartDate = dto.StartDate,
            EndDate = dto.EndDate,
            TeamId = dto.TeamId
        };

        _context.Projects.Add(project);
        await _context.SaveChangesAsync();

        // 201 Created + Location: /api/projects/{yeniId}
        var created = await FindDtoAsync(project.Id);
        return CreatedAtAction(nameof(GetById), new { id = project.Id }, created);
    }

    // PUT /api/projects/5
    [HttpPut("{id:int}")]
    [ProducesResponseType(typeof(ProjectDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ProjectDto>> Update(int id, ProjectUpdateDto dto)
    {
        // Güncellenecek kayıt takip edilerek çekilir (AsNoTracking yok)
        var project = await _context.Projects.FindAsync(id);

        if (project is null)
        {
            return NotFound(new { message = "Proje bulunamadı." });
        }

        // Sadece izin verilen alanlar güncellenir; TeamId değişmez
        project.Name = dto.Name.Trim();
        project.Description = NormalizeDescription(dto.Description);
        project.StartDate = dto.StartDate;
        project.EndDate = dto.EndDate;

        // EF değişen alanları kendisi bulur ve UPDATE üretir
        await _context.SaveChangesAsync();

        return Ok(await FindDtoAsync(id));
    }

    // DELETE /api/projects/5
    [HttpDelete("{id:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int id)
    {
        var project = await _context.Projects.FindAsync(id);

        if (project is null)
        {
            return NotFound(new { message = "Proje bulunamadı." });
        }

        // Cascade ayarı sayesinde görevler ve yorumları da silinir
        _context.Projects.Remove(project);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    // Tek projeyi DTO olarak getirir; yoksa null
    private Task<ProjectDto?> FindDtoAsync(int id)
    {
        return _context.Projects
            .AsNoTracking()
            .Where(p => p.Id == id)
            .Select(ToDto)
            .FirstOrDefaultAsync();
    }

    // Boş veya sadece boşluk olan açıklamayı null olarak sakla
    private static string? NormalizeDescription(string? description)
    {
        return string.IsNullOrWhiteSpace(description) ? null : description.Trim();
    }
}