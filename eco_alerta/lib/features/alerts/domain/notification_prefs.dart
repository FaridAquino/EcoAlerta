/// Preferencias de notificación configurables en la pantalla de Alertas.
enum DistanceMode { blocks2, meters500 }

class NotificationPrefs {
  final bool pushEnabled;
  final bool soundEnabled;

  /// Minutos de antelación para el recordatorio (5/10/15/30).
  final int minutesBefore;
  final DistanceMode distanceMode;

  /// Buffer de precisión en minutos (slider 2–60).
  final int precisionBuffer;

  /// "Notificarme al llegar" (switch de la pantalla Track).
  final bool notifyOnArrival;

  const NotificationPrefs({
    this.pushEnabled = true,
    this.soundEnabled = true,
    this.minutesBefore = 10,
    this.distanceMode = DistanceMode.blocks2,
    this.precisionBuffer = 10,
    this.notifyOnArrival = true,
  });

  NotificationPrefs copyWith({
    bool? pushEnabled,
    bool? soundEnabled,
    int? minutesBefore,
    DistanceMode? distanceMode,
    int? precisionBuffer,
    bool? notifyOnArrival,
  }) =>
      NotificationPrefs(
        pushEnabled: pushEnabled ?? this.pushEnabled,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        minutesBefore: minutesBefore ?? this.minutesBefore,
        distanceMode: distanceMode ?? this.distanceMode,
        precisionBuffer: precisionBuffer ?? this.precisionBuffer,
        notifyOnArrival: notifyOnArrival ?? this.notifyOnArrival,
      );

  Map<String, dynamic> toJson() => {
        'pushEnabled': pushEnabled,
        'soundEnabled': soundEnabled,
        'minutesBefore': minutesBefore,
        'distanceMode': distanceMode.name,
        'precisionBuffer': precisionBuffer,
        'notifyOnArrival': notifyOnArrival,
      };

  factory NotificationPrefs.fromJson(Map<String, dynamic> j) => NotificationPrefs(
        pushEnabled: j['pushEnabled'] as bool? ?? true,
        soundEnabled: j['soundEnabled'] as bool? ?? true,
        minutesBefore: j['minutesBefore'] as int? ?? 10,
        distanceMode: DistanceMode.values.firstWhere(
          (e) => e.name == j['distanceMode'],
          orElse: () => DistanceMode.blocks2,
        ),
        precisionBuffer: j['precisionBuffer'] as int? ?? 10,
        notifyOnArrival: j['notifyOnArrival'] as bool? ?? true,
      );
}
