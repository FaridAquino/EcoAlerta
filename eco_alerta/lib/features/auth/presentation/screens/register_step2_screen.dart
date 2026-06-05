import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/routes_provider.dart';

class RegisterStep2Screen extends ConsumerStatefulWidget {
  final String email;
  final String password;

  const RegisterStep2Screen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  ConsumerState<RegisterStep2Screen> createState() => _RegisterStep2ScreenState();
}

class _RegisterStep2ScreenState extends ConsumerState<RegisterStep2Screen> {
  final _addressCtrl = TextEditingController();
  final _mapController = MapController();
  String? _selectedRouteId;

  @override
  void initState() {
    super.initState();
    _addressCtrl.text = 'Av. Principal 123';
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _finish(List<CollectionRoute> routes) async {
    if (_selectedRouteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una ruta de recolección')),
      );
      return;
    }
    final ok = await ref.read(authProvider.notifier).register(
          email: widget.email,
          password: widget.password,
          routeId: _selectedRouteId!,
          address: _addressCtrl.text.trim(),
        );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta creada. Inicia sesión.'),
          backgroundColor: AppColors.primaryContainer,
        ),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(routesProvider);
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    ref.listen(authProvider, (_, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: AppColors.error),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: routesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (routes) => _buildContent(routes, isLoading),
      ),
    );
  }

  Widget _buildContent(List<CollectionRoute> routes, bool isLoading) {
    final selected = routes.where((r) => r.id == _selectedRouteId).firstOrNull;
    final polylinePoints = selected != null
        ? selected.orderedNodes
            .map((n) => LatLng(n.lat, n.lng))
            .toList()
        : <LatLng>[];

    final mapCenter = routes.isNotEmpty
        ? LatLng(routes.first.nodes.first.lat, routes.first.nodes.first.lng)
        : const LatLng(19.4326, -99.1332);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 650;
        return isDesktop
            ? _desktopLayout(routes, polylinePoints, mapCenter, isLoading)
            : _mobileLayout(routes, polylinePoints, mapCenter, isLoading);
      },
    );
  }

  Widget _mapWidget(List<LatLng> polylinePoints, LatLng center) {
    final token = dotenv.env['MAPBOX_TOKEN'] ?? '';
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: center, initialZoom: 14),
      children: [
        TileLayer(
          urlTemplate:
              'https://api.mapbox.com/styles/v1/mapbox/light-v11/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}',
          additionalOptions: {'accessToken': token},
          userAgentPackageName: 'com.example.eco_alerta',
        ),
        if (polylinePoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: polylinePoints,
                color: AppColors.primary,
                strokeWidth: 4,
              ),
            ],
          ),
        if (polylinePoints.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(
                point: polylinePoints.first,
                child: const Icon(Icons.location_on, color: AppColors.primary, size: 32),
              ),
              Marker(
                point: polylinePoints.last,
                child: const Icon(Icons.flag, color: AppColors.tertiary, size: 28),
              ),
            ],
          ),
      ],
    );
  }

  Widget _card(List<CollectionRoute> routes, bool isLoading) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(color: Color(0x1A000000), blurRadius: 30, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PASO 2 DE 2',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tu Ubicación',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Define tu zona para conectarte con la ruta de recolección óptima.',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                _AddressField(controller: _addressCtrl),
                const SizedBox(height: 16),
                _RoutesSection(
                  routes: routes,
                  selectedId: _selectedRouteId,
                  onSelect: (id) {
                    setState(() => _selectedRouteId = id);
                    final route = routes.firstWhere((r) => r.id == id);
                    if (route.nodes.isNotEmpty) {
                      _mapController.move(
                        LatLng(route.nodes.first.lat, route.nodes.first.lng),
                        14,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border(top: BorderSide(color: AppColors.surfaceContainerHighest)),
            ),
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _finish(routes),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Finalizar Registro',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileLayout(
    List<CollectionRoute> routes,
    List<LatLng> polylinePoints,
    LatLng center,
    bool isLoading,
  ) {
    return Stack(
      children: [
        Positioned.fill(child: _mapWidget(polylinePoints, center)),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _card(routes, isLoading),
        ),
      ],
    );
  }

  Widget _desktopLayout(
    List<CollectionRoute> routes,
    List<LatLng> polylinePoints,
    LatLng center,
    bool isLoading,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 400,
          child: SingleChildScrollView(child: _card(routes, isLoading)),
        ),
        Expanded(child: _mapWidget(polylinePoints, center)),
      ],
    );
  }
}

class _AddressField extends StatelessWidget {
  final TextEditingController controller;

  const _AddressField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.inter(fontSize: 16, color: AppColors.onSurface),
      decoration: InputDecoration(
        hintText: 'Buscar dirección o código postal...',
        hintStyle: GoogleFonts.inter(
          fontSize: 16,
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        prefixIcon: const Icon(Icons.search, color: AppColors.onSurfaceVariant, size: 20),
        suffixIcon: IconButton(
          icon: const Icon(Icons.my_location, color: AppColors.primary, size: 20),
          onPressed: () {},
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _RoutesSection extends StatelessWidget {
  final List<CollectionRoute> routes;
  final String? selectedId;
  final void Function(String id) onSelect;

  const _RoutesSection({
    required this.routes,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RUTAS SUGERIDAS',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
                letterSpacing: 0.1,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${routes.length} Encontradas',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...routes.map((route) => _RouteOption(
              route: route,
              isSelected: selectedId == route.id,
              onTap: () => onSelect(route.id),
            )),
      ],
    );
  }
}

class _RouteOption extends StatelessWidget {
  final CollectionRoute route;
  final bool isSelected;
  final VoidCallback onTap;

  const _RouteOption({
    required this.route,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceContainerHighest,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? const [BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 2))]
              : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.primaryContainer
                    : AppColors.surfaceContainerHigh,
              ),
              child: Icon(
                Icons.route,
                size: 20,
                color: isSelected ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        route.schedule.join(', '),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'A ${route.distanceKm} km',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
