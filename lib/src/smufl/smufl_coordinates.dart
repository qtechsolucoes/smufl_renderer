// lib/src/smufl/smufl_coordinates.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Sistema de coordenadas SMuFL (Staff Music Font Layout)
///
/// O SMuFL define um sistema de coordenadas baseado em unidades de staff space.
/// 1 staff space = distância entre duas linhas do pentagrama
/// Valores em metadata são em unidades de 1/4 staff space
class SmuflCoordinates {
  /// Converte unidades SMuFL para pixels
  /// @param smuflUnits Valor em unidades SMuFL (1/4 staff space)
  /// @param staffSpace Tamanho do staff space em pixels
  static double smuflToPixels(double smuflUnits, double staffSpace) {
    return (smuflUnits * staffSpace) / 4.0;
  }

  /// Converte pixels para unidades SMuFL
  /// @param pixels Valor em pixels
  /// @param staffSpace Tamanho do staff space em pixels
  static double pixelsToSmufl(double pixels, double staffSpace) {
    return (pixels * 4.0) / staffSpace;
  }

  /// Calcula o staff space baseado na fonte
  /// @param fontSize Tamanho da fonte em pixels
  static double getStaffSpaceFromFontSize(double fontSize) {
    // No SMuFL, o staff space é 1/4 do tamanho da fonte Bravura
    // Para Bravura, o staff space é exatamente fontSize / 4.0
    return fontSize / 4.0;
  }

  /// Calcula a altura de uma linha do pentagrama
  /// @param staffSpace Tamanho do staff space
  static double getStaffLineThickness(double staffSpace) {
    // Valor oficial do Bravura metadata: 0.13 staff spaces
    return staffSpace * 0.13;
  }

  /// Calcula a espessura de uma haste
  /// @param staffSpace Tamanho do staff space
  static double getStemThickness(double staffSpace) {
    // Valor oficial do Bravura metadata: 0.12 staff spaces
    return staffSpace * 0.12;
  }

  /// Calcula a altura padrão de uma haste
  /// @param staffSpace Tamanho do staff space
  static double getStemHeight(double staffSpace) {
    // Padrão oficial SMuFL: 3.5 staff spaces
    return staffSpace * 3.5;
  }

  /// Calcula a espessura das linhas suplementares
  /// @param staffSpace Tamanho do staff space
  static double getLedgerLineThickness(double staffSpace) {
    // Valor oficial do Bravura metadata: 0.16 staff spaces
    return staffSpace * 0.16;
  }

  /// Calcula a extensão das linhas suplementares
  /// @param staffSpace Tamanho do staff space
  static double getLedgerLineExtension(double staffSpace) {
    // Valor oficial do Bravura metadata: 0.4 staff spaces
    return staffSpace * 0.4;
  }
}

/// Classe para gerenciar bounding boxes de glifos
class GlyphBoundingBox {
  final double bBoxNeX; // Nordeste X
  final double bBoxNeY; // Nordeste Y
  final double bBoxSwX; // Sudoeste X
  final double bBoxSwY; // Sudoeste Y

  const GlyphBoundingBox({
    required this.bBoxNeX,
    required this.bBoxNeY,
    required this.bBoxSwX,
    required this.bBoxSwY,
  });

  /// Cria um bounding box a partir dos dados de metadata SMuFL
  factory GlyphBoundingBox.fromMetadata(Map<String, dynamic> bboxData) {
    final bBoxNE = bboxData['bBoxNE'] as List<dynamic>?;
    final bBoxSW = bboxData['bBoxSW'] as List<dynamic>?;

    return GlyphBoundingBox(
      bBoxNeX: (bBoxNE?[0] as num?)?.toDouble() ?? 0.0,
      bBoxNeY: (bBoxNE?[1] as num?)?.toDouble() ?? 0.0,
      bBoxSwX: (bBoxSW?[0] as num?)?.toDouble() ?? 0.0,
      bBoxSwY: (bBoxSW?[1] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Largura do glifo em unidades SMuFL
  double get width => bBoxNeX - bBoxSwX;

  /// Altura do glifo em unidades SMuFL
  double get height => bBoxNeY - bBoxSwY;

  /// Largura em pixels
  double widthInPixels(double staffSpace) {
    return SmuflCoordinates.smuflToPixels(width, staffSpace);
  }

  /// Altura em pixels
  double heightInPixels(double staffSpace) {
    return SmuflCoordinates.smuflToPixels(height, staffSpace);
  }

  /// Centro X do glifo
  double get centerX => (bBoxNeX + bBoxSwX) / 2;

  /// Centro Y do glifo
  double get centerY => (bBoxNeY + bBoxSwY) / 2;
}

/// Pontos de ancoragem para posicionamento preciso de glifos
class GlyphAnchors {
  final Map<String, Offset> anchors;

  GlyphAnchors(this.anchors);

  /// Cria anchors a partir dos dados de metadata SMuFL
  factory GlyphAnchors.fromMetadata(Map<String, dynamic>? anchorsData) {
    final anchors = <String, Offset>{};

    if (anchorsData != null) {
      for (final entry in anchorsData.entries) {
        final coords = entry.value as List<dynamic>?;
        if (coords != null && coords.length >= 2) {
          anchors[entry.key] = Offset(
            (coords[0] as num).toDouble(),
            (coords[1] as num).toDouble(),
          );
        }
      }
    }

    return GlyphAnchors(anchors);
  }

  /// Obtém um ponto de ancoragem específico
  Offset? getAnchor(String anchorName) => anchors[anchorName];

  /// Converte um anchor para pixels
  Offset? getAnchorInPixels(String anchorName, double staffSpace) {
    final anchor = getAnchor(anchorName);
    if (anchor == null) return null;

    return Offset(
      SmuflCoordinates.smuflToPixels(anchor.dx, staffSpace),
      SmuflCoordinates.smuflToPixels(anchor.dy, staffSpace),
    );
  }

  /// Anchors comuns para diferentes tipos de glifos
  static const Map<String, List<String>> commonAnchors = {
    'noteheads': ['stemUpSE', 'stemDownNW', 'opticalCenter'],
    'clefs': ['opticalCenter'],
    'accidentals': ['opticalCenter'],
    'articulations': ['opticalCenter'],
    'dynamics': ['opticalCenter'],
    'ornaments': ['opticalCenter'],
  };
}

/// Classe para informações completas de um glifo SMuFL
class SmuflGlyphInfo {
  final String name;
  final String codepoint;
  final String description;
  final GlyphBoundingBox? boundingBox;
  final GlyphAnchors? anchors;

  const SmuflGlyphInfo({
    required this.name,
    required this.codepoint,
    required this.description,
    this.boundingBox,
    this.anchors,
  });

  /// Verifica se o glifo tem informações de bounding box
  bool get hasBoundingBox => boundingBox != null;

  /// Verifica se o glifo tem pontos de ancoragem
  bool get hasAnchors => anchors != null && anchors!.anchors.isNotEmpty;
}

/// Utilitários para posicionamento baseado em SMuFL
class SmuflPositioning {
  /// Calcula a posição vertical de uma nota no pentagrama
  /// @param staffPosition Posição na pauta (0 = linha central)
  /// @param staffSpace Tamanho do staff space
  static double noteYPosition(int staffPosition, double staffSpace) {
    return -staffPosition * (staffSpace / 2);
  }

  /// Calcula se uma nota precisa de linhas suplementares
  /// @param staffPosition Posição na pauta
  static bool needsLedgerLines(int staffPosition) {
    return staffPosition.abs() > 4; // Fora das 5 linhas do pentagrama
  }

  /// Calcula as posições das linhas suplementares necessárias
  /// @param staffPosition Posição da nota
  static List<int> getLedgerLinePositions(int staffPosition) {
    final lines = <int>[];

    if (staffPosition > 4) {
      // Linhas acima do pentagrama
      for (int line = 6; line <= staffPosition; line += 2) {
        lines.add(line);
      }
    } else if (staffPosition < -4) {
      // Linhas abaixo do pentagrama
      for (int line = -6; line >= staffPosition; line -= 2) {
        lines.add(line);
      }
    }

    return lines;
  }

  /// Calcula o espaçamento horizontal entre elementos
  /// @param elementType Tipo de elemento musical
  /// @param staffSpace Tamanho do staff space
  static double getElementSpacing(String elementType, double staffSpace) {
    const spacingRatios = {
      'clef': 1.5,
      'keySignature': 0.8,
      'timeSignature': 1.0,
      'note': 1.0,
      'rest': 1.0,
      'barline': 0.5,
    };

    final ratio = spacingRatios[elementType] ?? 1.0;
    return staffSpace * ratio;
  }

  /// Calcula a rotação necessária para um glifo
  /// @param angle Ângulo em graus
  static Matrix4 getRotationMatrix(double angle) {
    final radians = angle * (math.pi / 180);
    return Matrix4.identity()..rotateZ(radians);
  }

  /// Calcula a escala necessária para um glifo
  /// @param scaleX Escala horizontal
  /// @param scaleY Escala vertical
  static Matrix4 getScaleMatrix(double scaleX, double scaleY) {
    return Matrix4.identity()..scale(scaleX, scaleY);
  }
}

/// Extensão para facilitar conversões
extension OffsetSmuflExtension on Offset {
  /// Converte um Offset de unidades SMuFL para pixels
  Offset toPixels(double staffSpace) {
    return Offset(
      SmuflCoordinates.smuflToPixels(dx, staffSpace),
      SmuflCoordinates.smuflToPixels(dy, staffSpace),
    );
  }

  /// Converte um Offset de pixels para unidades SMuFL
  Offset toSmufl(double staffSpace) {
    return Offset(
      SmuflCoordinates.pixelsToSmufl(dx, staffSpace),
      SmuflCoordinates.pixelsToSmufl(dy, staffSpace),
    );
  }
}