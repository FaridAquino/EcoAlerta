import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../widgets/eco_primary_button.dart';
import '../widgets/eco_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authProvider.notifier)
        .login(_emailCtrl.text.trim(), _passCtrl.text);
    if (ok && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    ref.listen(authProvider, (_, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _DecorativeBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceVariant),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 30,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Header(),
                          const SizedBox(height: 32),
                          EcoTextField(
                            label: 'Correo electrónico',
                            placeholder: 'usuario@ejemplo.com',
                            prefixIcon: Icons.mail_outline,
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Ingresa tu correo';
                              if (!v.contains('@')) return 'Correo inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Contraseña',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {},
                                    child: Text(
                                      '¿Olvidaste tu contraseña?',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              EcoTextField(
                                label: '',
                                placeholder: '••••••••',
                                prefixIcon: Icons.lock_outline,
                                controller: _passCtrl,
                                isPassword: true,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                                  return null;
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          EcoPrimaryButton(
                            label: 'Entrar',
                            icon: Icons.login,
                            onPressed: _submit,
                            isLoading: isLoading,
                          ),
                          const SizedBox(height: 24),
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: AppColors.onSurfaceVariant,
                              ),
                              children: [
                                const TextSpan(text: '¿No tienes una cuenta? '),
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () => context.push('/register/step1'),
                                    child: Text(
                                      'Crear cuenta',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.eco, color: AppColors.onPrimaryContainer, size: 32),
        ),
        const SizedBox(height: 12),
        Text(
          'EcoAlerta',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
            letterSpacing: -0.01 * 32,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bienvenido de nuevo. Accede a tu cuenta\npara continuar cuidando el medio ambiente.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DecorativeBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -MediaQuery.of(context).size.height * 0.2,
            left: -MediaQuery.of(context).size.width * 0.1,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.5,
              height: MediaQuery.of(context).size.width * 0.5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1AB1F0CE),
              ),
            ),
          ),
          Positioned(
            bottom: -MediaQuery.of(context).size.height * 0.2,
            right: -MediaQuery.of(context).size.width * 0.1,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.width * 0.6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1ABFE8FF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
