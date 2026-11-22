import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/project.dart';
import '../models/team.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../utils/project_validators.dart';
import '../widgets/error_banner.dart';

// Proje ekleme ve düzenleme formu: tek ekran, iki mod.
// projectId null → yeni proje, dolu → düzenleme.
class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({
    super.key,
    this.projectId,
    this.initialProject,
    this.api,
  });

  // Düzenlenecek projenin Id'si (yeni projede null)
  final int? projectId;

  // Listeden gelen proje; gelmezse Id ile API'den çekilir
  final Project? initialProject;

  // Testte sahte servis verilebilsin diye dışarıdan alınabilir
  final ApiService? api;

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  // Ekranda gösterilen tarih biçimi (API'ye "yyyy-MM-dd" gider)
  static final _dateFormat = DateFormat('dd.MM.yyyy');

  final _formKey = GlobalKey<FormState>();

  // Bitiş alanını tek başına doğrulayabilmek için (tarih seçilince)
  final _endFieldKey = GlobalKey<FormFieldState<String>>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();

  late final ApiService _api;

  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedTeamId;

  // Yeni projede seçilebilecek ekipler
  List<Team> _teams = [];

  // Düzenlemede ekip değiştirilemez, sadece adı gösterilir
  String _teamName = '';

  bool _isLoadingData = true; // ekipler veya proje yükleniyor
  String? _loadError; // yükleme hatası (tekrar dene butonu çıkar)
  bool _isSaving = false;
  String? _errorMessage; // kaydetme sırasında API'den gelen hata

  // İlk denemeden sonra her değişiklikte tekrar doğrula
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  bool get _isEdit => widget.projectId != null;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? ApiService();

    // Listeden proje geldiyse beklemeden formu doldur
    if (_isEdit && widget.initialProject != null) {
      _fillForm(widget.initialProject!);
      _isLoadingData = false;
    } else {
      _loadData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  // Yeni projede ekip listesini, düzenlemede projenin kendisini yükler
  Future<void> _loadData() async {
    try {
      if (_isEdit) {
        final project = await _api.getProject(widget.projectId!);
        _fillForm(project);
      } else {
        final teams = await _loadTeams();
        _teams = teams;
        // Tek ekip varsa seçili gelsin
        if (teams.length == 1) _selectedTeamId = teams.first.id;
      }
      _loadError = null;
    } on ApiException catch (e) {
      _loadError = e.message;
    }

    if (!mounted) return;
    setState(() => _isLoadingData = false);
  }

  void _retryLoad() {
    setState(() {
      _isLoadingData = true;
      _loadError = null;
    });
    _loadData();
  }

  // GEÇİCİ: Ekip listesini Zeynep'in GET /api/teams uç noktası sağlayacak.
  // Birleştirmeden sonra gövde sadece şu olacak:  return _api.getTeams();
    // Kullanıcının ekipleri (GET /api/teams); Admin için tüm ekipler
  Future<List<Team>> _loadTeams() {
    return _api.getTeams();
  }

  // Düzenlemede mevcut değerleri forma yazar
  void _fillForm(Project project) {
    _nameController.text = project.name;
    _descriptionController.text = project.description ?? '';
    _startDate = project.startDate;
    _endDate = project.endDate;
    _startController.text = _formatDate(project.startDate);
    _endController.text = _formatDate(project.endDate);
    _selectedTeamId = project.teamId;
    _teamName = project.teamName;
  }

  String _formatDate(DateTime? date) =>
      date == null ? '' : _dateFormat.format(date);

  // Takvimi açar, seçilen tarihi ilgili alana yazar
  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? _startDate : _endDate;

    // Bitiş seçilirken takvim başlangıç tarihinden açılsın
    final initial = current ?? (isStart ? null : _startDate) ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: isStart ? 'Başlangıç tarihi' : 'Bitiş tarihi',
      cancelText: 'Vazgeç',
      confirmText: 'Seç',
    );

    // Vazgeçildiyse veya ekran kapandıysa bir şey yapma
    if (picked == null || !mounted) return;
    _setDate(isStart: isStart, date: picked);
  }

  // Tarihi değiştirir (null = temizle) ve bitiş alanını hemen doğrular
  void _setDate({required bool isStart, DateTime? date}) {
    setState(() {
      if (isStart) {
        _startDate = date;
        _startController.text = _formatDate(date);
      } else {
        _endDate = date;
        _endController.text = _formatDate(date);
      }
    });

    // Hangi tarih değişirse değişsin kural bitiş alanında gösterilir
    _endFieldKey.currentState?.validate();
  }

  Future<void> _submit() async {
    // Klavyeyi kapat
    FocusScope.of(context).unfocus();

    // Hata varsa istek hiç gönderilmez
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final descriptionText = _descriptionController.text.trim();
    // Boş açıklama null gider
    final description = descriptionText.isEmpty ? null : descriptionText;

    try {
      if (_isEdit) {
        // PUT: ekip gönderilmez, API ekibi değiştirmiyor
        await _api.updateProject(
          widget.projectId!,
          name: name,
          description: description,
          startDate: _startDate,
          endDate: _endDate,
        );
      } else {
        await _api.createProject(
          name: name,
          description: description,
          startDate: _startDate,
          endDate: _endDate,
          teamId: _selectedTeamId!,
        );
      }

      if (!mounted) return;
      // Listeye mesaj döner; liste kendini yeniler ve SnackBar gösterir
      context.pop(_isEdit ? 'Proje güncellendi.' : 'Proje eklendi.');
    } on ApiException catch (e) {
      // API doğrulama hatası (400) veya bağlantı hatası
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Projeyi Düzenle' : 'Yeni Proje')),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ErrorBanner(message: _loadError!),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _retryLoad,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Kullanıcının hiç ekibi yoksa proje eklenemez
    final noTeams = !_isEdit && _teams.isEmpty;

    return Center(
      // Klavye açılınca taşmasın diye kaydırılabilir
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          // Tablette form ortada, en fazla 480 piksel
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sunucu hatası varsa formun üstünde
                if (_errorMessage != null) ...[
                  ErrorBanner(message: _errorMessage!),
                  const SizedBox(height: 16),
                ],

                _buildTeamField(noTeams),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  enabled: !_isSaving,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Proje adı',
                    prefixIcon: Icon(Icons.folder_outlined),
                  ),
                  validator: ProjectValidators.name,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  enabled: !_isSaving,
                  minLines: 3,
                  maxLines: 6,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama (isteğe bağlı)',
                    alignLabelWithHint: true,
                  ),
                  validator: ProjectValidators.description,
                ),
                const SizedBox(height: 16),

                _buildDateField(isStart: true),
                const SizedBox(height: 16),
                _buildDateField(isStart: false),
                const SizedBox(height: 24),

                // İstek sürerken veya ekip yokken pasif
                FilledButton(
                  onPressed: _isSaving || noTeams ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Kaydet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamField(bool noTeams) {
    // Düzenlemede ekip sadece gösterilir (API'de de TeamId güncellenmiyor)
    if (_isEdit) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Ekip',
          prefixIcon: Icon(Icons.groups_outlined),
          helperText: 'Projenin ekibi sonradan değiştirilemez.',
        ),
        child: Text(_teamName),
      );
    }

    if (noTeams) {
      return const ErrorBanner(
        message: 'Proje eklemek için önce bir ekibe üye olmalısın.',
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _selectedTeamId,
      decoration: const InputDecoration(
        labelText: 'Ekip',
        prefixIcon: Icon(Icons.groups_outlined),
      ),
      items: _teams
          .map((team) => DropdownMenuItem(
                value: team.id,
                child: Text(team.name),
              ))
          .toList(),
      onChanged: _isSaving
          ? null
          : (value) => setState(() => _selectedTeamId = value),
      validator: ProjectValidators.team,
    );
  }

  // Tarih alanı: klavye açılmaz, dokununca takvim açılır
  Widget _buildDateField({required bool isStart}) {
    final date = isStart ? _startDate : _endDate;

    return TextFormField(
      key: isStart ? null : _endFieldKey,
      controller: isStart ? _startController : _endController,
      readOnly: true,
      enabled: !_isSaving,
      onTap: () => _pickDate(isStart: isStart),
      decoration: InputDecoration(
        labelText: isStart ? 'Başlangıç tarihi' : 'Bitiş tarihi',
        hintText: 'Seçilmedi',
        prefixIcon: const Icon(Icons.event_outlined),
        // Tarih seçiliyse temizleme butonu (tarihler isteğe bağlı)
        suffixIcon: date == null
            ? null
            : IconButton(
                tooltip: 'Tarihi temizle',
                icon: const Icon(Icons.clear),
                onPressed: () => _setDate(isStart: isStart, date: null),
              ),
      ),
      // Tarih kuralı iki alanı birlikte kontrol eder, hata bitiş alanında
      validator: isStart
          ? null
          : (_) => ProjectValidators.dateRange(_startDate, _endDate),
    );
  }
}
