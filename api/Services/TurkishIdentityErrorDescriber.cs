using Microsoft.AspNetCore.Identity;

namespace TaskFlowApi.Services;

// Identity'nin İngilizce hata mesajlarını Türkçe karşılıklarıyla değiştirir.
// Her metot, ilgili hata oluştuğunda Identity tarafından çağrılır.
public class TurkishIdentityErrorDescriber : IdentityErrorDescriber
{
    // ---------- Genel ----------
    public override IdentityError DefaultError() => new()
    {
        Code = nameof(DefaultError),
        Description = "Bilinmeyen bir hata oluştu."
    };

    public override IdentityError ConcurrencyFailure() => new()
    {
        Code = nameof(ConcurrencyFailure),
        Description = "Kayıt başka bir işlem tarafından değiştirildi, lütfen tekrar deneyin."
    };

    // ---------- Kullanıcı adı ve e-posta ----------
    public override IdentityError InvalidUserName(string? userName) => new()
    {
        Code = nameof(InvalidUserName),
        Description = $"'{userName}' kullanıcı adı geçersiz; yalnızca harf ve rakam kullanılabilir."
    };

    public override IdentityError DuplicateUserName(string userName) => new()
    {
        Code = nameof(DuplicateUserName),
        Description = $"'{userName}' kullanıcı adı zaten kullanılıyor."
    };

    public override IdentityError InvalidEmail(string? email) => new()
    {
        Code = nameof(InvalidEmail),
        Description = $"'{email}' geçerli bir e-posta adresi değil."
    };

    public override IdentityError DuplicateEmail(string email) => new()
    {
        Code = nameof(DuplicateEmail),
        Description = $"'{email}' e-posta adresi zaten kayıtlı."
    };

    // ---------- Şifre ----------
    public override IdentityError PasswordTooShort(int length) => new()
    {
        Code = nameof(PasswordTooShort),
        Description = $"Şifre en az {length} karakter olmalıdır."
    };

    public override IdentityError PasswordRequiresDigit() => new()
    {
        Code = nameof(PasswordRequiresDigit),
        Description = "Şifre en az bir rakam (0-9) içermelidir."
    };

    public override IdentityError PasswordRequiresLower() => new()
    {
        Code = nameof(PasswordRequiresLower),
        Description = "Şifre en az bir küçük harf (a-z) içermelidir."
    };

    public override IdentityError PasswordRequiresUpper() => new()
    {
        Code = nameof(PasswordRequiresUpper),
        Description = "Şifre en az bir büyük harf (A-Z) içermelidir."
    };

    public override IdentityError PasswordRequiresNonAlphanumeric() => new()
    {
        Code = nameof(PasswordRequiresNonAlphanumeric),
        Description = "Şifre en az bir özel karakter içermelidir."
    };

    public override IdentityError PasswordRequiresUniqueChars(int uniqueChars) => new()
    {
        Code = nameof(PasswordRequiresUniqueChars),
        Description = $"Şifre en az {uniqueChars} farklı karakter içermelidir."
    };

    public override IdentityError PasswordMismatch() => new()
    {
        Code = nameof(PasswordMismatch),
        Description = "Şifre hatalı."
    };

    // ---------- Roller ----------
    public override IdentityError InvalidRoleName(string? role) => new()
    {
        Code = nameof(InvalidRoleName),
        Description = $"'{role}' geçerli bir rol adı değil."
    };

    public override IdentityError DuplicateRoleName(string role) => new()
    {
        Code = nameof(DuplicateRoleName),
        Description = $"'{role}' rolü zaten var."
    };

    public override IdentityError UserAlreadyInRole(string role) => new()
    {
        Code = nameof(UserAlreadyInRole),
        Description = $"Kullanıcı zaten '{role}' rolünde."
    };

    public override IdentityError UserNotInRole(string role) => new()
    {
        Code = nameof(UserNotInRole),
        Description = $"Kullanıcı '{role}' rolünde değil."
    };
}