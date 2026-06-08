import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
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
  final _cardKey = GlobalKey();
  final Set<String> _addedRouteIds = {};
  String? _visualizedRouteId;
  LatLng? _userPosition;
  double _cardHeight = 0;

  @override
  void initState() {
    super.initState();
    _addressCtrl.text = 'Av. Principal 123';
    _initLocation();
  }

  Future<void> _initLocation() async {
    // Muestra rápido la última posición conocida (si existe) y luego refina.
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && mounted) {
        setState(() => _userPosition = LatLng(last.latitude, last.longitude));
        _moveToWithCardOffset(_userPosition!, 16);
      }
    } catch (_) {}

    final pos = await _fetchCurrentPosition();
    if (pos == null || !mounted) return;
    setState(() => _userPosition = pos);
    _moveToWithCardOffset(pos, 16);
  }

  /// Obtiene la posición actual del dispositivo gestionando los permisos.
  Future<LatLng?> _fetchCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Vuelve a centrar el mapa en la ubicación actual del usuario ("donde me
  /// encuentro ahora"), desplazándola hacia arriba para que no la tape la tarjeta.
  Future<void> _recenterOnUser() async {
    // Centra de inmediato en la última posición conocida para evitar la espera
    // del fix GPS; luego refina en segundo plano.
    if (_userPosition != null) _moveToWithCardOffset(_userPosition!, 16);
    final pos = await _fetchCurrentPosition();
    if (pos == null || !mounted) return;
    setState(() => _userPosition = pos);
    _moveToWithCardOffset(pos, 16);
  }

  /// Mueve la cámara a [target] reproyectando el punto algunos píxeles hacia
  /// arriba (la mitad de la altura de la tarjeta) para que quede visible.
  void _moveToWithCardOffset(LatLng target, double zoom) {
    _mapController.move(target, zoom);
    if (_cardHeight <= 0) return;
    final camera = _mapController.camera;
    final pt = camera.latLngToScreenPoint(target);
    final shifted = camera.pointToLatLng(math.Point(pt.x, pt.y + _cardHeight / 2));
    _mapController.move(shifted, zoom);
  }

  /// Encuadra la ruta completa dejando espacio inferior igual a la tarjeta.
  void _fitRoute(CollectionRoute route) {
    final pts = route.orderedNodes.map((n) => LatLng(n.lat, n.lng)).toList();
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      _moveToWithCardOffset(pts.first, 16);
      return;
    }
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: pts,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 24,
          bottom: _cardHeight + 24,
          left: 32,
          right: 32,
        ),
      ),
    );
  }

  /// Mide la altura real de la tarjeta inferior tras el layout.
  void _measureCard() {
    final box = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final h = box.size.height;
    if (h != _cardHeight) setState(() => _cardHeight = h);
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _finish(List<CollectionRoute> routes) async {
    if (_addedRouteIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos una ruta de recolección')),
      );
      return;
    }
    final ok = await ref.read(authProvider.notifier).register(
          email: widget.email,
          password: widget.password,
          routeId: _addedRouteIds.join(','),
          address: _addressCtrl.text.trim(),
        );
    if (!ok || !mounted) return;

    // Auto-inicia sesión y entra directo al calendario.
    final loggedIn =
        await ref.read(authProvider.notifier).login(widget.email, widget.password);
    if (loggedIn && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cuenta creada! Bienvenido a EcoAlerta.'),
          backgroundColor: AppColors.primaryContainer,
        ),
      );
      context.go('/schedule');
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureCard());
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: routesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (routes) => _buildContent(routes, isLoading),
        ),
      ),
    );
  }

  Widget _buildContent(List<CollectionRoute> routes, bool isLoading) {
    final selected = routes.where((r) => r.id == _visualizedRouteId).firstOrNull;
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
              'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}',
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
        if (_userPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _userPosition!,
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withValues(alpha: 0.9),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _card(List<CollectionRoute> routes, bool isLoading) {
    return Container(
      key: _cardKey,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  addedIds: _addedRouteIds,
                  visualizedId: _visualizedRouteId,
                  onToggleAdd: (id) {
                    setState(() {
                      if (!_addedRouteIds.remove(id)) _addedRouteIds.add(id);
                    });
                  },
                  onVisualize: (id) {
                    setState(() => _visualizedRouteId = id);
                    _fitRoute(routes.firstWhere((r) => r.id == id));
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
          top: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).padding.top + 8,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _card(routes, isLoading),
        ),
        Positioned(
          right: 16,
          bottom: _cardHeight + 16,
          child: Material(
            color: AppColors.surface,
            shape: const CircleBorder(),
            elevation: 4,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _recenterOnUser,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.my_location, color: AppColors.primary, size: 24),
              ),
            ),
          ),
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
  final Set<String> addedIds;
  final String? visualizedId;
  final void Function(String id) onToggleAdd;
  final void Function(String id) onVisualize;

  const _RoutesSection({
    required this.routes,
    required this.addedIds,
    required this.visualizedId,
    required this.onToggleAdd,
    required this.onVisualize,
  });

  @override
  Widget build(BuildContext context) {
    final badge = addedIds.isEmpty
        ? '${routes.length} Encontradas'
        : '${addedIds.length} Agregadas';
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
                badge,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Toca + para agregar una ruta y toca la tarjeta para verla en el mapa.',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        ...routes.map((route) => _RouteOption(
              route: route,
              isAdded: addedIds.contains(route.id),
              isVisualized: visualizedId == route.id,
              onToggleAdd: () => onToggleAdd(route.id),
              onVisualize: () => onVisualize(route.id),
            )),
      ],
    );
  }
}

class _RouteOption extends StatelessWidget {
  final CollectionRoute route;
  final bool isAdded;
  final bool isVisualized;
  final VoidCallback onToggleAdd;
  final VoidCallback onVisualize;

  const _RouteOption({
    required this.route,
    required this.isAdded,
    required this.isVisualized,
    required this.onToggleAdd,
    required this.onVisualize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onVisualize,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isVisualized
              ? AppColors.primaryContainer.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isVisualized ? AppColors.primary : AppColors.surfaceContainerHighest,
            width: isVisualized ? 2 : 1,
          ),
          boxShadow: isVisualized
              ? const [BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 2))]
              : null,
        ),
        child: Row(
          children: [
            _AddRouteButton(isAdded: isAdded, onTap: onToggleAdd),
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
                  Icons.visibility,
                  size: 20,
                  color: isVisualized ? AppColors.primary : Colors.transparent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón circular "+" a la izquierda de cada ruta para agregarla/quitarla
/// del conjunto que se guardará (independiente de la visualización en el mapa).
class _AddRouteButton extends StatelessWidget {
  final bool isAdded;
  final VoidCallback onTap;

  const _AddRouteButton({required this.isAdded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isAdded ? AppColors.primary : AppColors.surfaceContainerHigh,
          border: Border.all(
            color: isAdded ? AppColors.primary : AppColors.surfaceContainerHighest,
          ),
        ),
        child: Icon(
          isAdded ? Icons.check : Icons.add,
          size: 22,
          color: isAdded ? AppColors.onPrimary : AppColors.primary,
        ),
      ),
    );
  }
}
