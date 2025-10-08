// lib/src/rendering/renderers/chord_renderer.dart

import 'package:flutter/material.dart';

import '../../music_model/musical_element.dart';
import '../../smufl/smufl_metadata_loader.dart';
import '../../theme/music_score_theme.dart';
import '../staff_coordinate_system.dart';
import 'note_renderer.dart';

class ChordRenderer {
  final StaffCoordinateSystem coordinates;
  final SmuflMetadata metadata;
  final MusicScoreTheme theme;
  final double glyphSize;
  final double staffLineThickness;
  final double stemThickness;
  final NoteRenderer noteRenderer;

  ChordRenderer({
    required this.coordinates,
    required this.metadata,
    required this.theme,
    required this.glyphSize,
    required this.staffLineThickness,
    required this.stemThickness,
    required this.noteRenderer,
  });

  void render(
    Canvas canvas,
    Chord chord,
    Offset basePosition,
    Clef currentClef,
  ) {
    final sortedNotes = [...chord.notes]
      ..sort(
        (a, b) => _calculateStaffPosition(
          b.pitch,
          currentClef,
        ).compareTo(_calculateStaffPosition(a.pitch, currentClef)),
      );

    final positions = sortedNotes
        .map((n) => _calculateStaffPosition(n.pitch, currentClef))
        .toList();

    final mostExtremePos = positions.reduce(
      (a, b) => a.abs() > b.abs() ? a : b,
    );
    final stemUp = mostExtremePos > 0;

    final Map<int, double> xOffsets = {};
    // CORREÇÃO TIPOGRÁFICA: Usar largura real da cabeça de nota para offset
    final noteheadInfo = metadata.getGlyphInfo('noteheadBlack');
    final noteWidth = noteheadInfo?.boundingBox?.width ?? 1.18;

    for (int i = 0; i < sortedNotes.length; i++) {
      xOffsets[i] = 0.0;
      if (i > 0 && (positions[i - 1] - positions[i]).abs() <= 1) {
        if (xOffsets[i - 1] == 0.0) {
          // Offset baseado na largura real da nota do metadata SMuFL
          xOffsets[i] = !stemUp
              ? -(noteWidth * coordinates.staffSpace)
              : (noteWidth * coordinates.staffSpace);
        }
      }
    }

    for (int i = 0; i < sortedNotes.length; i++) {
      final note = sortedNotes[i];
      final staffPos = positions[i];
      final noteY =
          coordinates.staffBaseline.dy -
          (staffPos * coordinates.staffSpace * 0.5);
      final xOffset = xOffsets[i]!;

      _drawLedgerLines(canvas, basePosition.dx + xOffset, staffPos);

      if (note.pitch.accidentalGlyph != null) {
        // CORREÇÃO: Passar informações adicionais para escalonamento de acidentes
        _renderAccidental(
          canvas,
          note,
          Offset(basePosition.dx + xOffset, noteY),
          i,
          sortedNotes,
          positions,
        );
      }

      _drawGlyph(
        canvas,
        glyphName: note.duration.type.glyphName,
        position: Offset(basePosition.dx + xOffset, noteY),
        size: glyphSize,
        color: theme.noteheadColor,
        centerVertically: true,
        centerHorizontally: true,
      );
    }

    if (chord.duration.type != DurationType.whole) {
      final extremeNote = stemUp ? sortedNotes.first : sortedNotes.last;
      final extremePos = _calculateStaffPosition(
        extremeNote.pitch,
        currentClef,
      );
      final extremeY =
          coordinates.staffBaseline.dy -
          (extremePos * coordinates.staffSpace * 0.5);
      final extremeNoteIndex = sortedNotes.indexOf(extremeNote);
      final stemXOffset = xOffsets[extremeNoteIndex]!;

      double stemFactor = 3.5 + (sortedNotes.length - 1) * 0.5;

      noteRenderer.renderStemAndFlag(
        canvas,
        Offset(basePosition.dx + stemXOffset, extremeY),
        extremePos,
        chord.duration.type,
        customStemFactor: stemFactor,
      );
    }
  }

  void _renderAccidental(Canvas canvas, Note note, Offset notePos, int noteIndex, List<Note> allNotes, List<int> positions) {
    // CORREÇÃO TIPOGRÁFICA: Implementar escalonamento de acidentes em acordes
    // Acidentes de notas adjacentes (intervalo de 2ª) devem ser escalonados horizontalmente
    double accidentalOffset = coordinates.staffSpace * 0.75;

    // Verificar se há notas adjacentes acima ou abaixo com acidentes
    int stackLevel = 0;
    for (int i = 0; i < noteIndex; i++) {
      if (allNotes[i].pitch.accidentalGlyph != null) {
        final positionDiff = (positions[noteIndex] - positions[i]).abs();
        if (positionDiff <= 1) {
          // Notas adjacentes (intervalo de 2ª), escalonar acidente
          stackLevel++;
        }
      }
    }

    // Cada nível adicional move o acidente mais para a esquerda
    final accidentalX = notePos.dx - accidentalOffset - (stackLevel * coordinates.staffSpace * 0.6);

    _drawGlyph(
      canvas,
      glyphName: note.pitch.accidentalGlyph!,
      position: Offset(accidentalX, notePos.dy),
      size: glyphSize,
      color: theme.accidentalColor ?? theme.noteheadColor,
      centerVertically: true,
      centerHorizontally: true,
    );
  }

  void _drawLedgerLines(Canvas canvas, double x, int staffPosition) {
    // CORREÇÃO: Manter consistência com note_renderer (abs() <= 4)
    if (!theme.showLedgerLines || staffPosition.abs() <= 4) return;
    final paint = Paint()
      ..color = theme.staffLineColor
      ..strokeWidth = staffLineThickness;

    // CORREÇÃO SMuFL: Usar método seguro ao invés de acesso direto
    final noteheadInfo = metadata.getGlyphInfo('noteheadBlack');
    final noteWidth = noteheadInfo?.boundingBox?.widthInPixels(coordinates.staffSpace)
        ?? (coordinates.staffSpace * 1.18);

    // CORREÇÃO SMuFL: Consistente com legerLineExtension (0.4) do metadata
    final extension = coordinates.staffSpace * 0.4;
    final totalWidth = noteWidth + (2 * extension);

    if (staffPosition > 4) {
      for (int pos = 6; pos <= staffPosition; pos += 2) {
        final y =
            coordinates.staffBaseline.dy - (pos * coordinates.staffSpace * 0.5);
        canvas.drawLine(
          Offset(x - totalWidth / 2, y),
          Offset(x + totalWidth / 2, y),
          paint,
        );
      }
    } else {
      for (int pos = -6; pos >= staffPosition; pos -= 2) {
        final y =
            coordinates.staffBaseline.dy - (pos * coordinates.staffSpace * 0.5);
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
        baseStep = 4;
        baseOctave = 4;
        basePosition = 2;
        break;
      case ClefType.bass:
        baseStep = 2;
        baseOctave = 3;
        basePosition = -2;
        break;
      case ClefType.alto:
        baseStep = 0;
        baseOctave = 4;
        basePosition = 0;
        break;
      case ClefType.tenor:
        baseStep = 5;
        baseOctave = 3;
        basePosition = -2;
        break;
      default:
        return 0;
    }
    int diatonicDistance =
        (pitchStep - baseStep) +
        ((pitch.octave + clef.octaveShift - baseOctave) * 7);
    return basePosition + diatonicDistance;
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
