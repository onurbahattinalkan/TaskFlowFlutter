using Microsoft.OpenApi;
using Microsoft.EntityFrameworkCore;
using TaskFlowApi.Data;


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
});



var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    // OpenAPI JSON dosyasını /swagger/v1/swagger.json adresinde yayınla
    app.UseSwagger();
    // Bu JSON'u okuyup /swagger adresinde test arayüzünü göster
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
