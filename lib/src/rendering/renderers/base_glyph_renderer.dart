// lib/src/rendering/renderers/base_glyph_renderer.dart
// NOVA CLASSE BASE: Renderização unificada de glifos SMuFL
//
// Esta classe base fornece método unificado para desenhar glifos
// usando SEMPRE bounding box SMuFL para posicionamento preciso.
//
// ELIMINA inconsistências de uso de centerVertically/centerHorizontally
// que causam alinhamentos imprecisos.

import 'package:flutter/material.dart';
import '../../smufl/smufl_metadata_loader.dart';
import '../staff_coordinate_system.dart';
import '../collision_detector.dart';

/// Classe base para renderizadores de glifos SMuFL
///
/// Fornece método unificado [drawGlyphWithBBox] que SEMPRE usa
/// bounding box do metadata SMuFL para posicionamento preciso.
///
/// IMPORTANTE: Todos os renderizadores devem herdar desta classe
/// e usar exclusivamente [drawGlyphWithBBox] para renderização.
abstract class BaseGlyphRenderer {
  final StaffCoordinateSystem coordinates;
  final SmuflMetadata metadata;
  final double glyphSize;

  /// Cache de TextPainters reutilizáveis para performance
  /// Key: glyphName_size_color
  final Map<String, TextPainter> _textPainterCache = {};

  /// Detector de colisões opcional (pode ser compartilhado entre renderizadores)
  CollisionDetector? collisionDetector;

  BaseGlyphRenderer({
    required this.coordinates,
    required this.metadata,
    required this.glyphSize,
    this.collisionDetector,
  });

  /// Desenha um glifo SMuFL usando bounding box para posicionamento preciso
  ///
  /// Este é o ÚNICO método que deve ser usado para renderização de glifos.
  /// Ele garante:
  /// 1. Uso correto de bounding box SMuFL (nunca TextPainter.height/width)
  /// 2. Centralização precisa baseada em bbox.centerY e bbox.centerX
  /// 3. Cache de TextPainters para performance
  ///
  /// @param canvas Canvas do Flutter para desenho
  /// @param glyphName Nome do glifo SMuFL (ex: 'noteheadBlack', 'gClef')
  /// @param position Posição de referência (onde o glifo será desenhado)
  /// @param color Cor do glifo
  /// @param options Opções de alinhamento e transformação
  void drawGlyphWithBBox(
    Canvas canvas, {
    required String glyphName,
    required Offset position,
    required Color color,
    GlyphDrawOptions options = const GlyphDrawOptions(),
  }) {
    // Obter codepoint Unicode do glifo
    final character = metadata.getCodepoint(glyphName);
    if (character.isEmpty) {
      // Glifo não encontrado, usar fallback se fornecido
      if (options.fallbackGlyph != null) {
        drawGlyphWithBBox(
          canvas,
          glyphName: options.fallbackGlyph!,
          position: position,
          color: color,
          options: options.copyWith(fallbackGlyph: null),
        );
      }
      return;
    }

    // Obter ou criar TextPainter do cache
    final cacheKey = '${glyphName}_${options.size ?? glyphSize}_${color.toARGB32()}';
    TextPainter textPainter;

    if (_textPainterCache.containsKey(cacheKey) && !options.disableCache) {
      textPainter = _textPainterCache[cacheKey]!;
    } else {
      textPainter = TextPainter(
        text: TextSpan(
          text: character,
          style: TextStyle(
            fontFamily: 'Bravura',
            fontSize: options.size ?? glyphSize,
            color: color,
            height: 1.0,
            letterSpacing: 0.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      if (!options.disableCache) {
        _textPainterCache[cacheKey] = textPainter;
      }
    }

    // CORREÇÃO CRÍTICA: Usar bounding box SMuFL ao invés de TextPainter dimensions
    final glyphInfo = metadata.getGlyphInfo(glyphName);
    double xOffset = 0.0;
    double yOffset = 0.0;

    if (glyphInfo != null && glyphInfo.hasBoundingBox) {
      final bbox = glyphInfo.boundingBox!;

      // Calcular offsets baseados no bounding box SMuFL
      if (options.centerHorizontally) {
        // Centralizar horizontalmente usando centro do bbox
        xOffset = -(bbox.centerX * coordinates.staffSpace);
      } else if (options.alignLeft) {
        // Alinhar à esquerda usando borda esquerda do bbox
        xOffset = -(bbox.bBoxSwX * coordinates.staffSpace);
      } else if (options.alignRight) {
        // Alinhar à direita usando borda direita do bbox
        xOffset = -(bbox.bBoxNeX * coordinates.staffSpace);
      }
      // Se nenhum, usar posição como está (sem offset horizontal)

      if (options.centerVertically) {
        // Centralizar verticalmente usando centro do bbox
        yOffset = -(bbox.centerY * coordinates.staffSpace);
      } else if (options.alignTop) {
        // Alinhar ao topo usando borda superior do bbox
        yOffset = -(bbox.bBoxNeY * coordinates.staffSpace);
      } else if (options.alignBottom) {
        // Alinhar à base usando borda inferior do bbox
        yOffset = -(bbox.bBoxSwY * coordinates.staffSpace);
      }
      // Se nenhum, usar posição como está (sem offset vertical)
    } else {
      // FALLBACK: Se não houver bounding box, usar dimensões do TextPainter
      // (menos preciso, mas funcional)
      if (options.centerHorizontally) {
        xOffset = -textPainter.width * 0.5;
      }
      if (options.centerVertically) {
        yOffset = -textPainter.height * 0.5;
      }
    }

    // Aplicar transformações (rotação, escala) se necessário
    if (options.rotation != 0.0 || options.scale != 1.0) {
      canvas.save();

      // Transladar para ponto de rotação/escala
      canvas.translate(position.dx + xOffset, position.dy + yOffset);

      // Aplicar rotação
      if (options.rotation != 0.0) {
        canvas.rotate(options.rotation * 3.14159 / 180.0); // Graus para radianos
      }

      // Aplicar escala
      if (options.scale != 1.0) {
        canvas.scale(options.scale);
      }

      // Desenhar na origem (já transladamos)
      textPainter.paint(canvas, Offset.zero);

      canvas.restore();
    } else {
      // Desenho simples sem transformações
      textPainter.paint(
        canvas,
        Offset(position.dx + xOffset, position.dy + yOffset),
      );
    }

    // Registrar desenho para sistema de detecção de colisões (se habilitado)
    if (options.trackBounds &&
        collisionDetector != null &&
        glyphInfo != null &&
        glyphInfo.hasBoundingBox) {
      final bbox = glyphInfo.boundingBox!;
      final bounds = Rect.fromLTWH(
        position.dx + xOffset + (bbox.bBoxSwX * coordinates.staffSpace),
        position.dy + yOffset + (bbox.bBoxSwY * coordinates.staffSpace),
        bbox.widthInPixels(coordinates.staffSpace),
        bbox.heightInPixels(coordinates.staffSpace),
      );

      // Registrar no sistema de colisões
      collisionDetector!.register(
        id: '${glyphName}_${position.dx.toStringAsFixed(1)}_${position.dy.toStringAsFixed(1)}',
        bounds: bounds,
        category: _getCategoryForGlyph(glyphName, options),
        priority: options.collisionPriority ?? CollisionPriority.medium,
      );
    }
  }

  /// Limpa cache de TextPainters
  /// Útil para liberar memória ou quando mudanças de tema ocorrem
  void clearCache() {
    _textPainterCache.clear();
  }

  /// Obtém número de itens no cache
  int get cacheSize => _textPainterCache.length;

  /// Determina a categoria de colisão baseada no nome do glifo e opções
  CollisionCategory _getCategoryForGlyph(String glyphName, GlyphDrawOptions options) {
    // Mapear baseado no nome do glifo
    if (glyphName.startsWith('notehead')) return CollisionCategory.notehead;
    if (glyphName.startsWith('accidental')) return CollisionCategory.accidental;
    if (glyphName.startsWith('flag')) return CollisionCategory.flag;
    if (glyphName.startsWith('rest')) return CollisionCategory.notehead;
    if (glyphName.contains('Clef')) return CollisionCategory.clef;
    if (glyphName.startsWith('artic')) return CollisionCategory.articulation;
    if (glyphName.contains('dynamic') || glyphName.startsWith('dynamic')) {
      return CollisionCategory.dynamic;
    }
    if (glyphName.contains('ornament')) return CollisionCategory.ornament;

    // Categoria padrão baseada nas opções predefinidas
    if (options == GlyphDrawOptions.noteheadDefault) {
      return CollisionCategory.notehead;
    }
    if (options == GlyphDrawOptions.accidentalDefault) {
      return CollisionCategory.accidental;
    }
    if (options == GlyphDrawOptions.articulationDefault) {
      return CollisionCategory.articulation;
    }
    if (options == GlyphDrawOptions.ornamentDefault) {
      return CollisionCategory.ornament;
    }

    return CollisionCategory.text; // Fallback
  }
}

/// Opções para desenho de glifos
class GlyphDrawOptions {
  /// Centralizar horizontalmente usando bounding box center
  final bool centerHorizontally;

  /// Centralizar verticalmente usando bounding box center
  final bool centerVertically;

  /// Alinhar à esquerda usando bounding box left edge
  final bool alignLeft;

  /// Alinhar à direita usando bounding box right edge
  final bool alignRight;

  /// Alinhar ao topo usando bounding box top edge
  final bool alignTop;

  /// Alinhar à base usando bounding box bottom edge
  final bool alignBottom;

  /// Tamanho customizado (se null, usa glyphSize padrão)
  final double? size;

  /// Rotação em graus (horário positivo)
  final double rotation;

  /// Escala (1.0 = normal)
  final double scale;

  /// Glifo de fallback caso o principal não seja encontrado
  final String? fallbackGlyph;

  /// Desabilitar cache (útil para glifos que mudam frequentemente)
  final bool disableCache;

  /// Registrar bounds para detecção de colisões
  final bool trackBounds;

  /// Prioridade de colisão (usado se trackBounds = true)
  final CollisionPriority? collisionPriority;

  const GlyphDrawOptions({
    this.centerHorizontally = false,
    this.centerVertically = false,
    this.alignLeft = false,
    this.alignRight = false,
    this.alignTop = false,
    this.alignBottom = false,
    this.size,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.fallbackGlyph,
    this.disableCache = false,
    this.trackBounds = false,
    this.collisionPriority,
  });

  /// Cria cópia com valores modificados
  GlyphDrawOptions copyWith({
    bool? centerHorizontally,
    bool? centerVertically,
    bool? alignLeft,
    bool? alignRight,
    bool? alignTop,
    bool? alignBottom,
    double? size,
    double? rotation,
    double? scale,
    String? fallbackGlyph,
    bool? disableCache,
    bool? trackBounds,
    CollisionPriority? collisionPriority,
  }) {
    return GlyphDrawOptions(
      centerHorizontally: centerHorizontally ?? this.centerHorizontally,
      centerVertically: centerVertically ?? this.centerVertically,
      alignLeft: alignLeft ?? this.alignLeft,
      alignRight: alignRight ?? this.alignRight,
      alignTop: alignTop ?? this.alignTop,
      alignBottom: alignBottom ?? this.alignBottom,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      fallbackGlyph: fallbackGlyph ?? this.fallbackGlyph,
      disableCache: disableCache ?? this.disableCache,
      trackBounds: trackBounds ?? this.trackBounds,
      collisionPriority: collisionPriority ?? this.collisionPriority,
    );
  }

  /// Opções padrão para cabeças de nota
  static const GlyphDrawOptions noteheadDefault = GlyphDrawOptions(
    centerHorizontally: true,
    centerVertically: true,
    trackBounds: true,
    collisionPriority: CollisionPriority.veryHigh,
  );

  /// Opções padrão para acidentes
  static const GlyphDrawOptions accidentalDefault = GlyphDrawOptions(
    centerHorizontally: true,
    centerVertically: true,
    trackBounds: true,
    collisionPriority: CollisionPriority.veryHigh,
  );

  /// Opções padrão para articulações
  static const GlyphDrawOptions articulationDefault = GlyphDrawOptions(
    centerHorizontally: true,
    centerVertically: true,
  );

  /// Opções padrão para ornamentos
  static const GlyphDrawOptions ornamentDefault = GlyphDrawOptions(
    centerHorizontally: true,
    centerVertically: true,
  );

  /// Opções padrão para pausas
  static const GlyphDrawOptions restDefault = GlyphDrawOptions(
    centerHorizontally: true,
    centerVertically: true,
  );
}
