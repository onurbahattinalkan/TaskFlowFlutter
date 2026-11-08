using Microsoft.AspNetCore.Identity;
using TaskFlowApi.Models;

namespace TaskFlowApi.Data;

// Uygulama açılırken rolleri ve admin hesabını oluşturur.
// Her açılışta çalışır ama var olan kayıtlara dokunmaz (idempotent).
public static class DbSeeder
{
    public static async Task SeedAsync(IServiceProvider services)
    {
        // Scoped servisleri (UserManager, DbContext) kullanabilmek için geçici kapsam
        using var scope = services.CreateScope();
        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var configuration = scope.ServiceProvider.GetRequiredService<IConfiguration>();
        var logger = scope.ServiceProvider.GetRequiredService<ILoggerFactory>().CreateLogger("DbSeeder");

        // ---------- 1) Roller ----------
        foreach (var roleName in new[] { AppRoles.Admin, AppRoles.User })
        {
            if (!await roleManager.RoleExistsAsync(roleName))
            {
                await roleManager.CreateAsync(new IdentityRole(roleName));
                logger.LogInformation("'{Role}' rolü oluşturuldu.", roleName);
            }
        }

        // ---------- 2) Admin hesabı ----------
        // Bilgiler user-secrets'tan gelir (AdminUser:Email, UserName, FullName, Password)
        var email = configuration["AdminUser:Email"];
        var userName = configuration["AdminUser:UserName"];
        var fullName = configuration["AdminUser:FullName"];
        var password = configuration["AdminUser:Password"];

        // Bilgiler eksikse uygulamayı durdurma, sadece uyar
        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(userName) ||
            string.IsNullOrWhiteSpace(fullName) || string.IsNullOrWhiteSpace(password))
        {
            logger.LogWarning("AdminUser ayarları eksik; admin hesabı oluşturulmadı. user-secrets ile ayarlayın.");
            return;
        }

        // Admin zaten varsa yeniden oluşturma
        var admin = await userManager.FindByEmailAsync(email);
        if (admin is null)
        {
            admin = new ApplicationUser
            {
                UserName = userName,
                Email = email,
                FullName = fullName,
                EmailConfirmed = true
            };

            var result = await userManager.CreateAsync(admin, password);
            if (!result.Succeeded)
            {
                // Örneğin şifre kurallara uymuyorsa sebebi loga yazılır
                var errors = string.Join(" ", result.Errors.Select(e => e.Description));
                logger.LogError("Admin hesabı oluşturulamadı: {Errors}", errors);
                return;
            }

            logger.LogInformation("Admin hesabı oluşturuldu: {Email}", email);
        }

        // Admin rolünde değilse ekle
        if (!await userManager.IsInRoleAsync(admin, AppRoles.Admin))
        {
            await userManager.AddToRoleAsync(admin, AppRoles.Admin);
        }
    }
}