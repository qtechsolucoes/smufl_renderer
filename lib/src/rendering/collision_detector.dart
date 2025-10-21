// lib/src/rendering/collision_detector.dart
// Sistema de Detecção de Colisões - Algoritmo Skyline
//
// Implementação baseada em:
// - Verovio: https://www.verovio.org/
// - Behind Bars (Elaine Gould) - Chapter 1: Spacing
// - The Art of Music Engraving (Ted Ross) - Chapter 4: Spacing
//
// O algoritmo Skyline é usado para detectar e evitar colisões entre
// elementos musicais (notas, acidentes, articulações, etc.)

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Representa um elemento registrado no detector de colisões
class CollisionElement {
  final String id;
  final Rect bounds;
  final CollisionPriority priority;
  final CollisionCategory category;
  final double timestamp;

  CollisionElement({
    required this.id,
    required this.bounds,
    required this.priority,
    required this.category,
    required this.timestamp,
  });

  /// Verifica se este elemento colide com outro
  bool collidesWith(CollisionElement other, {double margin = 0.0}) {
    final expandedBounds = bounds.inflate(margin);
    return expandedBounds.overlaps(other.bounds);
  }

  /// Calcula a área de sobreposição com outro elemento
  double overlapArea(CollisionElement other) {
    final intersection = bounds.intersect(other.bounds);
    if (intersection.isEmpty) return 0.0;
    return intersection.width * intersection.height;
  }
}

/// Prioridade de elementos para resolução de colisões
enum CollisionPriority {
  /// Elementos que não podem ser movidos (claves, fórmulas de compasso)
  immovable(100),

  /// Elementos muito importantes (cabeças de nota, acidentes)
  veryHigh(80),

  /// Elementos importantes (hastes, bandeirolas, beams)
  high(60),

  /// Elementos com prioridade média (articulações, dinâmicas)
  medium(40),

  /// Elementos com baixa prioridade (ligaduras, slurs)
  low(20),

  /// Elementos que podem ser facilmente movidos (texto, ornamentos)
  veryLow(10);

  final int value;
  const CollisionPriority(this.value);
}

/// Categoria de elementos musicais
enum CollisionCategory {
  notehead,
  accidental,
  stem,
  flag,
  beam,
  articulation,
  ornament,
  dynamic,
  lyric,
  tie,
  slur,
  clef,
  keySignature,
  timeSignature,
  barline,
  text,
}

/// Detector de colisões usando algoritmo Skyline
///
/// O Skyline mantém um perfil vertical do espaço ocupado,
/// permitindo detecção eficiente de colisões.
class CollisionDetector {
  final List<CollisionElement> _elements = [];
  final Map<String, CollisionElement> _elementById = {};

  /// Margem padrão de segurança entre elementos (em pixels)
  final double defaultMargin;

  /// Margem específica por categoria
  final Map<CollisionCategory, double> categoryMargins;

  CollisionDetector({
    this.defaultMargin = 2.0,
    Map<CollisionCategory, double>? categoryMargins,
  }) : categoryMargins = categoryMargins ?? _defaultCategoryMargins;

  /// Margens padrão por categoria (baseadas em Behind Bars)
  static final Map<CollisionCategory, double> _defaultCategoryMargins = {
    CollisionCategory.notehead: 1.0,
    CollisionCategory.accidental: 2.0,
    CollisionCategory.stem: 0.5,
    CollisionCategory.flag: 1.0,
    CollisionCategory.beam: 1.0,
    CollisionCategory.articulation: 2.0,
    CollisionCategory.ornament: 2.0,
    CollisionCategory.dynamic: 3.0,
    CollisionCategory.lyric: 3.0,
    CollisionCategory.tie: 1.0,
    CollisionCategory.slur: 1.0,
    CollisionCategory.clef: 2.0,
    CollisionCategory.keySignature: 1.5,
    CollisionCategory.timeSignature: 1.5,
    CollisionCategory.barline: 1.0,
    CollisionCategory.text: 2.0,
  };

  /// Registra um novo elemento
  void register({
    required String id,
    required Rect bounds,
    required CollisionCategory category,
    CollisionPriority priority = CollisionPriority.medium,
  }) {
    final element = CollisionElement(
      id: id,
      bounds: bounds,
      priority: priority,
      category: category,
      timestamp: DateTime.now().millisecondsSinceEpoch.toDouble(),
    );

    _elements.add(element);
    _elementById[id] = element;
  }

  /// Verifica se um elemento colide com elementos existentes
  bool hasCollision({
    required Rect bounds,
    required CollisionCategory category,
    String? ignoreId,
  }) {
    final margin = categoryMargins[category] ?? defaultMargin;

    for (final element in _elements) {
      if (ignoreId != null && element.id == ignoreId) continue;

      final expandedBounds = bounds.inflate(margin);
      if (expandedBounds.overlaps(element.bounds)) {
        return true;
      }
    }

    return false;
  }

  /// Encontra todos os elementos que colidem com as bounds fornecidas
  List<CollisionElement> findCollisions({
    required Rect bounds,
    required CollisionCategory category,
    String? ignoreId,
  }) {
    final margin = categoryMargins[category] ?? defaultMargin;
    final collisions = <CollisionElement>[];

    for (final element in _elements) {
      if (ignoreId != null && element.id == ignoreId) continue;

      final expandedBounds = bounds.inflate(margin);
      if (expandedBounds.overlaps(element.bounds)) {
        collisions.add(element);
      }
    }

    return collisions;
  }

  /// Calcula o deslocamento horizontal necessário para evitar colisão
  ///
  /// Retorna o offset mínimo em X para evitar colisão.
  /// Positivo = mover para direita, Negativo = mover para esquerda
  double calculateHorizontalOffset({
    required Rect bounds,
    required CollisionCategory category,
    String? ignoreId,
    bool preferRight = true,
  }) {
    final collisions = findCollisions(
      bounds: bounds,
      category: category,
      ignoreId: ignoreId,
    );

    if (collisions.isEmpty) return 0.0;

    final margin = categoryMargins[category] ?? defaultMargin;
    double minOffset = 0.0;

    for (final collision in collisions) {
      // Calcular overlap horizontal
      final overlap = _calculateHorizontalOverlap(bounds, collision.bounds);

      if (overlap > 0) {
        // Calcular quanto precisa mover
        final offsetNeeded = overlap + margin;

        if (preferRight) {
          // Mover para direita
          minOffset = math.max(minOffset, offsetNeeded);
        } else {
          // Mover para esquerda
          minOffset = math.min(minOffset, -offsetNeeded);
        }
      }
    }

    return minOffset;
  }

  /// Calcula o deslocamento vertical necessário para evitar colisão
  double calculateVerticalOffset({
    required Rect bounds,
    required CollisionCategory category,
    String? ignoreId,
    bool preferUp = true,
  }) {
    final collisions = findCollisions(
      bounds: bounds,
      category: category,
      ignoreId: ignoreId,
    );

    if (collisions.isEmpty) return 0.0;

    final margin = categoryMargins[category] ?? defaultMargin;
    double minOffset = 0.0;

    for (final collision in collisions) {
      // Calcular overlap vertical
      final overlap = _calculateVerticalOverlap(bounds, collision.bounds);

      if (overlap > 0) {
        // Calcular quanto precisa mover
        final offsetNeeded = overlap + margin;

        if (preferUp) {
          // Mover para cima (Y negativo)
          minOffset = math.min(minOffset, -offsetNeeded);
        } else {
          // Mover para baixo (Y positivo)
          minOffset = math.max(minOffset, offsetNeeded);
        }
      }
    }

    return minOffset;
  }

  /// Calcula overlap horizontal entre dois retângulos
  double _calculateHorizontalOverlap(Rect a, Rect b) {
    final left = math.max(a.left, b.left);
    final right = math.min(a.right, b.right);
    return math.max(0.0, right - left);
  }

  /// Calcula overlap vertical entre dois retângulos
  double _calculateVerticalOverlap(Rect a, Rect b) {
    final top = math.max(a.top, b.top);
    final bottom = math.min(a.bottom, b.bottom);
    return math.max(0.0, bottom - top);
  }

  /// Encontra a posição horizontal livre mais próxima
  ///
  /// Útil para posicionar acidentes em acordes
  double findNearestFreeX({
    required Rect bounds,
    required CollisionCategory category,
    required double startX,
    required double searchDirection, // -1 = esquerda, +1 = direita
    double searchStep = 1.0,
    double maxSearch = 100.0,
  }) {
    double currentX = startX;
    final searchEnd = startX + (searchDirection * maxSearch);

    while ((searchDirection > 0 && currentX < searchEnd) ||
        (searchDirection < 0 && currentX > searchEnd)) {
      final testBounds = bounds.shift(Offset(currentX - bounds.left, 0));

      if (!hasCollision(
        bounds: testBounds,
        category: category,
      )) {
        return currentX;
      }

      currentX += searchDirection * searchStep;
    }

    // Se não encontrou espaço livre, retornar posição final
    return currentX;
  }

  /// Obtém estatísticas de colisões
  CollisionStatistics getStatistics() {
    int totalCollisions = 0;
    final Map<CollisionCategory, int> collisionsByCategory = {};

    for (int i = 0; i < _elements.length; i++) {
      for (int j = i + 1; j < _elements.length; j++) {
        if (_elements[i].collidesWith(_elements[j])) {
          totalCollisions++;

          collisionsByCategory[_elements[i].category] =
              (collisionsByCategory[_elements[i].category] ?? 0) + 1;
          collisionsByCategory[_elements[j].category] =
              (collisionsByCategory[_elements[j].category] ?? 0) + 1;
        }
      }
    }

    return CollisionStatistics(
      totalElements: _elements.length,
      totalCollisions: totalCollisions,
      collisionsByCategory: collisionsByCategory,
    );
  }

  /// Limpa todos os elementos registrados
  void clear() {
    _elements.clear();
    _elementById.clear();
  }

  /// Remove um elemento específico
  void remove(String id) {
    final element = _elementById[id];
    if (element != null) {
      _elements.remove(element);
      _elementById.remove(id);
    }
  }

  /// Obtém elemento por ID
  CollisionElement? getElement(String id) => _elementById[id];

  /// Número de elementos registrados
  int get elementCount => _elements.length;
}

/// Estatísticas de colisões
class CollisionStatistics {
  final int totalElements;
  final int totalCollisions;
  final Map<CollisionCategory, int> collisionsByCategory;

  CollisionStatistics({
    required this.totalElements,
    required this.totalCollisions,
    required this.collisionsByCategory,
  });

  /// Taxa de colisão (0.0 a 1.0)
  double get collisionRate {
    if (totalElements <= 1) return 0.0;
    final maxPossibleCollisions = (totalElements * (totalElements - 1)) ~/ 2;
    return totalCollisions / maxPossibleCollisions;
  }

  @override
  String toString() {
    return 'CollisionStatistics(elements: $totalElements, '
        'collisions: $totalCollisions, '
        'rate: ${(collisionRate * 100).toStringAsFixed(1)}%)';
  }
}
