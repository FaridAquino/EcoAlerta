import 'package:alarm/alarm.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Centraliza notificaciones locales (recordatorios), la alarma que suena y
/// vibra en segundo plano (`alarm`) y el servicio en primer plano persistente
/// (`flutter_foreground_task`). Configurado solo para Android por ahora.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

  static const _reminderChannelId = 'eco_reminders';
  static const _foregroundChannelId = 'eco_foreground';
  static const _reminderId = 1001;
  static const _arrivalId = 1002;
  static const _alarmId = 42;
  static const _alarmAsset = 'assets/audio/alarm.wav';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    // Zona horaria por defecto del proyecto (rutas en Junín, Perú).
    tz.setLocalLocation(tz.getLocation('America/Lima'));

    await _fln.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    final android = _fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _reminderChannelId,
        'Recordatorios de recojo',
        description: 'Avisos previos al recojo de basura',
        importance: Importance.max,
      ),
    );

    await Alarm.init();

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _foregroundChannelId,
        channelName: 'Servicio EcoAlerta',
        channelDescription: 'Mantiene EcoAlerta activa para avisarte del recojo',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
      ),
    );

    _initialized = true;
  }

  /// Solicita los permisos necesarios (notificaciones y alarmas exactas).
  Future<void> requestPermissions() async {
    final android = _fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    try {
      await FlutterForegroundTask.requestNotificationPermission();
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    } catch (_) {}
  }

  /// Programa el recordatorio [minutesBefore] minutos antes de [pickup].
  Future<void> scheduleReminder(
    DateTime pickup, {
    required int minutesBefore,
    required bool sound,
  }) async {
    final when = pickup.subtract(Duration(minutes: minutesBefore));
    if (when.isBefore(DateTime.now())) return;
    await _fln.zonedSchedule(
      id: _reminderId,
      title: 'Recojo de basura próximo',
      body: 'En $minutesBefore min pasa el camión. ¡Prepárate para sacar la basura!',
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannelId,
          'Recordatorios de recojo',
          channelDescription: 'Avisos previos al recojo de basura',
          importance: Importance.max,
          priority: Priority.high,
          playSound: sound,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Programa la alarma (suena y vibra aun en segundo plano) a la hora de [pickup].
  Future<void> scheduleAlarm(
    DateTime pickup, {
    required bool vibrate,
  }) async {
    if (pickup.isBefore(DateTime.now())) return;
    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: _alarmId,
        dateTime: pickup,
        assetAudioPath: _alarmAsset,
        loopAudio: true,
        vibrate: vibrate,
        androidFullScreenIntent: true,
        volumeSettings: VolumeSettings.fixed(volume: 1, volumeEnforced: true),
        notificationSettings: const NotificationSettings(
          title: 'EcoAlerta — ¡Sacar la basura!',
          body: 'El camión de recolección está llegando a tu zona.',
          stopButton: 'Detener',
        ),
      ),
    );
  }

  /// Notificación inmediata cuando el camión "llega" (switch Notificarme al llegar).
  Future<void> showArrivalNotification() async {
    await _fln.show(
      id: _arrivalId,
      title: 'El camión está llegando',
      body: 'Saca la basura ahora, el recojo es en tu zona.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannelId,
          'Recordatorios de recojo',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Inicia el servicio en primer plano persistente (best-effort).
  Future<void> startPersistentService() async {
    try {
      if (await FlutterForegroundTask.isRunningService) return;
      await FlutterForegroundTask.startService(
        serviceTypes: [ForegroundServiceTypes.dataSync],
        notificationTitle: 'EcoAlerta activa',
        notificationText: 'Vigilando tu próximo recojo de basura.',
      );
    } catch (_) {}
  }

  Future<void> stopPersistentService() async {
    try {
      await FlutterForegroundTask.stopService();
    } catch (_) {}
  }

  /// Dispara una alarma de prueba dentro de [seconds] segundos (para verificar
  /// sonido/vibración en segundo plano). Pide permisos antes.
  Future<void> testAlarm({int seconds = 10}) async {
    await requestPermissions();
    await scheduleAlarm(
      DateTime.now().add(Duration(seconds: seconds)),
      vibrate: true,
    );
    await startPersistentService();
  }

  Future<void> cancelAll() async {
    await _fln.cancelAll();
    await Alarm.stop(_alarmId);
  }
}
