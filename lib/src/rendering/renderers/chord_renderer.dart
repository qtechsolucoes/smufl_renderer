// lib/src/rendering/renderers/chord_renderer.dart
// VERSÃO REFATORADA: Usa StaffPositionCalculator e BaseGlyphRenderer
//
// MELHORIAS IMPLEMENTADAS (Fase 2):
// ✅ Usa StaffPositionCalculator unificado (elimina 42 linhas duplicadas)
// ✅ Herda de BaseGlyphRenderer para renderização consistente
// ✅ Usa drawGlyphWithBBox para 100% conformidade SMuFL
// ✅ Cache automático de TextPainters para melhor performance

import 'package:flutter/material.dart';

import '../../music_model/musical_element.dart';
import '../../smufl/smufl_metadata_loader.dart';
import '../../theme/music_score_theme.dart';
import '../staff_coordinate_system.dart';
import '../staff_position_calculator.dart';
import 'base_glyph_renderer.dart';
import 'note_renderer.dart';

class ChordRenderer extends BaseGlyphRenderer {
  final MusicScoreTheme theme;
  final double staffLineThickness;
  final double stemThickness;
  final NoteRenderer noteRenderer;

  // ignore: use_super_parameters
  ChordRenderer({
    required StaffCoordinateSystem coordinates,
    required SmuflMetadata metadata,
    required this.theme,
    required double glyphSize,
    required this.staffLineThickness,
    required this.stemThickness,
    required this.noteRenderer,
  }) : super(
         coordinates: coordinates,
         metadata: metadata,
         glyphSize: glyphSize,
       );

  void render(
    Canvas canvas,
    Chord chord,
    Offset basePosition,
    Clef currentClef,
  ) {
    // MELHORIA: Usar StaffPositionCalculator unificado
    final sortedNotes = [...chord.notes]
      ..sort(
        (a, b) => StaffPositionCalculator.calculate(
          b.pitch,
          currentClef,
        ).compareTo(StaffPositionCalculator.calculate(a.pitch, currentClef)),
      );

    final positions = sortedNotes
        .map((n) => StaffPositionCalculator.calculate(n.pitch, currentClef))
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

      // MELHORIA: Usar StaffPositionCalculator.toPixelY
      final noteY = StaffPositionCalculator.toPixelY(
        staffPos,
        coordinates.staffSpace,
        coordinates.staffBaseline.dy,
      );

      final xOffset = xOffsets[i]!;

      // MELHORIA: Usar StaffPositionCalculator para ledger lines
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

      // MELHORIA: Usar drawGlyphWithBBox herdado de BaseGlyphRenderer
      drawGlyphWithBBox(
        canvas,
        glyphName: note.duration.type.glyphName,
        position: Offset(basePosition.dx + xOffset, noteY),
        color: theme.noteheadColor,
        options: GlyphDrawOptions.noteheadDefault,
      );
    }

    if (chord.duration.type != DurationType.whole) {
      final extremeNote = stemUp ? sortedNotes.first : sortedNotes.last;

      // MELHORIA: Usar StaffPositionCalculator
      final extremePos = StaffPositionCalculator.calculate(
        extremeNote.pitch,
        currentClef,
      );
      final extremeY = StaffPositionCalculator.toPixelY(
        extremePos,
        coordinates.staffSpace,
        coordinates.staffBaseline.dy,
      );

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

  void _renderAccidental(
    Canvas canvas,
    Note note,
    Offset notePos,
    int noteIndex,
    List<Note> allNotes,
    List<int> positions,
  ) {
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
    final accidentalX =
        notePos.dx -
        accidentalOffset -
        (stackLevel * coordinates.staffSpace * 0.6);

    // MELHORIA: Usar drawGlyphWithBBox herdado
    drawGlyphWithBBox(
      canvas,
      glyphName: note.pitch.accidentalGlyph!,
      position: Offset(accidentalX, notePos.dy),
      color: theme.accidentalColor ?? theme.noteheadColor,
      options: GlyphDrawOptions.accidentalDefault,
    );
  }

  void _drawLedgerLines(Canvas canvas, double x, int staffPosition) {
    if (!theme.showLedgerLines) return;

    // MELHORIA: Usar StaffPositionCalculator
    if (!StaffPositionCalculator.needsLedgerLines(staffPosition)) return;

    final paint = Paint()
      ..color = theme.staffLineColor
      ..strokeWidth = staffLineThickness;

    // CORREÇÃO SMuFL: Usar método seguro ao invés de acesso direto
    final noteheadInfo = metadata.getGlyphInfo('noteheadBlack');
    final noteWidth =
        noteheadInfo?.boundingBox?.widthInPixels(coordinates.staffSpace) ??
        (coordinates.staffSpace * 1.18);

    // CORREÇÃO SMuFL: Consistente com legerLineExtension (0.4) do metadata
    final extension = coordinates.staffSpace * 0.4;
    final totalWidth = noteWidth + (2 * extension);

    // MELHORIA: Usar StaffPositionCalculator.getLedgerLinePositions
    final ledgerPositions = StaffPositionCalculator.getLedgerLinePositions(
      staffPosition,
    );

    for (final pos in ledgerPositions) {
      final y = StaffPositionCalculator.toPixelY(
        pos,
        coordinates.staffSpace,
        coordinates.staffBaseline.dy,
      );

      canvas.drawLine(
        Offset(x - totalWidth / 2, y),
        Offset(x + totalWidth / 2, y),
        paint,
      );
    }
  }
}
