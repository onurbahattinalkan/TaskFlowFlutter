import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../config/app_router.dart';
import '../models/project.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../widgets/error_banner.dart';

// Kart menüsündeki seçenekler
enum _ProjectAction { edit, delete }

// Projeler ekranı: liste, yeni proje, düzenleme ve onaylı silme
class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key, this.api});

  // Testte sahte servis verilebilsin diye dışarıdan alınabilir
  final ApiService? api;

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  static final _dateFormat = DateFormat('dd.MM.yyyy');

  late final ApiService _api;

  List<Project> _projects = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? ApiService();
    _loadProjects();
  }

  // Listeyi API'den çeker; aşağı çekip yenilemede de kullanılır
  Future<void> _loadProjects() async {
    try {
      final projects = await _api.getProjects();
      if (!mounted) return;
      setState(() {
        _projects = projects;
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

  void _retry() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _loadProjects();
  }

  // Formu açar (project null → yeni proje).
  // Form kaydedince mesaj döndürür; o zaman liste yenilenir.
  Future<void> _openForm({Project? project}) async {
    final location = project == null
        ? AppRoutes.projectNew
        : AppRoutes.projectEdit(project.id);

    // extra: proje nesnesi forma taşınır, tekrar API'ye gidilmez
    final message = await context.push<String>(location, extra: project);

    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    _loadProjects();
  }

  // Silmeden önce onay sorar; görevler de silineceği için uyarır
  Future<void> _confirmDelete(Project project) async {
    final colors = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('Projeyi sil'),
        content: Text(
          project.taskCount > 0
              ? '"${project.name}" projesi ve içindeki ${project.taskCount} '
                  'görev (yorumlarıyla birlikte) kalıcı olarak silinecek. '
                  'Emin misin?'
              : '"${project.name}" projesi kalıcı olarak silinecek. '
                  'Emin misin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: colors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _api.deleteProject(project.id);
      if (!mounted) return;
      // Listeyi baştan çekmeye gerek yok, silineni çıkar
      setState(() => _projects.removeWhere((p) => p.id == project.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${project.name}" silindi.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  // Tarih bilgisini kısa metne çevirir; hiç tarih yoksa null
  String? _dateRange(Project project) {
    final start = project.startDate;
    final end = project.endDate;

    if (start != null && end != null) {
      return '${_dateFormat.format(start)} – ${_dateFormat.format(end)}';
    }
    if (start != null) return 'Başlangıç: ${_dateFormat.format(start)}';
    if (end != null) return 'Bitiş: ${_dateFormat.format(end)}';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Projeler')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Proje'),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // İlk yüklemede hata: liste yerine hata + tekrar dene
    if (_errorMessage != null && _projects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ErrorBanner(message: _errorMessage!),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Tablette liste ortada, en fazla 600 piksel
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: RefreshIndicator(
          onRefresh: _loadProjects,
          child: ListView(
            // Liste kısa olsa da aşağı çekip yenilenebilsin
            physics: const AlwaysScrollableScrollPhysics(),
            // Alttaki boşluk: son kart "Yeni Proje" butonunun altında kalmasın
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              // Yenilemede hata olduysa eski liste kalır, üstte uyarı çıkar
              if (_errorMessage != null) ...[
                ErrorBanner(message: _errorMessage!),
                const SizedBox(height: 12),
              ],
              if (_projects.isEmpty)
                _buildEmpty()
              else
                ..._projects.map(_buildProjectCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(Icons.folder_off_outlined,
              size: 64, color: colors.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('Henüz proje yok', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Sağ alttaki "Yeni Proje" butonuyla ilk projeni ekleyebilirsin.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    final colors = Theme.of(context).colorScheme;
    final dates = _dateRange(project);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 4),
        leading: CircleAvatar(
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          child: const Icon(Icons.folder_outlined),
        ),
        title: Text(
          project.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Ekip • görev sayısı • tarihler
        subtitle: Text([
          project.teamName,
          '${project.taskCount} görev',
                    ?dates,
        ].join(' • ')),
        // 5. haftada dokununca Proje Detayı (Kanban) açılacak; şimdilik düzenleme
        onTap: () => _openForm(project: project),
        trailing: PopupMenuButton<_ProjectAction>(
          tooltip: 'Seçenekler',
          onSelected: (action) {
            switch (action) {
              case _ProjectAction.edit:
                _openForm(project: project);
              case _ProjectAction.delete:
                _confirmDelete(project);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: _ProjectAction.edit,
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Düzenle'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: _ProjectAction.delete,
              child: ListTile(
                leading: Icon(Icons.delete_outline),
                title: Text('Sil'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
