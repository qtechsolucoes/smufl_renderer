// lib/src/rendering/renderers/rest_renderer.dart

import 'package:flutter/material.dart';

import '../../music_model/musical_element.dart';
import '../../smufl/smufl_metadata_loader.dart';
import '../../theme/music_score_theme.dart';
import '../staff_coordinate_system.dart';
import 'ornament_renderer.dart';

/// Renderizador especialista para desenhar Pausas.
class RestRenderer {
  final Canvas canvas;
  final StaffCoordinateSystem coordinates;
  final SmuflMetadata metadata;
  final MusicScoreTheme theme;
  final double glyphSize;
  final OrnamentRenderer ornamentRenderer;

  RestRenderer({
    required this.canvas,
    required this.coordinates,
    required this.metadata,
    required this.theme,
    required this.glyphSize,
    required this.ornamentRenderer,
  });

  void render(Rest rest, Offset position) {
    String glyphName;
    double yOffset = 0;

    switch (rest.duration.type) {
      case DurationType.whole:
        glyphName = 'restWhole';
        yOffset = -coordinates.staffSpace; // Pendurada na 4ª linha
        break;
      case DurationType.half:
        glyphName = 'restHalf';
        yOffset = 0; // Sobre a 3ª linha
        break;
      case DurationType.quarter:
        glyphName = 'restQuarter';
        break;
      case DurationType.eighth:
        glyphName = 'rest8th';
        break;
      case DurationType.sixteenth:
        glyphName = 'rest16th';
        break;
      case DurationType.thirtySecond:
        glyphName = 'rest32nd';
        break;
      case DurationType.sixtyFourth:
        glyphName = 'rest64th';
        break;
      default:
        glyphName = 'restQuarter';
    }

    final restPosition = Offset(
      position.dx,
      coordinates.staffBaseline.dy + yOffset,
    );

    _drawGlyph(
      glyphName: glyphName,
      position: restPosition,
      size: glyphSize,
      color: theme.restColor,
      centerVertically: true,
    );

    // Renderiza ornamentos na pausa (ex: fermata)
    if (rest.ornaments.isNotEmpty) {
      // Cria uma "nota fantasma" para passar para o ornamentRenderer
      final placeholderNote = Note(
        pitch: Pitch(step: 'B', octave: 4), // Posição central da pauta
        duration: rest.duration,
        ornaments: rest.ornaments,
      );
      ornamentRenderer.renderForNote(placeholderNote, restPosition, 0);
    }
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
