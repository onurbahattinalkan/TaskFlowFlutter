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



// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
