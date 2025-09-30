// lib/src/rendering/renderers/ornament_renderer.dart

import 'package:flutter/material.dart';
import '../../music_model/musical_element.dart';
import '../../smufl/smufl_metadata_loader.dart';
import '../../theme/music_score_theme.dart';
import '../staff_coordinate_system.dart';

class OrnamentRenderer {
  final Canvas canvas;
  final StaffCoordinateSystem coordinates;
  final SmuflMetadata metadata;
  final MusicScoreTheme theme;
  final double glyphSize;
  final double staffLineThickness;

  OrnamentRenderer({
    required this.canvas,
    required this.coordinates,
    required this.metadata,
    required this.theme,
    required this.glyphSize,
    required this.staffLineThickness,
  });

  void renderForNote(Note note, Offset notePos, int staffPosition) {
    if (note.ornaments.isEmpty) return;
    for (final ornament in note.ornaments) {
      if (_isLineOrnament(ornament.type)) continue;

      if (ornament.type == OrnamentType.arpeggio) {
        _renderArpeggio(notePos, notePos.dy, notePos.dy);
        continue;
      }

      final glyphName = _getOrnamentGlyph(ornament.type);
      if (glyphName == null) continue;

      bool ornamentAbove = _isOrnamentAbove(note, ornament);

      final ornamentY = _calculateOrnamentY(
        notePos.dy,
        ornamentAbove,
        staffPosition,
      );
      final ornamentX = _getOrnamentHorizontalPosition(note, notePos.dx);

      _drawGlyph(
        glyphName: glyphName,
        position: Offset(ornamentX, ornamentY),
        size: glyphSize * 0.9,
        color: theme.ornamentColor ?? theme.noteheadColor,
      );
    }
  }

  void renderForChord(
    Chord chord,
    Offset chordPos,
    int highestPos,
    int lowestPos,
  ) {
    if (chord.ornaments.isEmpty) return;
    final highestY =
        coordinates.staffBaseline.dy -
        (highestPos * coordinates.staffSpace * 0.5);
    final lowestY =
        coordinates.staffBaseline.dy -
        (lowestPos * coordinates.staffSpace * 0.5);

    for (final ornament in chord.ornaments) {
      if (ornament.type == OrnamentType.arpeggio) {
        _renderArpeggio(chordPos, lowestY, highestY);
        continue;
      }

      final glyphName = _getOrnamentGlyph(ornament.type);
      if (glyphName == null) continue;

      final ornamentY = _calculateOrnamentY(highestY, true, highestPos);
      _drawGlyph(
        glyphName: glyphName,
        position: Offset(chordPos.dx, ornamentY),
        size: glyphSize * 0.9,
        color: theme.ornamentColor ?? theme.noteheadColor,
      );
    }
  }

  bool _isOrnamentAbove(Note note, Ornament ornament) {
    if (ornament.type == OrnamentType.fermata) return true;
    if (ornament.type == OrnamentType.fermataBelow) return false;

    if (note.voice == null) {
      return ornament.above;
    } else {
      return (note.voice != 2);
    }
  }

  bool _isLineOrnament(OrnamentType type) {
    return type == OrnamentType.glissando || type == OrnamentType.portamento;
  }

  void _renderArpeggio(Offset chordPos, double bottomY, double topY) {
    final arpeggioX = chordPos.dx - (coordinates.staffSpace * 1.2);
    final arpeggioHeight = (bottomY - topY).abs() + coordinates.staffSpace;
    final startY = topY - (coordinates.staffSpace * 0.5);
    final paint = Paint()
      ..color = theme.ornamentColor ?? theme.noteheadColor
      ..strokeWidth = staffLineThickness * 0.8
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(arpeggioX - coordinates.staffSpace * 0.2, startY);
    final segments = (arpeggioHeight / (coordinates.staffSpace * 0.5))
        .clamp(3, 8)
        .toInt();
    for (var i = 0; i <= segments; i++) {
      final y = startY + (i / segments) * arpeggioHeight;
      final x =
          arpeggioX + (i % 2 == 0 ? -1 : 1) * coordinates.staffSpace * 0.2;
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  double _calculateOrnamentY(
    double noteY,
    bool ornamentAbove,
    int staffPosition,
  ) {
    final stemUp = staffPosition <= 0;
    final stemHeight = coordinates.staffSpace * 3.5;
    if (ornamentAbove) {
      final line5Y = coordinates.getStaffLineY(5);
      final minOrnamentY = line5Y - (coordinates.staffSpace * 1.5);
      final stemTipY = stemUp ? noteY - stemHeight : noteY;
      if (stemUp && stemTipY < minOrnamentY) {
        return stemTipY - coordinates.staffSpace;
      }
      return minOrnamentY;
    } else {
      final line1Y = coordinates.getStaffLineY(1);
      final maxOrnamentY = line1Y + (coordinates.staffSpace * 1.5);
      final stemTipY = !stemUp ? noteY + stemHeight : noteY;
      if (!stemUp && stemTipY > maxOrnamentY) {
        return stemTipY + coordinates.staffSpace;
      }
      return maxOrnamentY;
    }
  }

  double _getOrnamentHorizontalPosition(Note note, double noteX) {
    double baseX = noteX;
    if (note.pitch.accidentalGlyph != null) {
      baseX += coordinates.staffSpace * 0.5;
    }
    return baseX;
  }

  String? _getOrnamentGlyph(OrnamentType type) {
    // Mapa completo de glifos de ornamentos
    return switch (type) {
      OrnamentType.trill => 'ornamentTrill',
      OrnamentType.mordent => 'ornamentMordent',
      OrnamentType.invertedMordent => 'ornamentMordentInverted',
      OrnamentType.turn => 'ornamentTurn',
      OrnamentType.fermata => 'fermataAbove',
      OrnamentType.fermataBelow => 'fermataBelow',
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
