import 'package:flutter/material.dart';
import '../../auth/providers/routes_provider.dart';

/// Lógica pura del calendario de recojo: a partir de las rutas elegidas por el
/// usuario calcula los días de recojo, el próximo recojo y el estado actual.
///
/// El recojo siempre es a las 07:00 a. m. y el mensaje del día es "Sacar la basura".
class CollectionSchedule {
  CollectionSchedule._();

  /// Hora de recojo (07:00 a. m.).
  static const TimeOfDay pickupTime = TimeOfDay(hour: 7, minute: 0);

  /// Mensaje mostrado el día de recojo.
  static const String pickupLabel = 'Sacar la basura';

  /// Mapea un código de día en español (de `routes.json`) a `DateTime.weekday`
  /// (lunes = 1 … domingo = 7). Tolera acentos y mayúsculas.
  static int? weekdayFromCode(String code) {
    final c = code
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    const map = {
      'lun': DateTime.monday,
      'mar': DateTime.tuesday,
      'mie': DateTime.wednesday,
      'jue': DateTime.thursday,
      'vie': DateTime.friday,
      'sab': DateTime.saturday,
      'dom': DateTime.sunday,
    };
    return map[c.length >= 3 ? c.substring(0, 3) : c];
  }

  /// Conjunto de días de la semana (1–7) con recojo, según las rutas dadas.
  static Set<int> pickupWeekdays(List<CollectionRoute> routes) {
    final days = <int>{};
    for (final r in routes) {
      for (final code in r.schedule) {
        final wd = weekdayFromCode(code);
        if (wd != null) days.add(wd);
      }
    }
    return days;
  }

  /// `true` si [day] (a nivel de fecha) es día de recojo para las rutas.
  static bool isPickupDay(List<CollectionRoute> routes, DateTime day) =>
      pickupWeekdays(routes).contains(day.weekday);

  /// Devuelve el `DateTime` del próximo recojo (a las 07:00) a partir de [now],
  /// o `null` si las rutas no tienen días programados.
  static DateTime? nextPickup(List<CollectionRoute> routes, DateTime now) {
    final days = pickupWeekdays(routes);
    if (days.isEmpty) return null;
    for (var i = 0; i < 8; i++) {
      final d = DateTime(now.year, now.month, now.day).add(Duration(days: i));
      if (!days.contains(d.weekday)) continue;
      final pickup =
          DateTime(d.year, d.month, d.day, pickupTime.hour, pickupTime.minute);
      // El recojo de hoy ya pasó: seguir buscando el siguiente día programado.
      if (pickup.isAfter(now)) return pickup;
    }
    return null;
  }

  /// Los 7 días (lunes→domingo) de la semana que contiene [anchor].
  static List<DateTime> weekDays(DateTime anchor) {
    final monday = DateTime(anchor.year, anchor.month, anchor.day)
        .subtract(Duration(days: anchor.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  /// Estado del recojo respecto al día de recojo más cercano.
  static CollectionStatus statusFor(List<CollectionRoute> routes, DateTime now) {
    if (!isPickupDay(routes, now)) return CollectionStatus.notYet;
    final pickup =
        DateTime(now.year, now.month, now.day, pickupTime.hour, pickupTime.minute);
    final enRouteStart = pickup.subtract(const Duration(hours: 1)); // 06:00
    if (now.isBefore(enRouteStart)) return CollectionStatus.notYet;
    if (now.isBefore(pickup)) return CollectionStatus.enRoute;
    return CollectionStatus.done;
  }

  /// Minutos restantes hasta las 07:00 del día de recojo (para el ETA "En camino").
  static Duration etaTo(DateTime now) {
    final pickup =
        DateTime(now.year, now.month, now.day, pickupTime.hour, pickupTime.minute);
    final diff = pickup.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }
}

enum CollectionStatus { notYet, enRoute, done }

extension CollectionStatusX on CollectionStatus {
  String get label => switch (this) {
        CollectionStatus.notYet => 'Aún no es la fecha de recojo',
        CollectionStatus.enRoute => 'En camino',
        CollectionStatus.done => 'Finalizado',
      };

  IconData get icon => switch (this) {
        CollectionStatus.notYet => Icons.schedule,
        CollectionStatus.enRoute => Icons.local_shipping,
        CollectionStatus.done => Icons.check_circle,
      };
}
