// lib/src/rendering/renderers/barline_renderer.dart

import 'package:flutter/material.dart';

import '../../music_model/musical_element.dart';
import '../../smufl/smufl_metadata_loader.dart';
import '../../theme/music_score_theme.dart';
import '../staff_coordinate_system.dart';

/// Renderizador especialista para desenhar Barras de Compasso.
class BarlineRenderer {
  final Canvas canvas;
  final StaffCoordinateSystem coordinates;
  final SmuflMetadata metadata;
  final MusicScoreTheme theme;

  BarlineRenderer({
    required this.canvas,
    required this.coordinates,
    required this.metadata,
    required this.theme,
  });

  void render(Barline barline, Offset position) {
    final paint = Paint()
      ..color = theme.barlineColor
      ..strokeWidth = metadata.getEngravingDefault('thinBarlineThickness');

    canvas.drawLine(
      Offset(position.dx, coordinates.getStaffLineY(1)),
      Offset(position.dx, coordinates.getStaffLineY(5)),
      paint,
    );
  }
}
