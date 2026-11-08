using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;
using TaskFlowApi.Models;
using TaskFlowApi.Settings;

namespace TaskFlowApi.Services;

public class TokenService : ITokenService
{
    private readonly JwtSettings _settings;
    private readonly UserManager<ApplicationUser> _userManager;

    // Ayarlar ve UserManager dependency injection ile gelir
    public TokenService(IOptions<JwtSettings> options, UserManager<ApplicationUser> userManager)
    {
        _settings = options.Value;
        _userManager = userManager;
    }

    public async Task<TokenResult> CreateTokenAsync(ApplicationUser user)
    {
        // Kullanıcının rolleri (Admin, User) veritabanından okunur
        var roles = await _userManager.GetRolesAsync(user);

        // Token'ın içine yazılacak bilgiler (claim'ler); şifre gibi gizli bilgi konmaz
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id),                       // kullanıcı Id'si
            new(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
            new(JwtRegisteredClaimNames.Name, user.UserName ?? string.Empty),
            new("fullName", user.FullName),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),     // token'a özel benzersiz kimlik
        };

        // Her rol ayrı bir "role" claim'i olarak eklenir
        foreach (var role in roles)
        {
            claims.Add(new Claim("role", role));
        }

        // Gizli anahtarla HMAC-SHA256 imzası
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_settings.Key));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var expiresAt = DateTime.UtcNow.AddDays(_settings.ExpiresInDays);

        // Token'ın tüm özellikleri
        var descriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Issuer = _settings.Issuer,
            Audience = _settings.Audience,
            Expires = expiresAt,
            SigningCredentials = credentials
        };

        // "başlık.içerik.imza" biçimindeki token metnini üret
        var token = new JsonWebTokenHandler().CreateToken(descriptor);

        return new TokenResult(token, expiresAt);
    }
}