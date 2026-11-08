namespace TaskFlowApi.Settings;

// appsettings.json'daki "Jwt" bölümünün C# karşılığı.
// Key user-secrets'tan, diğerleri appsettings.json'dan gelir.
public class JwtSettings
{
    // Token imzalamak için gizli anahtar
    public string Key { get; set; } = string.Empty;

    // Token'ı üreten (bizim API)
    public string Issuer { get; set; } = string.Empty;

    // Token'ın hedefi (mobil uygulama)
    public string Audience { get; set; } = string.Empty;

    // Token kaç gün geçerli
    public int ExpiresInDays { get; set; } = 7;
}