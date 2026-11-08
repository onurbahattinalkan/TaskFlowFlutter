import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../config/app_router.dart';
import '../providers/auth_provider.dart';
import '../services/api_exception.dart';
import '../utils/validators.dart';
import '../widgets/error_banner.dart';

// Giriş ekranı: e-posta + şifre
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Formun tamamını doğrulamak için anahtar
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  // İlk denemeden sonra her tuşta tekrar doğrula
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    // Controller'lar bellekte kalmasın
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Klavyeyi kapat
    FocusScope.of(context).unfocus();

    // Biçim hatası varsa istek hiç gönderilmez
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Başarılıysa AuthProvider durumu değiştirir; yönlendirme üst katmanda
      await context.read<AuthProvider>().login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } on ApiException catch (e) {
      // Sunucunun mesajı: "E-posta veya şifre hatalı." / kilit / bağlantı hatası
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } finally {
      // Başarılı girişte ekran kapanmış olabilir
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Giriş Yap')),
      body: SafeArea(
        child: Center(
          // Klavye açılınca taşmasın diye kaydırılabilir
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              // Tablette form ortada, en fazla 400 piksel
              constraints: const BoxConstraints(maxWidth: 400),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autovalidateMode,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.task_alt, size: 64, color: colors.primary),
                      const SizedBox(height: 8),
                      Text(
                        'TaskFlow Mobil',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hesabına giriş yap',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 32),

                      // Sunucu hatası varsa formun üstünde
                      if (_errorMessage != null) ...[
                        ErrorBanner(message: _errorMessage!),
                        const SizedBox(height: 16),
                      ],

                      TextFormField(
                        controller: _emailController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'E-posta',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        enabled: !_isLoading,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        // Klavyedeki "Tamam" ile de giriş yapılsın
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Şifreyi göster'
                                : 'Şifreyi gizle',
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: Validators.loginPassword,
                      ),
                      const SizedBox(height: 24),

                      // İstek sürerken pasif, içinde yükleniyor göstergesi
                      FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Giriş Yap'),
                      ),
                      // ↓↓↓ YENİ EKLENEN KISIM ↓↓↓
                      const SizedBox(height: 8),
                      TextButton(
                        // push: kayıt ekranında geri oku çıksın
                        onPressed: _isLoading
                            ? null
                            : () => context.push(AppRoutes.register),
                        child: const Text('Hesabın yok mu? Kayıt ol'),
                      ),
                      // ↑↑↑ YENİ EKLENEN KISIM ↑↑↑
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}