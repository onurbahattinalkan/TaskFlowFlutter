using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Identity;

namespace TaskFlowApi.Models;

// Identity'nin hazır kullanıcı sınıfını genişletiyoruz.
// Id, UserName, Email, PasswordHash, kilit bilgileri IdentityUser'dan gelir.
public class ApplicationUser : IdentityUser
{
    // Kullanıcının adı soyadı (AspNetUsers tablosuna ek sütun olarak eklenir)
    [Required(ErrorMessage = "Ad soyad zorunludur.")]
    [StringLength(100, ErrorMessage = "Ad soyad en fazla 100 karakter olabilir.")]
    public string FullName { get; set; } = string.Empty;

    // Kullanıcının üye olduğu ekipler (TeamMembers üzerinden)
    public ICollection<TeamMember> TeamMemberships { get; set; } = new List<TeamMember>();

    // Kullanıcıya atanmış görevler
    public ICollection<TaskItem> AssignedTasks { get; set; } = new List<TaskItem>();

    // Kullanıcının yazdığı yorumlar
    public ICollection<Comment> Comments { get; set; } = new List<Comment>();
}