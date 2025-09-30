// lib/src/rendering/renderers/bar_element_renderer.dart

import 'package:flutter/material.dart';

import '../../music_model/musical_element.dart';
import '../../smufl/smufl_metadata_loader.dart';
import '../../theme/music_score_theme.dart';
import '../staff_coordinate_system.dart';

/// Renderizador especialista em elementos de compasso como Claves,
/// Armaduras de Clave e Fórmulas de Compasso.
class BarElementRenderer {
  final Canvas canvas;
  final StaffCoordinateSystem coordinates;
  final SmuflMetadata metadata;
  final MusicScoreTheme theme;
  final double glyphSize;

  BarElementRenderer({
    required this.canvas,
    required this.coordinates,
    required this.metadata,
    required this.theme,
    required this.glyphSize,
  });

  void renderClef(Clef clef, Offset basePosition) {
    final glyphName = clef.glyphName;
    double yOffset = 0;

    switch (clef.actualClefType) {
      case ClefType.treble:
      case ClefType.treble8va:
      case ClefType.treble8vb:
      case ClefType.treble15ma:
      case ClefType.treble15mb:
        yOffset = coordinates.getStaffLineY(2) - coordinates.staffBaseline.dy;
        break;
      case ClefType.bass:
      case ClefType.bass8va:
      case ClefType.bass8vb:
      case ClefType.bass15ma:
      case ClefType.bass15mb:
        yOffset = coordinates.getStaffLineY(4) - coordinates.staffBaseline.dy;
        break;
      case ClefType.alto:
        yOffset = 0;
        break;
      case ClefType.tenor:
        yOffset = coordinates.getStaffLineY(4) - coordinates.staffBaseline.dy;
        break;
      default:
        yOffset = 0;
    }

    _drawGlyph(
      glyphName: glyphName,
      position: Offset(basePosition.dx, coordinates.staffBaseline.dy + yOffset),
      size: glyphSize,
      color: theme.clefColor,
      centerVertically: true,
    );

    if (clef.octaveShift != 0) {
      _drawOctaveIndication(clef, basePosition);
    }
  }

  void _drawOctaveIndication(Clef clef, Offset position) {
    String octaveText = '';
    double yOffset = 0.0;

    switch (clef.octaveShift.abs()) {
      case 1:
        octaveText = '8';
        break;
      case 2:
        octaveText = '15';
        break;
    }

    if (octaveText.isNotEmpty) {
      yOffset = clef.octaveShift > 0
          ? -coordinates.staffSpace * 3.5
          : coordinates.staffSpace * 3.5;

      final textStyle = TextStyle(
        fontSize: coordinates.staffSpace * 1.2,
        color: theme.clefColor,
        fontWeight: FontWeight.bold,
      );

      _drawText(
        text: octaveText,
        position: Offset(
          position.dx + coordinates.staffSpace,
          coordinates.staffBaseline.dy + yOffset,
        ),
        style: textStyle,
      );
    }
  }

  void renderKeySignature(
    KeySignature ks,
    Clef currentClef,
    Offset basePosition,
  ) {
    if (ks.count == 0) return;

    final glyphName = ks.count > 0 ? 'accidentalSharp' : 'accidentalFlat';
    final count = ks.count.abs();
    final positions = _getKeySignaturePositionsCorrected(
      currentClef.actualClefType,
      ks.count > 0,
    );

    double currentX = basePosition.dx;
    const spacing = 0.8;

    for (int i = 0; i < count && i < positions.length; i++) {
      final staffPos = positions[i];
      final y =
          coordinates.staffBaseline.dy -
          (staffPos * coordinates.staffSpace * 0.5);

      _drawGlyph(
        glyphName: glyphName,
        position: Offset(currentX, y),
        size: glyphSize * 0.9,
        color: theme.keySignatureColor,
        centerVertically: true,
      );

      currentX += spacing * coordinates.staffSpace;
    }
  }

  List<int> _getKeySignaturePositionsCorrected(
    ClefType clefType,
    bool isSharp,
  ) {
    switch (clefType) {
      case ClefType.treble:
      case ClefType.treble8va:
      case ClefType.treble8vb:
      case ClefType.treble15ma:
      case ClefType.treble15mb:
        if (isSharp) return [4, 1, 5, 2, -1, 3, 0];
        return [0, 3, -1, 2, -2, 1, -3];
      case ClefType.bass:
      case ClefType.bass8va:
      case ClefType.bass8vb:
      case ClefType.bass15ma:
      case ClefType.bass15mb:
        if (isSharp) return [2, -1, 3, 0, -3, 1, -2];
        return [-2, 1, -3, 0, -4, -1, -5];
      case ClefType.alto:
        if (isSharp) return [3, 0, 4, 1, -2, 2, -1];
        return [-1, 2, -2, 1, -3, 0, -4];
      case ClefType.tenor:
        if (isSharp) return [1, -2, 2, -1, -4, 0, -3];
        return [0, -3, -1, -4, -2, -5, -3];
      default:
        if (isSharp) return [4, 1, 5, 2, -1, 3, 0];
        return [0, 3, -1, 2, -2, 1, -3];
    }
  }

  void renderTimeSignature(TimeSignature ts, Offset basePosition) {
    if (ts.numerator == 4 &&
        ts.denominator == 4 &&
        metadata.hasGlyph('timeSigCommon')) {
      _drawGlyph(
        glyphName: 'timeSigCommon',
        position: Offset(basePosition.dx, coordinates.staffBaseline.dy),
        size: glyphSize,
        color: theme.timeSignatureColor,
        centerVertically: true,
      );
      return;
    }
    if (ts.numerator == 2 &&
        ts.denominator == 2 &&
        metadata.hasGlyph('timeSigCutCommon')) {
      _drawGlyph(
        glyphName: 'timeSigCutCommon',
        position: Offset(basePosition.dx, coordinates.staffBaseline.dy),
        size: glyphSize,
        color: theme.timeSignatureColor,
        centerVertically: true,
      );
      return;
    }

    _drawGlyph(
      glyphName: 'timeSig${ts.numerator}',
      position: Offset(basePosition.dx, coordinates.getStaffLineY(4)),
      size: glyphSize,
      color: theme.timeSignatureColor,
      centerVertically: true,
    );
    _drawGlyph(
      glyphName: 'timeSig${ts.denominator}',
      position: Offset(basePosition.dx, coordinates.getStaffLineY(2)),
      size: glyphSize,
      color: theme.timeSignatureColor,
      centerVertically: true,
    );
  }

  void _drawText({
    required String text,
    required Offset position,
    required TextStyle style,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - (textPainter.width * 0.5),
        position.dy - (textPainter.height * 0.5),
      ),
    );
  }

  void _drawGlyph({
    required String glyphName,
    required Offset position,
    required double size,
    required Color color,
    bool centerVertically = false,
    bool centerHorizontally = false,
  }) {
    final character = metadata.getCodepoint(glyphName);
    if (character.isEmpty) return;
    final textPainter = TextPainter(
      text: TextSpan(
        text: character,
        style: TextStyle(
          fontFamily: 'Bravura',
          fontSize: size,
          color: color,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    double yOffset = centerVertically ? -textPainter.height * 0.5 : 0;
    double xOffset = centerHorizontally ? -textPainter.width * 0.5 : 0;
    textPainter.paint(
      canvas,
      Offset(position.dx + xOffset, position.dy + yOffset),
    );
  }
}
