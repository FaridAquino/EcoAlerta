# EcoAlerta

App móvil Flutter para alertas ecológicas (contaminación, sismos, fenómenos ambientales).

## Arquitectura

Feature-based con Clean Architecture por módulo:

```
lib/
├── core/          # Constantes, tema, utilidades, errores
├── features/      # Módulos de la app (por definir)
│   └── [feature]/
│       ├── data/          # APIs, DTOs, datasources
│       ├── domain/        # Entidades, use cases
│       ├── presentation/  # Screens y widgets
│       └── providers/     # Providers Riverpod del módulo
├── shared/        # Widgets, servicios y modelos compartidos
└── routes/        # Configuración de navegación (GoRouter)
```

## Stack

| Área | Librería |
|---|---|
| Estado | `flutter_riverpod` + `riverpod_annotation` |
| Navegación | `go_router` |
| Red | `dio` |
| Modelos | `freezed` + `json_serializable` |
| Almacenamiento | `shared_preferences` |

## Convenciones

- Usar `ConsumerWidget` en lugar de `StatefulWidget` para estado global
- `setState` solo para estado local de UI (sin efecto en otros widgets)
- `const` en todos los widgets estáticos
- Archivos y carpetas en `snake_case`
- Nunca mutar estado directamente; siempre crear nuevas instancias

## Comandos

```bash
flutter run                        # Ejecutar app
flutter analyze                    # Verificar lints
flutter test                       # Correr tests
flutter pub get                    # Instalar dependencias
dart run build_runner build        # Generar código (freezed, riverpod)
```

## Navegación

```dart
context.go('/ruta')       // Reemplaza el stack
context.push('/ruta')     // Agrega al stack (permite volver)
context.pop()             // Regresa
```
