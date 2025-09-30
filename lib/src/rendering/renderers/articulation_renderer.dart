// lib/src/rendering/renderers/articulation_renderer.dart

import 'package:flutter/material.dart';
import '../../music_model/musical_element.dart';
import '../../smufl/smufl_metadata_loader.dart';
import '../../theme/music_score_theme.dart';
import '../staff_coordinate_system.dart';

class ArticulationRenderer {
  final Canvas canvas;
  final StaffCoordinateSystem coordinates;
  final SmuflMetadata metadata;
  final MusicScoreTheme theme;
  final double glyphSize;

  ArticulationRenderer({
    required this.canvas,
    required this.coordinates,
    required this.metadata,
    required this.theme,
    required this.glyphSize,
  });

  void render(
    List<ArticulationType> articulations,
    Offset notePos,
    int staffPosition,
  ) {
    if (articulations.isEmpty) return;

    final stemUp = staffPosition <= 0;
    final articulationAbove = !stemUp;
    final yOffset = articulationAbove
        ? -coordinates.staffSpace * 1.2
        : coordinates.staffSpace * 1.2;

    for (final articulation in articulations) {
      final glyphName = _getArticulationGlyph(articulation, articulationAbove);
      if (glyphName != null) {
        _drawGlyph(
          glyphName: glyphName,
          position: Offset(notePos.dx, notePos.dy + yOffset),
          size: glyphSize * 0.8,
          color: theme.articulationColor,
        );
      }
    }
  }

  String? _getArticulationGlyph(ArticulationType type, bool above) {
    return switch (type) {
      ArticulationType.staccato => 'augmentationDot',
      ArticulationType.staccatissimo =>
        above ? 'articStaccatissimoAbove' : 'articStaccatissimoBelow',
      ArticulationType.accent =>
        above ? 'articAccentAbove' : 'articAccentBelow',
      ArticulationType.strongAccent || ArticulationType.marcato =>
        above ? 'articMarcatoAbove' : 'articMarcatoBelow',
      ArticulationType.tenuto =>
        above ? 'articTenutoAbove' : 'articTenutoBelow',
      ArticulationType.upBow => 'stringsUpBow',
      ArticulationType.downBow => 'stringsDownBow',
      ArticulationType.harmonics => 'stringsHarmonic',
      ArticulationType.pizzicato => 'pluckedPizzicato',
      _ => null,
    };
  }

  void _drawGlyph({
    required String glyphName,
    required Offset position,
    required double size,
    required Color color,
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
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }
}
