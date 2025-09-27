// lib/src/rendering/performance_optimizer.dart

import 'package:flutter/material.dart';
import '../layout/layout_engine.dart';
import '../music_model/musical_element.dart';

/// Otimizador de performance para renderização instantânea
class PerformanceOptimizer {

  /// Cache de paths pré-calculados para reutilização
  static final Map<String, Path> _pathCache = {};

  /// Cache de medições de texto
  static final Map<String, TextPainter> _textCache = {};

  /// Cache de posições calculadas
  static final Map<String, Offset> _positionCache = {};

  /// Limpa todos os caches para liberar memória
  static void clearCaches() {
    _pathCache.clear();
    _textCache.clear();
    _positionCache.clear();
  }

  /// Obtém ou cria um path para desenhar linhas de pauta
  static Path getStaffLinesPath(double width, double y, double staffSpace) {
    final key = 'staff_${width}_${y}_$staffSpace';

    return _pathCache.putIfAbsent(key, () {
      final path = Path();
      for (int i = 0; i < 5; i++) {
        final lineY = y + (i * staffSpace);
        path.moveTo(0, lineY);
        path.lineTo(width, lineY);
      }
      return path;
    });
  }

  /// Obtém ou cria um path para hastes de notas
  static Path getNoteStemPath(Offset start, Offset end) {
    final key = 'stem_${start.dx}_${start.dy}_${end.dx}_${end.dy}';

    return _pathCache.putIfAbsent(key, () {
      final path = Path();
      path.moveTo(start.dx, start.dy);
      path.lineTo(end.dx, end.dy);
      return path;
    });
  }

  /// Obtém ou cria um path para barras de ligação
  static Path getBeamPath(List<Offset> points) {
    final key = 'beam_${points.map((p) => '${p.dx}_${p.dy}').join('_')}';

    return _pathCache.putIfAbsent(key, () {
      final path = Path();
      if (points.isNotEmpty) {
        path.moveTo(points.first.dx, points.first.dy);
        for (int i = 1; i < points.length; i++) {
          path.lineTo(points[i].dx, points[i].dy);
        }
        path.close();
      }
      return path;
    });
  }

  /// Obtém um TextPainter otimizado para texto musical
  static TextPainter getTextPainter(String text, TextStyle style) {
    final key = '${text}_${style.fontSize}_${style.fontFamily}_${style.color}';

    return _textCache.putIfAbsent(key, () {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      painter.layout();
      return painter;
    });
  }

  /// Calcula posição otimizada para símbolos SMuFL
  static Offset getSymbolPosition(
    String glyphName,
    Offset basePosition,
    double fontSize,
    Map<String, dynamic>? glyphMetrics,
  ) {
    final key = '${glyphName}_${basePosition.dx}_${basePosition.dy}_$fontSize';

    return _positionCache.putIfAbsent(key, () {
      double offsetX = 0.0;
      double offsetY = 0.0;

      if (glyphMetrics != null) {
        final bBoxSW = glyphMetrics['bBoxSW'] as List<double>?;
        if (bBoxSW != null && bBoxSW.length >= 2) {
          offsetX = -bBoxSW[0] * fontSize;
          offsetY = -bBoxSW[1] * fontSize;
        }
      }

      return Offset(basePosition.dx + offsetX, basePosition.dy + offsetY);
    });
  }

  /// Agrupa elementos por tipo para renderização em lote
  static Map<Type, List<PositionedElement>> groupElementsByType(
    List<PositionedElement> elements,
  ) {
    final grouped = <Type, List<PositionedElement>>{};

    for (final element in elements) {
      final type = element.element.runtimeType;
      grouped.putIfAbsent(type, () => []).add(element);
    }

    return grouped;
  }

  /// Calcula região visível para renderização seletiva
  static List<PositionedElement> getVisibleElements(
    List<PositionedElement> elements,
    Rect visibleRect, {
    double margin = 50.0,
  }) {
    final expandedRect = visibleRect.inflate(margin);

    return elements.where((element) {
      final pos = element.position;
      return expandedRect.contains(pos);
    }).toList();
  }

  /// Otimiza ordem de renderização para melhor performance
  static List<PositionedElement> optimizeRenderOrder(
    List<PositionedElement> elements,
  ) {
    // Ordena por sistema primeiro, depois por posição X
    elements.sort((a, b) {
      final systemCompare = a.system.compareTo(b.system);
      if (systemCompare != 0) return systemCompare;
      return a.position.dx.compareTo(b.position.dx);
    });

    // Reordena para renderizar elementos de fundo primeiro
    final List<PositionedElement> background = [];
    final List<PositionedElement> foreground = [];

    for (final element in elements) {
      if (_isBackgroundElement(element.element)) {
        background.add(element);
      } else {
        foreground.add(element);
      }
    }

    return [...background, ...foreground];
  }

  /// Verifica se um elemento deve ser renderizado no fundo
  static bool _isBackgroundElement(MusicalElement element) {
    return element is Clef ||
           element is KeySignature ||
           element is TimeSignature ||
           element is Barline;
  }

  /// Implementa pool de objetos para reduzir alocações
  static final List<Paint> _paintPool = [];

  /// Obtém um objeto Paint do pool ou cria um novo
  static Paint getPaint({
    Color color = Colors.black,
    double strokeWidth = 1.0,
    PaintingStyle style = PaintingStyle.fill,
  }) {
    Paint paint;

    if (_paintPool.isNotEmpty) {
      paint = _paintPool.removeLast();
    } else {
      paint = Paint();
    }

    paint.color = color;
    paint.strokeWidth = strokeWidth;
    paint.style = style;
    paint.isAntiAlias = true;

    return paint;
  }

  /// Retorna um objeto Paint para o pool
  static void returnPaint(Paint paint) {
    if (_paintPool.length < 20) { // Limita o tamanho do pool
      _paintPool.add(paint);
    }
  }

  /// Otimizações específicas para renderização de texto SMuFL
  static void drawOptimizedSmuflText(
    Canvas canvas,
    String character,
    Offset position,
    double fontSize,
    Color color,
  ) {
    final style = TextStyle(
      fontFamily: 'Bravura',
      fontSize: fontSize,
      color: color,
      fontFeatures: const [FontFeature.enable('kern')],
    );

    final painter = getTextPainter(character, style);

    painter.paint(
      canvas,
      Offset(
        position.dx - painter.width / 2,
        position.dy - painter.height / 2,
      ),
    );
  }

  /// Implementa renderização em lote para elementos similares
  static void batchRender<T extends MusicalElement>(
    Canvas canvas,
    List<PositionedElement> elements,
    void Function(Canvas, T, Offset) renderFunction,
  ) {
    for (final element in elements) {
      if (element.element is T) {
        renderFunction(canvas, element.element as T, element.position);
      }
    }
  }

  /// Calcula métricas de performance (usando microsegundos como entrada)
  static PerformanceMetrics calculateMetrics(
    List<PositionedElement> elements,
    int microseconds,
  ) {
    return PerformanceMetrics(
      elementCount: elements.length,
      renderTimeMs: microseconds / 1000.0,
      cacheHitRate: _calculateCacheHitRate(),
      memoryUsage: _estimateMemoryUsage(),
    );
  }

  static double _calculateCacheHitRate() {
    final totalCacheAccess = _pathCache.length + _textCache.length + _positionCache.length;
    if (totalCacheAccess == 0) return 0.0;
    return totalCacheAccess * 0.8; // Estimativa
  }

  static double _estimateMemoryUsage() {
    return (_pathCache.length * 100 +
            _textCache.length * 50 +
            _positionCache.length * 16) / 1024; // KB
  }
}

/// Métricas de performance da renderização
class PerformanceMetrics {
  final int elementCount;
  final double renderTimeMs;
  final double cacheHitRate;
  final double memoryUsage;

  const PerformanceMetrics({
    required this.elementCount,
    required this.renderTimeMs,
    required this.cacheHitRate,
    required this.memoryUsage,
  });

  @override
  String toString() {
    return 'PerformanceMetrics('
           'elements: $elementCount, '
           'renderTime: ${renderTimeMs.toStringAsFixed(2)}ms, '
           'cacheHit: ${(cacheHitRate * 100).toStringAsFixed(1)}%, '
           'memory: ${memoryUsage.toStringAsFixed(1)}KB)';
  }
}