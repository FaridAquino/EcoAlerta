import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/providers/current_user_provider.dart';
import '../../../auth/providers/routes_provider.dart';

/// Muestra en el mapa las rutas que el usuario eligió en el registro y permite
/// visualizar una a la vez (se encuadra por encima de la lista inferior).
class RoutesScreen extends ConsumerStatefulWidget {
  const RoutesScreen({super.key});

  @override
  ConsumerState<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends ConsumerState<RoutesScreen> {
  final _mapController = MapController();
  String? _visualizedId;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _fitRoute(CollectionRoute route) {
    final pts = route.orderedNodes.map((n) => LatLng(n.lat, n.lng)).toList();
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      _mapController.move(pts.first, 16);
      return;
    }
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: pts,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 24,
          bottom: 120,
          left: 32,
          right: 32,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(userRoutesProvider);
    return routesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (routes) {
        if (routes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No agregaste rutas en el registro.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
              ),
            ),
          );
        }
        final selected = routes.where((r) => r.id == _visualizedId).firstOrNull;
        final pts = selected?.orderedNodes.map((n) => LatLng(n.lat, n.lng)).toList() ??
            <LatLng>[];
        final center = LatLng(routes.first.nodes.first.lat, routes.first.nodes.first.lng);

        return Stack(
          children: [
            Positioned.fill(child: _map(pts, center)),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _routeChips(routes),
            ),
          ],
        );
      },
    );
  }

  Widget _map(List<LatLng> pts, LatLng center) {
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
        if (pts.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(points: pts, color: AppColors.primary, strokeWidth: 4),
            ],
          ),
        if (pts.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(
                point: pts.first,
                child: const Icon(Icons.location_on, color: AppColors.primary, size: 32),
              ),
              Marker(
                point: pts.last,
                child: const Icon(Icons.flag, color: AppColors.tertiary, size: 28),
              ),
            ],
          ),
      ],
    );
  }

  Widget _routeChips(List<CollectionRoute> routes) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, -6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MIS RUTAS',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: routes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final r = routes[i];
                final isSel = r.id == _visualizedId;
                return ChoiceChip(
                  selected: isSel,
                  label: Text(r.name),
                  labelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: isSel ? AppColors.onPrimary : AppColors.onSurface,
                  ),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  onSelected: (_) {
                    setState(() => _visualizedId = r.id);
                    _fitRoute(r);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
