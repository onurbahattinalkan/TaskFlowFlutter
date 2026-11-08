using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using TaskFlowApi.Dtos.Auth;
using TaskFlowApi.Models;
using TaskFlowApi.Services;

using Microsoft.AspNetCore.Authorization;
using Microsoft.IdentityModel.JsonWebTokens;

namespace TaskFlowApi.Controllers;

// Adres: /api/auth/...
[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly ITokenService _tokenService;

    public AuthController(UserManager<ApplicationUser> userManager, ITokenService tokenService)
    {
        _userManager = userManager;
        _tokenService = tokenService;
    }

    // POST /api/auth/register
    [AllowAnonymous]
    [HttpPost("register")]
    [ProducesResponseType(typeof(AuthResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<AuthResponseDto>> Register(RegisterDto dto)
    {
        // DTO'dan yeni kullanıcı nesnesi; Id ve şifre hash'ini Identity üretir
        var user = new ApplicationUser
        {
            UserName = dto.UserName.Trim(),
            Email = dto.Email.Trim(),
            FullName = dto.FullName.Trim()
        };

        // Şifre kuralları ve e-posta/kullanıcı adı tekrarı burada kontrol edilir
        var createResult = await _userManager.CreateAsync(user, dto.Password);
        if (!createResult.Succeeded)
        {
            return IdentityErrors(createResult);
        }

        // Kayıt olan herkes "User" rolünü alır
        var roleResult = await _userManager.AddToRoleAsync(user, AppRoles.User);
        if (!roleResult.Succeeded)
        {
            // Rol verilemediyse yarım hesap kalmasın
            await _userManager.DeleteAsync(user);
            return IdentityErrors(roleResult);
        }

        // Kayıt olan kullanıcı doğrudan giriş yapmış sayılır
        return Ok(await CreateResponseAsync(user));
    }

    // POST /api/auth/login
    [AllowAnonymous]
    [HttpPost("login")]
    [ProducesResponseType(typeof(AuthResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<AuthResponseDto>> Login(LoginDto dto)
    {
        var user = await _userManager.FindByEmailAsync(dto.Email.Trim());

        // Kayıtlı olmayan e-posta ile yanlış şifreye aynı mesaj:
        // hangi e-postaların kayıtlı olduğu dışarıya sızmasın
        if (user is null)
        {
            return Unauthorized(new { message = "E-posta veya şifre hatalı." });
        }

        // Kilitli hesap (5 hatalı deneme veya ileride Admin kilidi)
        if (await _userManager.IsLockedOutAsync(user))
        {
            return Unauthorized(new { message = "Hesabınız geçici olarak kilitlendi. Lütfen daha sonra tekrar deneyin." });
        }

        // Girilen şifre veritabanındaki hash ile karşılaştırılır
        if (!await _userManager.CheckPasswordAsync(user, dto.Password))
        {
            // Hatalı deneme sayacını artır; 5. denemede Identity hesabı kilitler
            await _userManager.AccessFailedAsync(user);

            if (await _userManager.IsLockedOutAsync(user))
            {
                return Unauthorized(new { message = "Çok fazla hatalı deneme yapıldı. Hesabınız 5 dakika kilitlendi." });
            }

            return Unauthorized(new { message = "E-posta veya şifre hatalı." });
        }

        // Başarılı girişte hatalı deneme sayacını sıfırla
        await _userManager.ResetAccessFailedCountAsync(user);

        return Ok(await CreateResponseAsync(user));
    }


    // GET /api/auth/me — sadece giriş yapmış kullanıcılar.
    // Bilgiler veritabanından değil, doğrulanmış token'dan okunur.
    [Authorize]
    [HttpGet("me")]
    [ProducesResponseType(typeof(CurrentUserDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public ActionResult<CurrentUserDto> Me()
    {
        return Ok(new CurrentUserDto
        {
            UserId = User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value ?? string.Empty,
            UserName = User.FindFirst(JwtRegisteredClaimNames.Name)?.Value ?? string.Empty,
            Email = User.FindFirst(JwtRegisteredClaimNames.Email)?.Value ?? string.Empty,
            FullName = User.FindFirst("fullName")?.Value ?? string.Empty,
            Roles = User.FindAll("role").Select(c => c.Value).ToList()
        });
    }


    // GET /api/auth/admin-check — rol bazlı yetkiyi test etmek için.
    // Admin değilse 403 döner. Admin API'si (6. hafta) gelince kaldırılabilir.
    [Authorize(Roles = AppRoles.Admin)]
    [HttpGet("admin-check")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public IActionResult AdminCheck()
    {
        return Ok(new { message = $"Admin yetkisi doğrulandı: {User.Identity?.Name}" });
    }



    // Identity hatalarını ModelState'e ekleyip standart 400 cevabı döner
    // (DTO doğrulama hatalarıyla aynı biçimde olsun diye)
    private ActionResult IdentityErrors(IdentityResult result)
    {
        foreach (var error in result.Errors)
        {
            ModelState.AddModelError(error.Code, error.Description);
        }

        return ValidationProblem(ModelState);
    }

    // Token'ı üretip cevap DTO'sunu doldurur
    private async Task<AuthResponseDto> CreateResponseAsync(ApplicationUser user)
    {
        var token = await _tokenService.CreateTokenAsync(user);

        return new AuthResponseDto
        {
            Token = token.Token,
            ExpiresAt = token.ExpiresAt,
            UserId = user.Id,
            UserName = user.UserName ?? string.Empty,
            Email = user.Email ?? string.Empty,
            FullName = user.FullName,
            Roles = await _userManager.GetRolesAsync(user)
        };
    }
}