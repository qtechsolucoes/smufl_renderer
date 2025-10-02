// lib/src/rendering/renderers/rest_renderer.dart

import 'package:flutter/material.dart';
import '../../music_model/musical_element.dart';
import '../../smufl/smufl_metadata_loader.dart';
import '../../theme/music_score_theme.dart';
import '../staff_coordinate_system.dart';
import 'ornament_renderer.dart';

class RestRenderer {
  final StaffCoordinateSystem coordinates;
  final SmuflMetadata metadata;
  final MusicScoreTheme theme;
  final double glyphSize;
  final OrnamentRenderer ornamentRenderer;

  RestRenderer({
    required this.coordinates,
    required this.metadata,
    required this.theme,
    required this.glyphSize,
    required this.ornamentRenderer,
  });

  void render(Canvas canvas, Rest rest, Offset position) {
    String glyphName;
    // CORREÇÃO: Usar staffPosition relativo ao centro da pauta
    // staffPosition 0 = linha do meio (linha 3)
    // Positive = acima, Negative = abaixo
    int staffPosition;

    switch (rest.duration.type) {
      case DurationType.whole:
        glyphName = 'restWhole';
        // CORREÇÃO MUSICOLÓGICA SMuFL: Pausa de semibreve fica ABAIXO da 4ª linha
        // Posição -2 = um espaço abaixo da linha do meio
        staffPosition = -2;
        break;
      case DurationType.half:
        glyphName = 'restHalf';
        // CORREÇÃO MUSICOLÓGICA SMuFL: Pausa de mínima fica ACIMA da 3ª linha
        // Posição 2 = um espaço acima da linha do meio
        staffPosition = 2;
        break;
      case DurationType.quarter:
        glyphName = 'restQuarter';
        // Pausa de semínima centrada
        staffPosition = 0;
        break;
      case DurationType.eighth:
        glyphName = 'rest8th';
        // Pausas menores centradas
        staffPosition = 0;
        break;
      case DurationType.sixteenth:
        glyphName = 'rest16th';
        staffPosition = 0;
        break;
      case DurationType.thirtySecond:
        glyphName = 'rest32nd';
        staffPosition = 0;
        break;
      case DurationType.sixtyFourth:
        glyphName = 'rest64th';
        staffPosition = 0;
        break;
      default:
        glyphName = 'restQuarter';
        staffPosition = 0;
    }

    // Calcular Y baseado no staff position (mesmo método usado para notas)
    final restY =
        coordinates.staffBaseline.dy -
        (staffPosition * coordinates.staffSpace * 0.5);

    final restPosition = Offset(position.dx, restY);

    // CORREÇÃO DEFINITIVA SMuFL: Usar apenas bounding box center, SEM centerVertically
    // O TextPainter.height não corresponde ao SMuFL bounding box
    final glyphInfo = metadata.getGlyphInfo(glyphName);
    double verticalAdjustment = 0;

    if (glyphInfo != null && glyphInfo.hasBoundingBox) {
      // Usar centro do bounding box SMuFL para alinhamento preciso
      final bbox = glyphInfo.boundingBox!;
      // bbox.centerY está em staff spaces, converter para pixels
      verticalAdjustment = -(bbox.centerY * coordinates.staffSpace);
    }

    _drawGlyph(
      canvas,
      glyphName: glyphName,
      position: Offset(restPosition.dx, restPosition.dy + verticalAdjustment),
      size: glyphSize,
      color: theme.restColor,
      centerVertically: false, // NUNCA usar centerVertically para SMuFL glyphs
      centerHorizontally: true, // Manter centralização horizontal
    );

    if (rest.ornaments.isNotEmpty) {
      final placeholderNote = Note(
        pitch: Pitch(step: 'B', octave: 4), // Posição central da pauta
        duration: rest.duration,
        ornaments: rest.ornaments,
      );
      // CORREÇÃO: Passando o 'canvas' como primeiro argumento.
      ornamentRenderer.renderForNote(canvas, placeholderNote, restPosition, 0);
    }
  }

  void _drawGlyph(
    Canvas canvas, {
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
