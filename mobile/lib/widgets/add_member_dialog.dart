import 'package:flutter/material.dart';

import '../models/team.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import 'error_banner.dart';

// "Üye Ekle" formu. Başarılı olursa güncel ekip detayını döndürerek kapanır.
class AddMemberDialog extends StatefulWidget {
  final int teamId;

  const AddMemberDialog({super.key, required this.teamId});

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Kurallar API'deki AddMemberDto ile aynı
  String? _validate(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Kullanıcı adı veya e-posta zorunludur.';
    if (text.length > 256) {
      return 'Kullanıcı adı veya e-posta en fazla 256 karakter olabilir.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final team =
          await _api.addTeamMember(widget.teamId, _controller.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop<TeamDetail>(team);
    } on ApiException catch (e) {
      if (!mounted) return;
      // "Kullanıcı bulunamadı", "zaten üye" gibi API mesajları burada görünür
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Üye Ekle'),
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
                controller: _controller,
                enabled: !_isLoading,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Kullanıcı adı veya e-posta',
                  hintText: 'ör. testb veya testb@taskflow.com',
                ),
                validator: _validate,
                onFieldSubmitted: (_) => _submit(),
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
              : const Text('Ekle'),
        ),
      ],
    );
  }
}