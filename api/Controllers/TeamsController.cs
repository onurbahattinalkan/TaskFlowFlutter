using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.JsonWebTokens;
using TaskFlowApi.Data;
using TaskFlowApi.Dtos.Teams;
using TaskFlowApi.Models;
using TaskFlowApi.Services;

namespace TaskFlowApi.Controllers;

// Adres: /api/teams
// [Authorize] yazmaya gerek yok: varsayılan politika tüm uç noktalarda giriş istiyor.
[ApiController]
[Route("api/[controller]")]
public class TeamsController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly ITeamAuthorizationService _teamAuth;
    private readonly UserManager<ApplicationUser> _userManager;

    public TeamsController(
        AppDbContext context,
        ITeamAuthorizationService teamAuth,
        UserManager<ApplicationUser> userManager)
    {
        _context = context;
        _teamAuth = teamAuth;
        _userManager = userManager;
    }

    // GET /api/teams — kullanıcının ekipleri (Admin: tüm ekipler)
    [HttpGet]
    [ProducesResponseType(typeof(IEnumerable<TeamDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IEnumerable<TeamDto>>> GetAll()
    {
        var userId = GetCurrentUserId();
        if (userId is null) return Unauthorized(new { message = "Kullanıcı bilgisi okunamadı." });

        var query = _context.Teams.AsNoTracking();

        // Admin değilse sadece üyesi olduğu ekipler
        if (!await _teamAuth.IsAdminAsync(userId))
        {
            query = query.Where(t => t.Members.Any(m => m.UserId == userId));
        }

        var teams = await query
            .OrderBy(t => t.Name)
            .Select(t => new TeamDto
            {
                Id = t.Id,
                Name = t.Name,
                Description = t.Description,
                CreatedAt = t.CreatedAt,
                MemberCount = t.Members.Count,
                // Bu kullanıcının bu ekipteki rolü; üye değilse (Admin) null
                MyRole = t.Members
                    .Where(m => m.UserId == userId)
                    .Select(m => m.TeamRole)
                    .FirstOrDefault()
            })
            .ToListAsync();

        return Ok(teams);
    }

    // GET /api/teams/3 — ekip detayı + üyeler (sadece ekip üyeleri)
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(TeamDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TeamDetailDto>> GetById(int id)
    {
        var userId = GetCurrentUserId();
        if (userId is null) return Unauthorized(new { message = "Kullanıcı bilgisi okunamadı." });

        if (!await _context.Teams.AnyAsync(t => t.Id == id))
        {
            return NotFound(new { message = "Ekip bulunamadı." });
        }

        if (!await _teamAuth.IsMemberAsync(userId, id))
        {
            return Forbidden("Bu ekibin üyesi değilsiniz.");
        }

        return Ok(await FindDetailAsync(id, userId));
    }

    // POST /api/teams — yeni ekip; kuran kişi otomatik Lider
    [HttpPost]
    [ProducesResponseType(typeof(TeamDetailDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<TeamDetailDto>> Create(TeamCreateDto dto)
    {
        var userId = GetCurrentUserId();
        if (userId is null) return Unauthorized(new { message = "Kullanıcı bilgisi okunamadı." });

        var team = new Team
        {
            Name = dto.Name.Trim(),
            Description = string.IsNullOrWhiteSpace(dto.Description) ? null : dto.Description.Trim()
        };

        // Kurucu, ekibin ilk üyesi ve lideri olarak eklenir.
        // TeamId'yi bilmemize gerek yok: navigation (Team = team) üzerinden EF doldurur.
        team.Members.Add(new TeamMember
        {
            UserId = userId,
            TeamRole = TeamRoles.Leader
        });

        _context.Teams.Add(team);
        // Ekip + lider üyeliği tek SaveChanges = tek transaction
        await _context.SaveChangesAsync();

        var created = await FindDetailAsync(team.Id, userId);
        return CreatedAtAction(nameof(GetById), new { id = team.Id }, created);
    }

    // POST /api/teams/3/members — ekibe üye ekle (sadece Lider)
    [HttpPost("{id:int}/members")]
    [ProducesResponseType(typeof(TeamDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TeamDetailDto>> AddMember(int id, AddMemberDto dto)
    {
        var userId = GetCurrentUserId();
        if (userId is null) return Unauthorized(new { message = "Kullanıcı bilgisi okunamadı." });

        if (!await _context.Teams.AnyAsync(t => t.Id == id))
        {
            return NotFound(new { message = "Ekip bulunamadı." });
        }

        if (!await _teamAuth.IsLeaderAsync(userId, id))
        {
            return Forbidden("Üye eklemek için ekip lideri olmalısınız.");
        }

        // "@" içeriyorsa e-posta, yoksa kullanıcı adı olarak ara
        var input = dto.UserNameOrEmail.Trim();
        var user = input.Contains('@')
            ? await _userManager.FindByEmailAsync(input)
            : await _userManager.FindByNameAsync(input);

        if (user is null)
        {
            ModelState.AddModelError(nameof(dto.UserNameOrEmail), "Bu kullanıcı adı veya e-postaya sahip kullanıcı bulunamadı.");
            return ValidationProblem(ModelState);
        }

        // Aynı kişi iki kez eklenmesin (veritabanındaki benzersiz index'e takılıp 500 olmasın)
        if (await _context.TeamMembers.AnyAsync(tm => tm.TeamId == id && tm.UserId == user.Id))
        {
            ModelState.AddModelError(nameof(dto.UserNameOrEmail), "Bu kullanıcı zaten ekibin üyesi.");
            return ValidationProblem(ModelState);
        }

        // Eklenen kişi her zaman "Üye"; rol istemciden alınmaz
        _context.TeamMembers.Add(new TeamMember
        {
            TeamId = id,
            UserId = user.Id,
            TeamRole = TeamRoles.Member
        });
        await _context.SaveChangesAsync();

        return Ok(await FindDetailAsync(id, userId));
    }

    // POST /api/teams/3/transfer-leadership — liderliği başka bir üyeye devret (sadece Lider)
    [HttpPost("{id:int}/transfer-leadership")]
    [ProducesResponseType(typeof(TeamDetailDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<TeamDetailDto>> TransferLeadership(int id, TransferLeadershipDto dto)
    {
        var userId = GetCurrentUserId();
        if (userId is null) return Unauthorized(new { message = "Kullanıcı bilgisi okunamadı." });

        if (!await _context.Teams.AnyAsync(t => t.Id == id))
        {
            return NotFound(new { message = "Ekip bulunamadı." });
        }

        if (!await _teamAuth.IsLeaderAsync(userId, id))
        {
            return Forbidden("Liderliği devretmek için ekip lideri olmalısınız.");
        }

        // Ekibin tüm üyelikleri takip edilerek çekilir (değiştireceğiz)
        var memberships = await _context.TeamMembers
            .Where(tm => tm.TeamId == id)
            .ToListAsync();

        var newLeader = memberships.FirstOrDefault(tm => tm.UserId == dto.NewLeaderUserId);

        if (newLeader is null)
        {
            ModelState.AddModelError(nameof(dto.NewLeaderUserId), "Yeni lider ekibin üyesi olmalıdır.");
            return ValidationProblem(ModelState);
        }

        if (newLeader.TeamRole == TeamRoles.Leader)
        {
            ModelState.AddModelError(nameof(dto.NewLeaderUserId), "Bu kullanıcı zaten ekibin lideri.");
            return ValidationProblem(ModelState);
        }

        // Mevcut lider(ler) Üye olur, seçilen kişi Lider olur.
        // (Admin üye olmadığı bir ekipte devrederse de mevcut lider Üye'ye düşer.)
        foreach (var leader in memberships.Where(tm => tm.TeamRole == TeamRoles.Leader))
        {
            leader.TeamRole = TeamRoles.Member;
        }
        newLeader.TeamRole = TeamRoles.Leader;

        // İki değişiklik tek SaveChanges = tek transaction; ekip lidersiz kalmaz
        await _context.SaveChangesAsync();

        return Ok(await FindDetailAsync(id, userId));
    }

    // ---------- Yardımcılar ----------

    // Ekip detayını DTO olarak getirir; üyeler: önce Lider, sonra ada göre
    private Task<TeamDetailDto?> FindDetailAsync(int teamId, string userId)
    {
        return _context.Teams
            .AsNoTracking()
            .Where(t => t.Id == teamId)
            .Select(t => new TeamDetailDto
            {
                Id = t.Id,
                Name = t.Name,
                Description = t.Description,
                CreatedAt = t.CreatedAt,
                MemberCount = t.Members.Count,
                ProjectCount = t.Projects.Count,
                MyRole = t.Members
                    .Where(m => m.UserId == userId)
                    .Select(m => m.TeamRole)
                    .FirstOrDefault(),
                Members = t.Members
                    .OrderBy(m => m.TeamRole == TeamRoles.Leader ? 0 : 1)
                    .ThenBy(m => m.User.FullName)
                    .Select(m => new TeamMemberDto
                    {
                        UserId = m.UserId,
                        UserName = m.User.UserName ?? string.Empty,
                        FullName = m.User.FullName,
                        Email = m.User.Email ?? string.Empty,
                        TeamRole = m.TeamRole,
                        JoinedAt = m.JoinedAt
                    })
                    .ToList()
            })
            .FirstOrDefaultAsync();
    }

    // Kullanıcı Id'si istemciden değil, doğrulanmış token'dan ("sub") okunur
    private string? GetCurrentUserId()
    {
        return User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
    }

    // 403 + Türkçe mesaj (mobildeki ApiException "message" alanını okuyor)
    private ObjectResult Forbidden(string message)
    {
        return StatusCode(StatusCodes.Status403Forbidden, new { message });
    }
}