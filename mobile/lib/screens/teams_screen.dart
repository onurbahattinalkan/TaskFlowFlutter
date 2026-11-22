import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/team.dart';
import '../providers/auth_provider.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../widgets/create_team_dialog.dart';
import '../widgets/error_banner.dart';
import '../widgets/status_chip.dart';

// "Ekiplerim" ekranı: kullanıcının ekipleri (Admin için tüm ekipler)
class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final _api = ApiService();

  // Ekranın durumu: yükleniyor / hata / liste
  List<Team> _teams = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  // showSpinner: ilk açılışta tam ekran yükleniyor göstergesi;
  // aşağı çekip yenilemede liste yerinde kalsın diye false
  Future<void> _loadTeams({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final teams = await _api.getTeams();
      if (!mounted) return;
      setState(() {
        _teams = teams;
        _errorMessage = null;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  // Dialog'u açar; ekip oluşturulduysa bilgi verip listeyi yeniler
  Future<void> _createTeam() async {
    final created = await showDialog<TeamDetail>(
      context: context,
      // Kayıt sürerken dışarı dokununca kapanmasın
      barrierDismissible: false,
      builder: (_) => const CreateTeamDialog(),
    );

    // Vazgeç'e basıldıysa null döner
    if (created == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${created.name}" ekibi oluşturuldu.')),
    );
    await _loadTeams(showSpinner: false);
  }

  // Kullanıcının bu ekipteki rolüne göre rozet
  Widget? _roleChip(Team team, bool isAdmin, ColorScheme colors) {
    if (team.isLeader) {
      return StatusChip(
        label: TeamRoles.leader,
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
      );
    }
    if (team.myRole == TeamRoles.member) {
      return StatusChip(
        label: TeamRoles.member,
        backgroundColor: colors.surfaceContainerHighest,
        foregroundColor: colors.onSurfaceVariant,
      );
    }
    // Üyesi olmadığı ekibi gören kişi sadece Admin olabilir
    if (isAdmin) {
      return StatusChip(
        label: 'Admin',
        backgroundColor: colors.tertiaryContainer,
        foregroundColor: colors.onTertiaryContainer,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ekiplerim')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _createTeam,
        icon: const Icon(Icons.group_add),
        label: const Text('Yeni Ekip'),
      ),
      body: SafeArea(
        // Tablette içerik ortada, en fazla 600 piksel genişlikte
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _buildBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 1) Yükleniyor
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2) Hata (ve gösterilecek liste yok)
    if (_errorMessage != null && _teams.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ErrorBanner(message: _errorMessage!),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadTeams,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      );
    }

    final isAdmin = context.watch<AuthProvider>().user?.isAdmin ?? false;

    // Aşağı çekince yenile (boş durumda da çalışsın diye her zaman ListView)
    return RefreshIndicator(
      onRefresh: () => _loadTeams(showSpinner: false),
      child: _teams.isEmpty
          // 3) Boş
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(32),
              children: [
                const SizedBox(height: 48),
                Icon(Icons.groups_outlined, size: 64, color: colors.outline),
                const SizedBox(height: 16),
                Text(
                  'Henüz bir ekibin yok',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '"Yeni Ekip" ile bir ekip kurabilir ya da bir ekip liderinin seni eklemesini bekleyebilirsin.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            )
          // 4) Liste
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              // Altta boşluk: son kart FAB'ın altında kalmasın
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: _teams.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final team = _teams[index];
                final description = team.description;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(team.name.isNotEmpty
                          ? team.name[0].toUpperCase()
                          : '?'),
                    ),
                    title: Text(team.name),
                    subtitle: Text(
                      description == null || description.isEmpty
                          ? '${team.memberCount} üye'
                          : '${team.memberCount} üye • $description',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: _roleChip(team, isAdmin, colors),
                    // Ekip Detayı'na geçiş 6. adımda eklenecek
                  ),
                );
              },
            ),
    );
  }
}