// lib/src/rendering/renderers/note_renderer.dart

import 'package:flutter/material.dart';
import '../../music_model/musical_element.dart';
import '../../smufl/smufl_metadata_loader.dart';
import '../../theme/music_score_theme.dart';
import '../staff_coordinate_system.dart';
import 'articulation_renderer.dart';
import 'ornament_renderer.dart';

class NoteRenderer {
  final Canvas canvas;
  final StaffCoordinateSystem coordinates;
  final SmuflMetadata metadata;
  final MusicScoreTheme theme;
  final double glyphSize;
  final double staffLineThickness;
  final double stemThickness;
  final ArticulationRenderer articulationRenderer;
  final OrnamentRenderer ornamentRenderer;

  NoteRenderer({
    required this.canvas,
    required this.coordinates,
    required this.metadata,
    required this.theme,
    required this.glyphSize,
    required this.staffLineThickness,
    required this.stemThickness,
    required this.articulationRenderer,
    required this.ornamentRenderer,
  });

  void render(Note note, Offset basePosition, Clef currentClef) {
    final staffPosition = _calculateStaffPosition(note.pitch, currentClef);
    final noteY =
        coordinates.staffBaseline.dy -
        (staffPosition * coordinates.staffSpace * 0.5);
    _drawLedgerLines(basePosition.dx, staffPosition);
    if (note.pitch.accidentalGlyph != null) {
      _renderAccidental(note, Offset(basePosition.dx, noteY));
    }
    _drawGlyph(
      glyphName: note.duration.type.glyphName,
      position: Offset(basePosition.dx, noteY),
      size: glyphSize,
      color: theme.noteheadColor,
    );
    if (note.duration.type != DurationType.whole && note.beam == null) {
      renderStemAndFlag(
        Offset(basePosition.dx, noteY),
        staffPosition,
        note.duration.type,
      );
    }
    articulationRenderer.render(
      note.articulations,
      Offset(basePosition.dx, noteY),
      staffPosition,
    );
    ornamentRenderer.renderForNote(
      note,
      Offset(basePosition.dx, noteY),
      staffPosition,
    );
    if (note.duration.dots > 0) {
      _renderAugmentationDots(
        note,
        Offset(basePosition.dx, noteY),
        staffPosition,
      );
    }
  }

  void renderStemAndFlag(
    Offset notePos,
    int staffPosition,
    DurationType duration, {
    double? customStemFactor,
  }) {
    final stemUp = staffPosition <= 0;
    final noteWidth =
        (metadata.getGlyphBBox(duration.glyphName)?['bBoxNE']?[0] ?? 1.18) *
        coordinates.staffSpace;
    double stemHeightFactor = 3.5;
    if (customStemFactor == null) {
      stemHeightFactor = switch (duration) {
        DurationType.sixteenth => 3.8,
        DurationType.thirtySecond => 4.2,
        DurationType.sixtyFourth => 4.6,
        _ => 3.5,
      };
    }
    final stemHeight =
        coordinates.staffSpace * (customStemFactor ?? stemHeightFactor);
    final stemX = stemUp
        ? notePos.dx + (noteWidth / 2)
        : notePos.dx - (noteWidth / 2);
    final stemStartY = notePos.dy;
    final stemEndY = stemUp ? stemStartY - stemHeight : stemStartY + stemHeight;
    final stemPaint = Paint()
      ..color = theme.stemColor
      ..strokeWidth = stemThickness
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(
      Offset(stemX, stemStartY),
      Offset(stemX, stemEndY),
      stemPaint,
    );
    if (duration.value < 0.25) {
      _renderFlag(Offset(stemX, stemEndY), duration, stemUp);
    }
  }

  void _renderFlag(Offset stemEnd, DurationType duration, bool stemUp) {
    final flagGlyph = switch (duration) {
      DurationType.eighth => stemUp ? 'flag8thUp' : 'flag8thDown',
      DurationType.sixteenth => stemUp ? 'flag16thUp' : 'flag16thDown',
      DurationType.thirtySecond => stemUp ? 'flag32ndUp' : 'flag32ndDown',
      DurationType.sixtyFourth => stemUp ? 'flag64thUp' : 'flag64thDown',
      _ => null,
    };
    if (flagGlyph != null) {
      _drawGlyph(
        glyphName: flagGlyph,
        position: stemEnd,
        size: glyphSize,
        color: theme.stemColor,
      );
    }
  }

  void _renderAccidental(Note note, Offset notePos) {
    final accidentalX = notePos.dx - (coordinates.staffSpace * 1.0);
    _drawGlyph(
      glyphName: note.pitch.accidentalGlyph!,
      position: Offset(accidentalX, notePos.dy),
      size: glyphSize,
      color: theme.accidentalColor ?? theme.noteheadColor,
    );
  }

  void _renderAugmentationDots(Note note, Offset notePos, int staffPosition) {
    double dotX = notePos.dx + (coordinates.staffSpace * 1.0);
    double dotY = notePos.dy;
    if (staffPosition % 2 != 0) {
      // Se a nota está num espaço
      dotY -= coordinates.staffSpace * 0.5;
    }
    for (int i = 0; i < note.duration.dots; i++) {
      _drawGlyph(
        glyphName: 'augmentationDot',
        position: Offset(dotX, dotY),
        size: glyphSize * 0.5,
        color: theme.noteheadColor,
      );
      dotX += coordinates.staffSpace * 0.7;
    }
  }

  void _drawLedgerLines(double x, int staffPosition) {
    if (!theme.showLedgerLines || staffPosition.abs() <= 5) return;
    final paint = Paint()
      ..color = theme.staffLineColor
      ..strokeWidth = staffLineThickness;
    final noteWidth =
        (metadata.getGlyphBBox('noteheadBlack')?['bBoxNE']?[0] ?? 1.18) *
        coordinates.staffSpace;
    final totalWidth = noteWidth + (coordinates.staffSpace * 0.5);
    if (staffPosition > 5) {
      for (int pos = 6; pos <= staffPosition; pos += 2) {
        final y =
            coordinates.staffBaseline.dy -
            ((pos - 1) * coordinates.staffSpace * 0.5);
        canvas.drawLine(
          Offset(x - totalWidth / 2, y),
          Offset(x + totalWidth / 2, y),
          paint,
        );
      }
    } else {
      for (int pos = -6; pos >= staffPosition; pos -= 2) {
        final y =
            coordinates.staffBaseline.dy -
            ((pos + 1) * coordinates.staffSpace * 0.5);
        canvas.drawLine(
          Offset(x - totalWidth / 2, y),
          Offset(x + totalWidth / 2, y),
          paint,
        );
      }
    }
  }

  int _calculateStaffPosition(Pitch pitch, Clef clef) {
    const stepToDiatonic = {
      'C': 0,
      'D': 1,
      'E': 2,
      'F': 3,
      'G': 4,
      'A': 5,
      'B': 6,
    };
    final pitchStep = stepToDiatonic[pitch.step] ?? 0;
    int baseStep, baseOctave, basePosition;
    switch (clef.actualClefType) {
      case ClefType.treble:
        baseStep = 6;
        baseOctave = 4;
        basePosition = 0;
        break;
      case ClefType.bass:
        baseStep = 1;
        baseOctave = 3;
        basePosition = 0;
        break;
      case ClefType.alto:
        baseStep = 0;
        baseOctave = 4;
        basePosition = 0;
        break;
      case ClefType.tenor:
        baseStep = 5;
        baseOctave = 3;
        basePosition = 0;
        break;
      default:
        return 0;
    }
    int diatonicDistance =
        (pitchStep - baseStep) +
        ((pitch.octave + clef.octaveShift - baseOctave) * 7);
    return basePosition - diatonicDistance;
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
