import 'package:flutter/material.dart';

import '../models/team.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import 'error_banner.dart';

// "Yeni Ekip" formu. Başarılı olursa oluşturulan ekibi döndürerek kapanır.
class CreateTeamDialog extends StatefulWidget {
  const CreateTeamDialog({super.key});

  @override
  State<CreateTeamDialog> createState() => _CreateTeamDialogState();
}

class _CreateTeamDialogState extends State<CreateTeamDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    // Controller'lar bellekte kalmasın
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Kurallar API'deki TeamCreateDto ile aynı
  String? _validateName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ekip adı zorunludur.';
    if (text.length > 100) return 'Ekip adı en fazla 100 karakter olabilir.';
    return null;
  }

  String? _validateDescription(String? value) {
    if ((value?.trim().length ?? 0) > 500) {
      return 'Açıklama en fazla 500 karakter olabilir.';
    }
    return null;
  }

  Future<void> _submit() async {
    // Önce mobil tarafta doğrula; hatalıysa API'ye gitme
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final description = _descriptionController.text.trim();
      final team = await _api.createTeam(
        name: _nameController.text.trim(),
        // Boş açıklama null gönderilir
        description: description.isEmpty ? null : description,
      );

      if (!mounted) return;
      // Dialog'u kapat ve oluşturulan ekibi listeye döndür
      Navigator.of(context).pop<TeamDetail>(team);
    } on ApiException catch (e) {
      if (!mounted) return;
      // Sunucu hatası dialog içinde gösterilir; dialog kapanmaz
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Ekip'),
      // Klavye açılınca taşmasın diye kaydırılabilir
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMessage != null) ...[
                ErrorBanner(message: _errorMessage!),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _nameController,
                enabled: !_isLoading,
                autofocus: true,
                maxLength: 100,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Ekip adı'),
                validator: _validateName,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                enabled: !_isLoading,
                maxLength: 500,
                minLines: 1,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'Açıklama (isteğe bağlı)'),
                validator: _validateDescription,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Oluştur'),
        ),
      ],
    );
  }
}