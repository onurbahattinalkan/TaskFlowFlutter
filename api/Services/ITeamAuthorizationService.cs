namespace TaskFlowApi.Services;

// Ekip içi yetki soruları: kullanıcı bu ekibin üyesi mi, lideri mi?
// Controller'lar bu sorguları kendisi yazmak yerine bu servise sorar.
public interface ITeamAuthorizationService
{
    // Kullanıcı ekibin üyesi mi? (Lider de üyedir; sistem Admin'i her ekipte üye sayılır)
    Task<bool> IsMemberAsync(string userId, int teamId);

    // Kullanıcı ekibin lideri mi? (sistem Admin'i her ekipte lider sayılır)
    Task<bool> IsLeaderAsync(string userId, int teamId);

    // Kullanıcının gerçekten üye olduğu ekiplerin Id'leri ("Ekiplerim" listesi için)
    Task<List<int>> GetMemberTeamIdsAsync(string userId);

    // Kullanıcı sistem Admin'i mi?
    Task<bool> IsAdminAsync(string userId);
}