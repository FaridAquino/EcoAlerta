import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/providers/current_user_provider.dart';
import '../../../schedule/domain/collection_schedule.dart';
import '../../data/notification_service.dart';
import '../../domain/notification_prefs.dart';
import '../../providers/alerts_providers.dart';

/// Configura y solicita permisos para las notificaciones locales y la alarma.
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(notificationPrefsProvider);
    final notifier = ref.read(notificationPrefsProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _banner(),
          const SizedBox(height: 20),
          _channels(prefs, notifier),
          const SizedBox(height: 20),
          _proximity(prefs, notifier),
          const SizedBox(height: 20),
          _tip(),
          const SizedBox(height: 24),
          _saveButton(prefs),
          const SizedBox(height: 12),
          _testButton(),
        ],
      ),
    );
  }

  Widget _testButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _saving ? null : _testAlarm,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.alarm),
        label: Text(
          'Probar alarma (10 s)',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _testAlarm() async {
    await NotificationService.instance.testAlarm(seconds: 10);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('La alarma sonará en 10 s. Bloquea o minimiza la app para probar.'),
        backgroundColor: AppColors.primaryContainer,
      ),
    );
  }

  Widget _banner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Mantente informado',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Personaliza cómo y cuándo recibir avisos del recojo de basura en tu zona.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _channels(NotificationPrefs prefs, NotificationPrefsNotifier notifier) {
    return _card(
      child: Column(
        children: [
          _toggleRow(
            icon: Icons.notifications,
            iconBg: AppColors.primaryFixedDim,
            iconColor: AppColors.primary,
            title: 'Notificaciones push',
            subtitle: 'Avisos en tiempo real en tu dispositivo',
            value: prefs.pushEnabled,
            onChanged: (v) => notifier.update(prefs.copyWith(pushEnabled: v)),
          ),
          const Divider(height: 24),
          _toggleRow(
            icon: Icons.volume_up,
            iconBg: AppColors.secondaryFixed,
            iconColor: AppColors.secondary,
            title: 'Sonido de notificación',
            subtitle: 'Reproducir un sonido en las alertas',
            value: prefs.soundEnabled,
            onChanged: (v) => notifier.update(prefs.copyWith(soundEnabled: v)),
          ),
        ],
      ),
    );
  }

  Widget _proximity(NotificationPrefs prefs, NotificationPrefsNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UMBRAL DE PROXIMIDAD',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.social_distance, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Alerta por distancia',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _distanceButton('2 cuadras', DistanceMode.blocks2, prefs, notifier),
                  const SizedBox(width: 8),
                  _distanceButton('500 metros', DistanceMode.meters500, prefs, notifier),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Buffer de precisión',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${prefs.precisionBuffer} min',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimaryFixed,
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: prefs.precisionBuffer.toDouble(),
                min: 2,
                max: 60,
                divisions: 58,
                activeColor: AppColors.primary,
                onChanged: (v) =>
                    notifier.update(prefs.copyWith(precisionBuffer: v.round())),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _distanceButton(
    String label,
    DistanceMode mode,
    NotificationPrefs prefs,
    NotificationPrefsNotifier notifier,
  ) {
    final isSel = prefs.distanceMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => notifier.update(prefs.copyWith(distanceMode: mode)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSel ? AppColors.primaryContainer : AppColors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSel ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSel ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _tip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tertiaryContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tertiaryContainer.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb, color: AppColors.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                children: const [
                  TextSpan(
                    text: 'Eco Tip: ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text:
                        'configurar la alerta 10 min antes te da tiempo de revisar que tu reciclaje esté bien separado.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveButton(NotificationPrefs prefs) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _saving ? null : () => _save(prefs),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
              )
            : const Icon(Icons.check_circle),
        label: Text(
          _saving ? 'Guardando...' : 'Guardar preferencias',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _save(NotificationPrefs prefs) async {
    setState(() => _saving = true);
    final svc = NotificationService.instance;
    try {
      await ref.read(notificationPrefsProvider.notifier).save(prefs);
      await svc.requestPermissions();

      final routes = await ref.read(userRoutesProvider.future);
      final next = CollectionSchedule.nextPickup(routes, DateTime.now());

      await svc.cancelAll();
      if (prefs.pushEnabled && next != null) {
        await svc.scheduleReminder(
          next,
          minutesBefore: prefs.minutesBefore,
          sound: prefs.soundEnabled,
        );
        await svc.scheduleAlarm(next, vibrate: true);
        await svc.startPersistentService();
      } else {
        await svc.stopPersistentService();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferencias guardadas y alertas programadas'),
            backgroundColor: AppColors.primaryContainer,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: child,
      );

  Widget _toggleRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
