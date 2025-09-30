// lib/src/rendering/renderers/chord_renderer.dart

import 'package:flutter/material.dart';

import '../../music_model/musical_element.dart';
import '../../smufl/smufl_metadata_loader.dart';
import '../../theme/music_score_theme.dart';
import '../staff_coordinate_system.dart';
import 'note_renderer.dart';

/// Renderizador especialista em desenhar acordes, incluindo empilhamento de notas,
/// haste única e posicionamento de elementos compartilhados.
class ChordRenderer {
  final Canvas canvas;
  final StaffCoordinateSystem coordinates;
  final SmuflMetadata metadata;
  final MusicScoreTheme theme;
  final double glyphSize;
  final double staffLineThickness;
  final double stemThickness;
  // Dependência do NoteRenderer para reutilizar a lógica da haste
  final NoteRenderer noteRenderer;

  ChordRenderer({
    required this.canvas,
    required this.coordinates,
    required this.metadata,
    required this.theme,
    required this.glyphSize,
    required this.staffLineThickness,
    required this.stemThickness,
    required this.noteRenderer,
  });

  void render(Chord chord, Offset basePosition, Clef currentClef) {
    // Ordena as notas do acorde da mais aguda para a mais grave para facilitar o desenho
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

    // Decide a direção da haste com base na nota mais distante do centro da pauta
    final mostExtremePos = positions.reduce(
      (a, b) => a.abs() > b.abs() ? a : b,
    );
    final stemUp = mostExtremePos > 0;

    // Calcula os deslocamentos horizontais para evitar colisão de cabeças de notas adjacentes
    final Map<int, double> xOffsets = {};
    for (int i = 0; i < sortedNotes.length; i++) {
      xOffsets[i] = 0.0;
      if (i > 0 && (positions[i - 1] - positions[i]).abs() <= 1) {
        if (xOffsets[i - 1] == 0.0) {
          xOffsets[i] = !stemUp
              ? -coordinates.staffSpace * 1.1
              : coordinates.staffSpace * 1.1;
        }
      }
    }

    // Desenha as cabeças de nota
    for (int i = 0; i < sortedNotes.length; i++) {
      final note = sortedNotes[i];
      final staffPos = positions[i];
      final noteY =
          coordinates.staffBaseline.dy -
          (staffPos * coordinates.staffSpace * 0.5);
      final xOffset = xOffsets[i]!;

      _drawLedgerLines(basePosition.dx + xOffset, staffPos);

      if (note.pitch.accidentalGlyph != null) {
        _renderAccidental(note, Offset(basePosition.dx + xOffset, noteY));
      }

      _drawGlyph(
        glyphName: note.duration.type.glyphName,
        position: Offset(basePosition.dx + xOffset, noteY),
        size: glyphSize,
        color: theme.noteheadColor,
        centerVertically: true,
        centerHorizontally: true,
      );
    }

    // Desenha a haste única do acorde
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

      // A haste de um acorde é geralmente mais longa que a de uma nota simples
      double stemFactor = 3.5 + (sortedNotes.length - 1) * 0.5;

      // Reutiliza o método público do NoteRenderer para desenhar a haste e a bandeirola (se houver)
      noteRenderer.renderStemAndFlag(
        Offset(basePosition.dx + stemXOffset, extremeY),
        extremePos,
        chord.duration.type,
        customStemFactor: stemFactor,
      );
    }
  }

  void _renderAccidental(Note note, Offset notePos) {
    final accidentalX = notePos.dx - (coordinates.staffSpace * 1.2);
    _drawGlyph(
      glyphName: note.pitch.accidentalGlyph!,
      position: Offset(accidentalX, notePos.dy),
      size: glyphSize,
      color: theme.accidentalColor ?? theme.noteheadColor,
      centerVertically: true,
      centerHorizontally: true,
    );
  }

  void _drawLedgerLines(double x, int staffPosition) {
    if (!theme.showLedgerLines || staffPosition.abs() <= 4) return;
    final paint = Paint()
      ..color = theme.staffLineColor
      ..strokeWidth = staffLineThickness;
    final noteWidth =
        (metadata.getGlyphBBox('noteheadBlack')?['bBoxNE']?[0] ?? 1.18) *
        coordinates.staffSpace;
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
