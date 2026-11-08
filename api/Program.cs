using Microsoft.OpenApi;
using Microsoft.EntityFrameworkCore;
using TaskFlowApi.Data;
using Microsoft.AspNetCore.Identity;
using TaskFlowApi.Models;
using TaskFlowApi.Services;
using TaskFlowApi.Settings;

using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.IdentityModel.Tokens;


var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();



//bağlantı dizesini appsettings.json'dan alıyoruz
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

// appsettings.json'daki değer boş olduğu için boş string kontrolü de yapıyoruz;
// user-secrets ayarlanmamışsa uygulama anlaşılır bir hatayla dursun
if (string.IsNullOrWhiteSpace(connectionString))
{
    throw new InvalidOperationException(
        "Bağlantı dizesi bulunamadı. 'dotnet user-secrets set \"ConnectionStrings:DefaultConnection\" ...' ile ayarlayın.");
}

// AppDbContext'i servis olarak kaydet ve PostgreSQL (Npgsql) kullanacağını belirt
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(connectionString));



// Identity: kullanıcı ve rol yönetimi (UserManager, RoleManager).
// AddIdentity yerine AddIdentityCore: cookie tabanlı oturumu kurmaz,
// çünkü API'miz JWT token ile çalışacak.
builder.Services
    .AddIdentityCore<ApplicationUser>(options =>
    {
        // Şifre kuralları (web projesiyle aynı)
        options.Password.RequiredLength = 6;
        options.Password.RequireDigit = true;
        options.Password.RequireLowercase = true;
        options.Password.RequireUppercase = false;
        options.Password.RequireNonAlphanumeric = false;

        // Aynı e-posta ile ikinci hesap açılamaz
        options.User.RequireUniqueEmail = true;

        // 5 hatalı şifre denemesinde hesap 5 dakika kilitlenir
        options.Lockout.MaxFailedAccessAttempts = 5;
        options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(5);
        options.Lockout.AllowedForNewUsers = true;
    })
    // Admin / User rolleri için RoleManager'ı da ekle
    .AddRoles<IdentityRole>()
    // Kullanıcı ve rolleri AppDbContext üzerinden PostgreSQL'de sakla
    .AddEntityFrameworkStores<AppDbContext>()
    // Hata mesajlarını Türkçe olarak üret
    .AddErrorDescriber<TurkishIdentityErrorDescriber>();



// "Jwt" bölümünü JwtSettings sınıfına bağla (Options pattern)
builder.Services.Configure<JwtSettings>(builder.Configuration.GetSection("Jwt"));

// Anahtar yoksa veya çok kısaysa uygulama anlaşılır bir hatayla dursun
var jwtSettings = builder.Configuration.GetSection("Jwt").Get<JwtSettings>();
if (jwtSettings is null || jwtSettings.Key.Length < 32)
{
    throw new InvalidOperationException(
        "JWT anahtarı bulunamadı veya çok kısa. 'dotnet user-secrets set \"Jwt:Key\" ...' ile ayarlayın.");
}

// Token servisi: her HTTP isteği için bir örnek oluşturulur
builder.Services.AddScoped<ITokenService, TokenService>();



// Gelen isteklerdeki "Authorization: Bearer <token>" başlığını doğrula
builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        // Token'daki kısa claim adlarını (sub, name, role) olduğu gibi kullan
        options.MapInboundClaims = false;

        options.TokenValidationParameters = new TokenValidationParameters
        {
            // Token'ı bizim API mi üretti?
            ValidateIssuer = true,
            ValidIssuer = jwtSettings.Issuer,

            // Token bizim uygulama için mi?
            ValidateAudience = true,
            ValidAudience = jwtSettings.Audience,

            // İmza bizim gizli anahtarımızla mı atılmış? (değiştirilmiş token reddedilir)
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings.Key)),

            // Süresi dolmuş mu? Saat farkları için 1 dk tolerans
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromMinutes(1),

            // User.Identity.Name ve rol kontrolleri hangi claim'den okunsun
            NameClaimType = "name",
            RoleClaimType = "role"
        };
    });

// Yetkilendirme: aksi belirtilmedikçe tüm uç noktalar giriş ister (secure by default)
builder.Services.AddAuthorization(options =>
{
    options.FallbackPolicy = new AuthorizationPolicyBuilder()
        .RequireAuthenticatedUser()
        .Build();
});




// Controller'lardaki uç noktaları Swagger'ın görebilmesi için keşif servisi
builder.Services.AddEndpointsApiExplorer();

// Swagger dokümanını üret; başlık ve sürüm arayüzün üstünde görünür
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "TaskFlow Mobil API",
        Version = "v1",
        Description = "TaskFlow Mobil uygulaması için ekip, proje ve görev yönetimi Web API'si"
    });

        // Sayfaya "Authorize" butonu ekle: API, HTTP Bearer ile JWT kullanıyor
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        Description = "Giriş yaptıktan sonra dönen token'ı yapıştırın (başına 'Bearer' yazmayın)."
    });

    // Girilen token'ı tüm isteklere Authorization başlığı olarak ekle
    options.AddSecurityRequirement(document => new OpenApiSecurityRequirement
    {
        [new OpenApiSecuritySchemeReference("Bearer", document)] = []
    });
});



var app = builder.Build();

// Açılışta rolleri ve admin hesabını oluştur (zaten varsa dokunmaz)
await DbSeeder.SeedAsync(app.Services);

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    // OpenAPI JSON dosyasını /swagger/v1/swagger.json adresinde yayınla
    app.UseSwagger();
    // Bu JSON'u okuyup /swagger adresinde test arayüzünü göster
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// Önce kim olduğunu belirle (token), sonra izinlerini kontrol et
app.UseAuthentication();

app.UseAuthorization();

app.MapControllers();

app.Run();
