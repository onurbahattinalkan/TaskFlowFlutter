using TaskFlowApi.Models;

namespace TaskFlowApi.Services;

// Üretilen token ve bitiş zamanı birlikte döner
public record TokenResult(string Token, DateTime ExpiresAt);

// Kullanıcı için JWT üreten servisin sözleşmesi
public interface ITokenService
{
    Task<TokenResult> CreateTokenAsync(ApplicationUser user);
}