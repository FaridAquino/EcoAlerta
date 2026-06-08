import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../alerts/data/notification_service.dart';
import '../../../alerts/providers/alerts_providers.dart';
import '../../../auth/providers/current_user_provider.dart';
import '../../../schedule/domain/collection_schedule.dart';

/// Mapa de seguimiento. Muestra el estado del recojo derivado del calendario
/// (Aún no / En camino / Finalizado) y el switch "Notificarme al llegar".
class TrackScreen extends ConsumerStatefulWidget {
  const TrackScreen({super.key});

  @override
  ConsumerState<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends ConsumerState<TrackScreen> {
  final _mapController = MapController();
  LatLng? _userPosition;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && mounted) {
        setState(() => _userPosition = LatLng(last.latitude, last.longitude));
        _mapController.move(_userPosition!, 15);
      }
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() => _userPosition = LatLng(pos.latitude, pos.longitude));
      _mapController.move(_userPosition!, 15);
    } catch (_) {}
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Camión simulado: ligeramente desplazado respecto al usuario / ruta.
  LatLng? _truckPosition(List routes) {
    if (_userPosition != null) {
      return LatLng(_userPosition!.latitude + 0.0018, _userPosition!.longitude + 0.0016);
    }
    if (routes.isNotEmpty && routes.first.nodes.isNotEmpty) {
      final n = routes.first.nodes.first;
      return LatLng(n.lat + 0.0018, n.lng + 0.0016);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final routes = ref.watch(userRoutesProvider).valueOrNull ?? const [];
    final status = CollectionSchedule.statusFor(routes, DateTime.now());
    final center = _userPosition ??
        (routes.isNotEmpty && routes.first.nodes.isNotEmpty
            ? LatLng(routes.first.nodes.first.lat, routes.first.nodes.first.lng)
            : const LatLng(-11.4194, -75.6977));
    final truck = _truckPosition(routes);

    return Stack(
      children: [
        Positioned.fill(child: _map(center, truck)),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: _statusCard(status),
        ),
      ],
    );
  }

  Widget _map(LatLng center, LatLng? truck) {
    final token = dotenv.env['MAPBOX_TOKEN'] ?? '';
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: center, initialZoom: 14),
      children: [
        TileLayer(
          urlTemplate:
              'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}',
          additionalOptions: {'accessToken': token},
          userAgentPackageName: 'com.example.eco_alerta',
        ),
        MarkerLayer(
          markers: [
            if (_userPosition != null)
              Marker(
                point: _userPosition!,
                width: 26,
                height: 26,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            if (truck != null)
              Marker(
                point: truck,
                width: 44,
                height: 44,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3)),
                    ],
                  ),
                  child: const Icon(Icons.local_shipping, color: Colors.white, size: 22),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _statusCard(CollectionStatus status) {
    final prefs = ref.watch(notificationPrefsProvider);
    final eta = CollectionSchedule.etaTo(DateTime.now());
    final isEnRoute = status == CollectionStatus.enRoute;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 30, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryFixedDim,
                ),
                child: Icon(status.icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTADO',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      status.label,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isEnRoute)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'A ${eta.inMinutes} min',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onTertiaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _progressFor(status, eta),
              minHeight: 6,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Notificarme al llegar',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
                ),
              ),
              Switch(
                value: prefs.notifyOnArrival,
                activeColor: AppColors.primary,
                onChanged: (v) {
                  ref
                      .read(notificationPrefsProvider.notifier)
                      .save(prefs.copyWith(notifyOnArrival: v));
                  if (v && isEnRoute) {
                    NotificationService.instance.showArrivalNotification();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  double _progressFor(CollectionStatus status, Duration eta) {
    switch (status) {
      case CollectionStatus.notYet:
        return 0.1;
      case CollectionStatus.enRoute:
        // 06:00→0% , 07:00→100%
        final remaining = eta.inMinutes.clamp(0, 60);
        return (60 - remaining) / 60;
      case CollectionStatus.done:
        return 1;
    }
  }
}
