// lib/src/rendering/renderers/ornament_renderer.dart

import 'package:flutter/material.dart';
import '../../music_model/musical_element.dart';
import '../../smufl/smufl_metadata_loader.dart';
import '../../theme/music_score_theme.dart';
import '../staff_coordinate_system.dart';

class OrnamentRenderer {
  final StaffCoordinateSystem coordinates;
  final SmuflMetadata metadata;
  final MusicScoreTheme theme;
  final double glyphSize;
  final double staffLineThickness;

  OrnamentRenderer({
    required this.coordinates,
    required this.metadata,
    required this.theme,
    required this.glyphSize,
    required this.staffLineThickness,
  });

  void renderForNote(
    Canvas canvas,
    Note note,
    Offset notePos,
    int staffPosition,
  ) {
    if (note.ornaments.isEmpty) return;

    for (final ornament in note.ornaments) {
      if (_isLineOrnament(ornament.type)) continue;

      if (ornament.type == OrnamentType.arpeggio) {
        _renderArpeggio(canvas, notePos, notePos.dy, notePos.dy);
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

      // Ornamentos com tamanho proporcional, não reduzidos
      _drawGlyph(
        canvas,
        glyphName: glyphName,
        position: Offset(ornamentX, ornamentY),
        size: glyphSize * 0.85, // Ligeiramente menor mas proporcional
        color: theme.ornamentColor ?? theme.noteheadColor,
      );
    }
  }

  void renderForChord(
    Canvas canvas,
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
        _renderArpeggio(canvas, chordPos, lowestY, highestY);
        continue;
      }

      final glyphName = _getOrnamentGlyph(ornament.type);
      if (glyphName == null) continue;

      final ornamentY = _calculateOrnamentY(highestY, true, highestPos);

      _drawGlyph(
        canvas,
        glyphName: glyphName,
        position: Offset(chordPos.dx, ornamentY),
        size: glyphSize * 0.9,
        color: theme.ornamentColor ?? theme.noteheadColor,
      );
    }
  }

  bool _isOrnamentAbove(Note note, Ornament ornament) {
    // This logic is faithful to the original corrected staff_renderer
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

  void _renderArpeggio(
    Canvas canvas,
    Offset chordPos,
    double bottomY,
    double topY,
  ) {
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
      // CORREÇÃO LACERDA: Ornamentos acima devem ficar bem acima da pauta
      // Mínimo de 1.0 staff space acima da linha superior (5ª linha)
      final line5Y = coordinates.getStaffLineY(5);
      final minOrnamentY = line5Y - (coordinates.staffSpace * 1.0);

      // Se tem haste para cima, ornamento acima da ponta da haste
      if (stemUp) {
        final stemTipY = noteY - stemHeight;
        if (stemTipY < minOrnamentY) {
          return stemTipY - (coordinates.staffSpace * 0.6);
        }
      }
      return minOrnamentY;
    } else {
      // CORREÇÃO LACERDA: Ornamentos abaixo devem ficar bem abaixo da pauta
      // Mínimo de 1.0 staff space abaixo da linha inferior (1ª linha)
      final line1Y = coordinates.getStaffLineY(1);
      final maxOrnamentY = line1Y + (coordinates.staffSpace * 1.0);

      // Se tem haste para baixo, ornamento abaixo da ponta da haste
      if (!stemUp) {
        final stemTipY = noteY + stemHeight;
        if (stemTipY > maxOrnamentY) {
          return stemTipY + (coordinates.staffSpace * 0.6);
        }
      }
      return maxOrnamentY;
    }
  }

  double _getOrnamentHorizontalPosition(Note note, double noteX) {
    double baseX = noteX;
    if (note.pitch.accidentalType != null) {
      baseX += coordinates.staffSpace * 0.8;
    }
    return baseX;
  }

  String? _getOrnamentGlyph(OrnamentType type) {
    const ornamentGlyphs = {
      OrnamentType.trill: 'ornamentTrill',
      OrnamentType.trillFlat: 'ornamentTrillFlat',
      OrnamentType.trillNatural: 'ornamentTrillNatural',
      OrnamentType.trillSharp: 'ornamentTrillSharp',
      OrnamentType.shortTrill: 'ornamentShortTrill',
      OrnamentType.trillLigature: 'ornamentPrecompTrillLowerMordent',
      OrnamentType.mordent: 'ornamentMordent',
      OrnamentType.invertedMordent: 'ornamentMordentInverted',
      OrnamentType.mordentUpperPrefix: 'ornamentPrecompMordentUpperPrefix',
      OrnamentType.mordentLowerPrefix: 'ornamentPrecompMordentLowerPrefix',
      OrnamentType.turn: 'ornamentTurn',
      OrnamentType.turnInverted: 'ornamentTurnInverted',
      OrnamentType.invertedTurn: 'ornamentTurnInverted',
      OrnamentType.turnSlash: 'ornamentTurnSlash',
      OrnamentType.appoggiaturaUp: 'graceNoteAcciaccaturaStemUp',
      OrnamentType.appoggiaturaDown: 'graceNoteAcciaccaturaStemDown',
      OrnamentType.acciaccatura: 'graceNoteAcciaccaturaStemUp',
      OrnamentType.fermata: 'fermataAbove',
      OrnamentType.fermataBelow: 'fermataBelow',
      OrnamentType.fermataBelowInverted: 'fermataBelowInverted',
      OrnamentType.schleifer: 'ornamentSchleifer',
      OrnamentType.haydn: 'ornamentHaydn',
      OrnamentType.shake: 'ornamentShake3',
      OrnamentType.wavyLine: 'ornamentPrecompSlide',
      OrnamentType.zigZagLineNoRightEnd: 'ornamentZigZagLineNoRightEnd',
      OrnamentType.zigZagLineWithRightEnd: 'ornamentZigZagLineWithRightEnd',
      OrnamentType.zigzagLine: 'ornamentZigZagLineWithRightEnd',
      OrnamentType.scoop: 'brassBendUp',
      OrnamentType.fall: 'brassFallMedium',
      OrnamentType.doit: 'brassDoitMedium',
      OrnamentType.plop: 'brassPlop',
      OrnamentType.bend: 'brassBendUp',
      OrnamentType.grace: 'graceNoteAcciaccaturaStemUp',
    };
    return ornamentGlyphs[type];
  }

  void _drawGlyph(
    Canvas canvas, {
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
