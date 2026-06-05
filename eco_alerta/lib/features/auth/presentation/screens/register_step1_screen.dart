import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/eco_primary_button.dart';
import '../widgets/eco_text_field.dart';

class RegisterStep1Screen extends StatefulWidget {
  const RegisterStep1Screen({super.key});

  @override
  State<RegisterStep1Screen> createState() => _RegisterStep1ScreenState();
}

class _RegisterStep1ScreenState extends State<RegisterStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    context.push(
      '/register/step2',
      extra: {'email': _emailCtrl.text.trim(), 'password': _passCtrl.text},
    );
  }

  @override
  Widget build(BuildContext context) {
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
                          EcoTextField(
                            label: 'Contraseña',
                            placeholder: '••••••••',
                            prefixIcon: Icons.lock_outline,
                            controller: _passCtrl,
                            isPassword: true,
                            validator: (v) {
                              if (v == null || v.length < 6) return 'Mínimo 6 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          EcoTextField(
                            label: 'Confirmar contraseña',
                            placeholder: '••••••••',
                            prefixIcon: Icons.lock_outline,
                            controller: _confirmPassCtrl,
                            isPassword: true,
                            validator: (v) {
                              if (v != _passCtrl.text) return 'Las contraseñas no coinciden';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          EcoPrimaryButton(
                            label: 'Siguiente',
                            icon: Icons.arrow_forward,
                            onPressed: _next,
                          ),
                          const SizedBox(height: 24),
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: AppColors.onSurfaceVariant,
                              ),
                              children: [
                                const TextSpan(text: '¿Ya tienes una cuenta? '),
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () => context.go('/login'),
                                    child: Text(
                                      'Iniciar sesión',
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
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco, color: AppColors.onPrimaryContainer, size: 24),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Paso 1 de 2',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Crear cuenta',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
              letterSpacing: -0.32,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Registra tus credenciales de acceso.',
            style: GoogleFonts.inter(fontSize: 16, color: AppColors.onSurfaceVariant),
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
