import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/providers/current_user_provider.dart';
import '../../../auth/providers/routes_provider.dart';
import '../../domain/collection_schedule.dart';

/// Calendario semanal de recojo. Los días de recojo dependen de las rutas que
/// el usuario eligió (`schedule`); el recojo es a las 07:00 a. m.
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  late DateTime _selectedDay;
  late DateTime _weekAnchor;

  static const _dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  static const _monthNames = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _weekAnchor = _selectedDay;
  }

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(userRoutesProvider);
    return routesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (routes) => _content(routes),
    );
  }

  Widget _content(List<CollectionRoute> routes) {
    final now = DateTime.now();
    final next = CollectionSchedule.nextPickup(routes, now);
    final pickupDays = CollectionSchedule.pickupWeekdays(routes);
    final week = CollectionSchedule.weekDays(_weekAnchor);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heroNextCollection(routes, next, now),
          const SizedBox(height: 24),
          _weeklyCalendar(week, pickupDays),
          const SizedBox(height: 24),
          _dayDetail(routes),
        ],
      ),
    );
  }

  Widget _heroNextCollection(
    List<CollectionRoute> routes,
    DateTime? next,
    DateTime now,
  ) {
    final routeNames = routes.isEmpty
        ? 'Sin rutas seleccionadas'
        : routes.map((r) => r.name).join(' · ');
    final countdown = next == null ? '—' : _countdownText(next.difference(now));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRÓXIMO RECOJO',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: AppColors.onPrimaryContainer.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      routeNames,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.schedule, color: AppColors.onPrimaryContainer, size: 20),
                    const SizedBox(height: 2),
                    Text(
                      next == null ? '—' : _whenLabel(next, now),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                countdown,
                style: GoogleFonts.inter(
                  fontSize: 34,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'a las 07:00 a. m.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onPrimaryContainer.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weeklyCalendar(List<DateTime> week, Set<int> pickupDays) {
    final today = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 20, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calendario semanal',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(
                      () => _weekAnchor = _weekAnchor.subtract(const Duration(days: 7)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(
                      () => _weekAnchor = _weekAnchor.add(const Duration(days: 7)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final l in _dayLabels)
                Expanded(
                  child: Center(
                    child: Text(
                      l,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final day in week)
                Expanded(
                  child: _dayCell(
                    day,
                    isPickup: pickupDays.contains(day.weekday),
                    isToday: _sameDate(day, today),
                    isSelected: _sameDate(day, _selectedDay),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayCell(
    DateTime day, {
    required bool isPickup,
    required bool isToday,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedDay = day),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer.withValues(alpha: 0.15)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isToday ? AppColors.primaryFixed : Colors.transparent),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              '${day.day}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isToday || isSelected ? AppColors.primary : AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPickup ? AppColors.primary : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayDetail(List<CollectionRoute> routes) {
    final isPickup = CollectionSchedule.isPickupDay(routes, _selectedDay);
    final dateLabel =
        '${_selectedDay.day} ${_monthNames[_selectedDay.month - 1]} ${_selectedDay.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recojo del $dateLabel',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (isPickup)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.tertiary.withValues(alpha: 0.12),
                    ),
                    child: const Icon(Icons.delete_outline, color: AppColors.tertiary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CollectionSchedule.pickupLabel,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          'Recolección de residuos en tu zona',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '07:00 a. m.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onPrimaryFixed,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No hay recojo programado este día.',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  String _whenLabel(DateTime next, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(next.year, next.month, next.day);
    final diff = d.difference(today).inDays;
    if (diff <= 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    return 'En $diff d';
  }

  String _countdownText(Duration d) {
    if (d.isNegative) return 'Ahora';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
