using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using TaskFlowApi.Models;

namespace TaskFlowApi.Data;

// IdentityDbContext: Identity tablolarını (AspNetUsers, AspNetRoles...) otomatik ekler
// <ApplicationUser>: kullanıcı tablosu için kendi genişlettiğimiz sınıfı kullan
public class AppDbContext : IdentityDbContext<ApplicationUser>
{
    // Ayarlar (bağlantı dizesi vb.) dışarıdan, Program.cs'teki kayıttan gelir
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    // Her DbSet bir tabloyu temsil eder
    public DbSet<Team> Teams => Set<Team>();
    public DbSet<TeamMember> TeamMembers => Set<TeamMember>();
    public DbSet<Project> Projects => Set<Project>();
    public DbSet<TaskItem> Tasks => Set<TaskItem>();
    public DbSet<Comment> Comments => Set<Comment>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        // Identity tablolarının ayarları için önce base çağrılmalı
        base.OnModelCreating(builder);

        // ---------- TeamMember ----------
        builder.Entity<TeamMember>(entity =>
        {
            // Aynı kullanıcı aynı ekibe iki kez eklenemez
            entity.HasIndex(tm => new { tm.TeamId, tm.UserId }).IsUnique();

            // Ekip silinince üyelikleri de silinir
            entity.HasOne(tm => tm.Team)
                  .WithMany(t => t.Members)
                  .HasForeignKey(tm => tm.TeamId)
                  .OnDelete(DeleteBehavior.Cascade);

            // Kullanıcı silinince üyelikleri de silinir
            entity.HasOne(tm => tm.User)
                  .WithMany(u => u.TeamMemberships)
                  .HasForeignKey(tm => tm.UserId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        // ---------- Project ----------
        builder.Entity<Project>(entity =>
        {
            // Ekip silinince projeleri de silinir
            entity.HasOne(p => p.Team)
                  .WithMany(t => t.Projects)
                  .HasForeignKey(p => p.TeamId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        // ---------- TaskItem ----------
        builder.Entity<TaskItem>(entity =>
        {
            // Proje silinince görevleri de silinir
            entity.HasOne(t => t.Project)
                  .WithMany(p => p.Tasks)
                  .HasForeignKey(t => t.ProjectId)
                  .OnDelete(DeleteBehavior.Cascade);

            // Atanan kullanıcı silinirse görev kalır, AssignedUserId null olur
            entity.HasOne(t => t.AssignedUser)
                  .WithMany(u => u.AssignedTasks)
                  .HasForeignKey(t => t.AssignedUserId)
                  .OnDelete(DeleteBehavior.SetNull);
        });

        // ---------- Comment ----------
        builder.Entity<Comment>(entity =>
        {
            // Görev silinince yorumları da silinir
            entity.HasOne(c => c.TaskItem)
                  .WithMany(t => t.Comments)
                  .HasForeignKey(c => c.TaskItemId)
                  .OnDelete(DeleteBehavior.Cascade);

            // Yorumu olan kullanıcı silinemez (yorum geçmişi korunur)
            entity.HasOne(c => c.User)
                  .WithMany(u => u.Comments)
                  .HasForeignKey(c => c.UserId)
                  .OnDelete(DeleteBehavior.Restrict);
        });
    }
}