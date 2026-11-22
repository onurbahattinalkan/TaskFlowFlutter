import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/team.dart';
import '../providers/auth_provider.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../widgets/add_member_dialog.dart';
import '../widgets/error_banner.dart';
import '../widgets/status_chip.dart';

// Ekip Detayı: ekip bilgileri, üyeler, üye ekleme, liderlik devri
class TeamDetailScreen extends StatefulWidget {
  final int teamId;

  const TeamDetailScreen({super.key, required this.teamId});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final _api = ApiService();

  TeamDetail? _team;
  bool _isLoading = true;
  // Liderlik devri gibi bir işlem sürerken butonlar pasif olsun
  bool _isBusy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  Future<void> _loadTeam({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final team = await _api.getTeam(widget.teamId);
      if (!mounted) return;
      setState(() {
        _team = team;
        _errorMessage = null;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      // 403 (üye değil) ve 404 (ekip yok) mesajları da buradan gösterilir
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addMember() async {
    final updated = await showDialog<TeamDetail>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddMemberDialog(teamId: widget.teamId),
    );

    if (updated == null || !mounted) return;
    // API güncel ekibi döndürdü; tekrar istek atmaya gerek yok
    setState(() => _team = updated);
    _showMessage('Üye eklendi.');
  }

  Future<void> _transferLeadership(TeamMember member) async {
    // Admin üyesi olmadığı ekipte devrediyorsa myRole null olur
    final isOutsider = _team?.myRole == null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Liderliği devret'),
        content: Text(isOutsider
            ? '${member.fullName} ekibin yeni lideri olacak, mevcut lider Üye olacak.'
            : '${member.fullName} ekibin yeni lideri olacak ve sen Üye olacaksın. '
                'Bunu yalnızca yeni lider geri alabilir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Devret'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    try {
      final updated =
          await _api.transferLeadership(widget.teamId, member.userId);
      if (!mounted) return;
      // Cevaptaki myRole değiştiği için yönetim butonları kendiliğinden gizlenir
      setState(() {
        _team = updated;
        _isBusy = false;
      });
      _showMessage('Liderlik ${member.fullName} kişisine devredildi.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      _showMessage(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final team = _team;
    final isAdmin = context.watch<AuthProvider>().user?.isAdmin ?? false;
    // Yönetim işlemleri: ekip lideri veya sistem Admin'i
    final canManage = team != null && (team.isLeader || isAdmin);

    return Scaffold(
      appBar: AppBar(title: Text(team?.name ?? 'Ekip Detayı')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _isBusy ? null : _addMember,
              icon: const Icon(Icons.person_add),
              label: const Text('Üye Ekle'),
            )
          : null,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _buildBody(context, canManage),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool canManage) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final team = _team;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (team == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ErrorBanner(message: _errorMessage ?? 'Ekip yüklenemedi.'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadTeam,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      );
    }

    final description = team.description;

    return RefreshIndicator(
      onRefresh: () => _loadTeam(showSpinner: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          if (_isBusy) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
          ],

          // Ekip bilgileri
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(team.name, style: textTheme.headlineSmall),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.people, size: 18),
                        label: Text('${team.memberCount} üye'),
                      ),
                      Chip(
                        avatar: const Icon(Icons.folder, size: 18),
                        label: Text('${team.projectCount} proje'),
                      ),
                      if (team.myRole != null)
                        Chip(
                          avatar: const Icon(Icons.badge, size: 18),
                          label: Text('Rolün: ${team.myRole}'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text('Üyeler (${team.members.length})', style: textTheme.titleMedium),
          const SizedBox(height: 8),

          // Üye listesi (API'den önce Lider, sonra ada göre sıralı gelir)
          ...team.members.map((member) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(member.fullName.isNotEmpty
                        ? member.fullName[0].toUpperCase()
                        : '?'),
                  ),
                  title: Text(member.fullName.isNotEmpty
                      ? member.fullName
                      : member.userName),
                  subtitle: Text(
                    '@${member.userName} • ${member.email}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: _memberTrailing(member, canManage, colors),
                ),
              )),
        ],
      ),
    );
  }

  // Liderin yanında rozet; yöneticiye diğer üyelerde işlem menüsü
  Widget? _memberTrailing(
      TeamMember member, bool canManage, ColorScheme colors) {
    if (member.isLeader) {
      return StatusChip(
        label: TeamRoles.leader,
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
      );
    }

    if (!canManage) return null;

    return PopupMenuButton<String>(
      tooltip: 'İşlemler',
      enabled: !_isBusy,
      onSelected: (_) => _transferLeadership(member),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'transfer',
          child: Text('Liderliği devret'),
        ),
      ],
    );
  }
}