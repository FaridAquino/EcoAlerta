import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RouteNode {
  final String id;
  final String label;
  final double lat;
  final double lng;

  const RouteNode({
    required this.id,
    required this.label,
    required this.lat,
    required this.lng,
  });

  factory RouteNode.fromMap(Map<String, dynamic> m) => RouteNode(
        id: m['id'] as String,
        label: m['label'] as String,
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
      );
}

class RouteEdge {
  final String from;
  final String to;

  const RouteEdge({required this.from, required this.to});

  factory RouteEdge.fromMap(Map<String, dynamic> m) =>
      RouteEdge(from: m['from'] as String, to: m['to'] as String);
}

class CollectionRoute {
  final String id;
  final String name;
  final List<String> schedule;
  final double distanceKm;
  final String start;
  final String end;
  final List<RouteNode> nodes;
  final List<RouteEdge> edges;

  const CollectionRoute({
    required this.id,
    required this.name,
    required this.schedule,
    required this.distanceKm,
    required this.start,
    required this.end,
    required this.nodes,
    required this.edges,
  });

  factory CollectionRoute.fromMap(Map<String, dynamic> m) {
    final graph = m['graph'] as Map<String, dynamic>;
    return CollectionRoute(
      id: m['id'] as String,
      name: m['name'] as String,
      schedule: List<String>.from(m['schedule'] as List),
      distanceKm: (m['distanceKm'] as num).toDouble(),
      start: graph['start'] as String,
      end: graph['end'] as String,
      nodes: (graph['nodes'] as List)
          .map((n) => RouteNode.fromMap(Map<String, dynamic>.from(n as Map)))
          .toList(),
      edges: (graph['edges'] as List)
          .map((e) => RouteEdge.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  List<RouteNode> get orderedNodes {
    final nodeMap = {for (final n in nodes) n.id: n};
    final adjacency = <String, String>{};
    for (final e in edges) {
      adjacency[e.from] = e.to;
    }
    final result = <RouteNode>[];
    String? current = start;
    while (current != null && nodeMap.containsKey(current)) {
      result.add(nodeMap[current]!);
      current = adjacency[current];
    }
    return result;
  }
}

final routesProvider = FutureProvider<List<CollectionRoute>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/routes.json');
  final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
  return (json['routes'] as List)
      .map((r) => CollectionRoute.fromMap(Map<String, dynamic>.from(r as Map)))
      .toList();
});
