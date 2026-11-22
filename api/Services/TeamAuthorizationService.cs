using Microsoft.EntityFrameworkCore;
using TaskFlowApi.Data;
using TaskFlowApi.Models;

namespace TaskFlowApi.Services;

public class TeamAuthorizationService : ITeamAuthorizationService
{
    private readonly AppDbContext _context;

    public TeamAuthorizationService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<bool> IsMemberAsync(string userId, int teamId)
    {
        // Admin her ekibi görebilir
        if (await IsAdminAsync(userId)) return true;

        // TeamMembers tablosunda bu kullanıcı–ekip satırı var mı?
        return await _context.TeamMembers
            .AnyAsync(tm => tm.TeamId == teamId && tm.UserId == userId);
    }

    public async Task<bool> IsLeaderAsync(string userId, int teamId)
    {
        // Admin her ekipte lider yetkisine sahip
        if (await IsAdminAsync(userId)) return true;

        // Satır var mı ve ekip içi rolü "Lider" mi?
        return await _context.TeamMembers
            .AnyAsync(tm => tm.TeamId == teamId
                         && tm.UserId == userId
                         && tm.TeamRole == TeamRoles.Leader);
    }

    public Task<List<int>> GetMemberTeamIdsAsync(string userId)
    {
        // Sadece Id'ler çekilir; ekip bilgileri controller'da ayrıca sorgulanır
        return _context.TeamMembers
            .Where(tm => tm.UserId == userId)
            .Select(tm => tm.TeamId)
            .ToListAsync();
    }

    public Task<bool> IsAdminAsync(string userId)
    {
        // AspNetUserRoles (kullanıcı–rol eşleşmesi) + AspNetRoles (rol adı).
        // EF Core bunu tek bir EXISTS sorgusuna çevirir.
        return _context.UserRoles.AnyAsync(ur =>
            ur.UserId == userId &&
            _context.Roles.Any(r => r.Id == ur.RoleId && r.Name == AppRoles.Admin));
    }
}