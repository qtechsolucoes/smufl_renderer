// lib/src/rendering/renderers/note_renderer.dart

import 'package:flutter/material.dart';
import '../../music_model/musical_element.dart';
import '../../smufl/smufl_metadata_loader.dart';
import '../../theme/music_score_theme.dart';
import '../smufl_positioning_engine.dart';
import '../staff_coordinate_system.dart';
import 'articulation_renderer.dart';
import 'ornament_renderer.dart';
import 'symbol_and_text_renderer.dart';

class NoteRenderer {
  final StaffCoordinateSystem coordinates;
  final SmuflMetadata metadata;
  final MusicScoreTheme theme;
  final double glyphSize;
  final double staffLineThickness;
  final double stemThickness;
  final ArticulationRenderer articulationRenderer;
  final OrnamentRenderer ornamentRenderer;
  final SMuFLPositioningEngine positioningEngine;
  late final SymbolAndTextRenderer symbolAndTextRenderer;

  NoteRenderer({
    required this.coordinates,
    required this.metadata,
    required this.theme,
    required this.glyphSize,
    required this.staffLineThickness,
    required this.stemThickness,
    required this.articulationRenderer,
    required this.ornamentRenderer,
    required this.positioningEngine,
  }) {
    // Inicializar renderizador de símbolos e texto para dinâmicas
    symbolAndTextRenderer = SymbolAndTextRenderer(
      coordinates: coordinates,
      metadata: metadata,
      theme: theme,
      glyphSize: glyphSize,
    );
  }

  void render(Canvas canvas, Note note, Offset basePosition, Clef currentClef) {
    final staffPosition = _calculateStaffPosition(note.pitch, currentClef);
    final noteY =
        coordinates.staffBaseline.dy -
        (staffPosition * coordinates.staffSpace * 0.5);

    _drawLedgerLines(canvas, basePosition.dx, staffPosition);

    if (note.pitch.accidentalGlyph != null) {
      _renderAccidental(canvas, note, Offset(basePosition.dx, noteY));
    }

    // Desenhar cabeça de nota
    final noteheadGlyph = note.duration.type.glyphName;

    // CORREÇÃO SMuFL: Usar bounding box do metadata para centralização precisa
    // TextPainter.height NÃO corresponde ao bounding box SMuFL
    final noteheadInfo = metadata.getGlyphInfo(noteheadGlyph);
    double noteheadVerticalAdjust = 0;

    if (noteheadInfo != null && noteheadInfo.hasBoundingBox) {
      // Centralizar usando bounding box SMuFL (em staff spaces)
      final bbox = noteheadInfo.boundingBox!;
      noteheadVerticalAdjust = -(bbox.centerY * coordinates.staffSpace);
    }

    _drawGlyph(
      canvas,
      glyphName: noteheadGlyph,
      position: Offset(
        basePosition.dx,
        noteY + noteheadVerticalAdjust,
      ),
      size: glyphSize,
      color: theme.noteheadColor,
      centerVertically: false, // Usar apenas bounding box SMuFL
      centerHorizontally: true,
    );

    if (note.duration.type != DurationType.whole && note.beam == null) {
      renderStemAndFlag(
        canvas,
        // CORREÇÃO: Passar a posição DA CABEÇA renderizada (com ajuste SMuFL)
        // porque os anchors são relativos à posição do glyph desenhado
        Offset(basePosition.dx, noteY + noteheadVerticalAdjust),
        staffPosition,
        note.duration.type,
      );
    }

    articulationRenderer.render(
      canvas,
      note.articulations,
      Offset(basePosition.dx, noteY),
      staffPosition,
    );
    ornamentRenderer.renderForNote(
      canvas,
      note,
      Offset(basePosition.dx, noteY),
      staffPosition,
    );

    // CORREÇÃO: Restaurar renderização de dinâmicas nas notas
    if (note.dynamicElement != null) {
      _renderDynamic(canvas, note.dynamicElement!, basePosition, staffPosition);
    }

    if (note.duration.dots > 0) {
      _renderAugmentationDots(
        canvas,
        note,
        Offset(basePosition.dx, noteY),
        staffPosition,
      );
    }
  }

  void renderStemAndFlag(
    Canvas canvas,
    Offset notePos,
    int staffPosition,
    DurationType duration, {
    double? customStemFactor,
  }) {
    final stemUp = staffPosition <= 0;

    // CORREÇÃO SMuFL: Usar âncoras reais da cabeça de nota
    final noteheadGlyph = duration.glyphName;
    final stemAnchor = stemUp
        ? positioningEngine.getStemUpAnchor(noteheadGlyph)
        : positioningEngine.getStemDownAnchor(noteheadGlyph);

    // Converter âncora de spaces para pixels
    final stemAnchorPixels = Offset(
      stemAnchor.dx * coordinates.staffSpace,
      stemAnchor.dy * coordinates.staffSpace,
    );

    // Posição da haste: notePos + âncora
    // notePos já é a posição centralizada da nota
    final stemX = notePos.dx + stemAnchorPixels.dx;
    final stemStartY = notePos.dy + stemAnchorPixels.dy;

    // CORREÇÃO TIPOGRÁFICA: Calcular comprimento usando positioning engine
    final beamCount = _getBeamCount(duration);
    final stemLength = customStemFactor != null
        ? customStemFactor * coordinates.staffSpace
        : positioningEngine.calculateStemLength(
            staffPosition: staffPosition,
            stemUp: stemUp,
            beamCount: beamCount,
            isBeamed: false,
          ) * coordinates.staffSpace;

    final stemEndY = stemUp ? stemStartY - stemLength : stemStartY + stemLength;

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
      _renderFlag(canvas, Offset(stemX, stemEndY), duration, stemUp);
    }
  }

  int _getBeamCount(DurationType duration) {
    return switch (duration) {
      DurationType.eighth => 1,
      DurationType.sixteenth => 2,
      DurationType.thirtySecond => 3,
      DurationType.sixtyFourth => 4,
      _ => 0,
    };
  }

  void _renderFlag(
    Canvas canvas,
    Offset stemEnd,
    DurationType duration,
    bool stemUp,
  ) {
    final flagGlyph = switch (duration) {
      DurationType.eighth => stemUp ? 'flag8thUp' : 'flag8thDown',
      DurationType.sixteenth => stemUp ? 'flag16thUp' : 'flag16thDown',
      DurationType.thirtySecond => stemUp ? 'flag32ndUp' : 'flag32ndDown',
      DurationType.sixtyFourth => stemUp ? 'flag64thUp' : 'flag64thDown',
      _ => null,
    };

    if (flagGlyph != null) {
      // CORREÇÃO SMuFL: Usar âncora da bandeirola para conexão precisa
      // Flags em SMuFL são registradas com y=0 no final de uma haste de 3.5 spaces
      final flagAnchor = positioningEngine.getFlagAnchor(flagGlyph);

      // Converter âncora de spaces para pixels
      final flagAnchorPixels = Offset(
        flagAnchor.dx * coordinates.staffSpace,
        flagAnchor.dy * coordinates.staffSpace,
      );

      // Posição da bandeirola: final da haste menos o offset da âncora
      final flagX = stemEnd.dx - flagAnchorPixels.dx;
      final flagY = stemEnd.dy - flagAnchorPixels.dy;

      _drawGlyph(
        canvas,
        glyphName: flagGlyph,
        position: Offset(flagX, flagY),
        size: glyphSize,
        color: theme.stemColor,
        centerVertically: false,
        centerHorizontally: false,
      );
    }
  }

  void _renderAccidental(Canvas canvas, Note note, Offset notePos) {
    // CORREÇÃO SMuFL: Usar positioning engine para espaçamento correto
    // Baseado em Behind Bars e Ted Ross: 0.16-0.20 spaces da cabeça
    final staffPosition = _calculateStaffPosition(
      note.pitch,
      Clef(clefType: ClefType.treble),
    );

    final accidentalPosition = positioningEngine.calculateAccidentalPosition(
      accidentalGlyph: note.pitch.accidentalGlyph!,
      noteheadGlyph: note.duration.type.glyphName,
      staffPosition: staffPosition.toDouble(),
    );

    // Converter de spaces para pixels
    final accidentalX = notePos.dx + (accidentalPosition.dx * coordinates.staffSpace);
    final accidentalY = notePos.dy + (accidentalPosition.dy * coordinates.staffSpace);

    _drawGlyph(
      canvas,
      glyphName: note.pitch.accidentalGlyph!,
      position: Offset(accidentalX, accidentalY),
      size: glyphSize,
      color: theme.accidentalColor ?? theme.noteheadColor,
      centerVertically: true,
      centerHorizontally: true,
    );
  }

  void _renderAugmentationDots(
    Canvas canvas,
    Note note,
    Offset notePos,
    int staffPosition,
  ) {
    final dotX = notePos.dx + (coordinates.staffSpace * 1.2);
    double dotY = notePos.dy;

    // CORREÇÃO MUSICOLÓGICA: Lógica estava invertida
    // staffPosition % 2 == 0 -> nota em LINHA (precisa mover ponto)
    // staffPosition % 2 != 0 -> nota em ESPAÇO (ponto fica no lugar)
    if (staffPosition % 2 == 0) {
      // Note is on a LINE, move dot up to adjacent space
      dotY -= coordinates.staffSpace * 0.5;
    }

    for (int i = 0; i < note.duration.dots; i++) {
      final currentDotX = dotX + (i * coordinates.staffSpace * 0.4);

      _drawGlyph(
        canvas,
        glyphName: 'augmentationDot',
        position: Offset(currentDotX, dotY),
        // CORREÇÃO CRÍTICA SMuFL: 4.5 * staffSpace é gigantesco!
        // glyphSize já é o tamanho correto (4 * staffSpace)
        size: glyphSize * 0.8, // Ponto ligeiramente menor que nota
        color: theme.noteheadColor,
        centerVertically: true,
        centerHorizontally: true,
      );
    }
  }

  void _drawLedgerLines(Canvas canvas, double x, int staffPosition) {
    if (!theme.showLedgerLines) return;
    // CORREÇÃO MUSICOLÓGICA: Linhas da pauta vão de -4 a +4 (linhas 1-5)
    // Qualquer posição com abs() > 4 precisa de linhas suplementares
    if (staffPosition.abs() <= 4) return;

    final paint = Paint()
      ..color = theme.staffLineColor
      ..strokeWidth = staffLineThickness;

    final noteWidth = coordinates.staffSpace * 1.18;
    // CORREÇÃO SMuFL: Usar legerLineExtension do metadata Bravura (0.4)
    final extension = coordinates.staffSpace * 0.4;
    final totalWidth = noteWidth + (2 * extension);

    if (staffPosition > 5) {
      // Lines above staff
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
      // Lines below staff
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

    switch (clef.actualClefType) {
      case ClefType.treble:
      case ClefType.treble8va:
      case ClefType.treble8vb:
      case ClefType.treble15ma:
      case ClefType.treble15mb:
        const refStep = 6; // B on middle line
        const refOctave = 4;
        final octaveAdjust = pitch.octave + clef.octaveShift - refOctave;
        return (pitchStep - refStep) + (octaveAdjust * 7);

      case ClefType.bass:
      case ClefType.bass8va:
      case ClefType.bass8vb:
      case ClefType.bass15ma:
      case ClefType.bass15mb:
        const refStep = 1; // D on middle line
        const refOctave = 3;
        final octaveAdjust = pitch.octave + clef.octaveShift - refOctave;
        return (pitchStep - refStep) + (octaveAdjust * 7);

      case ClefType.alto:
        const refStep = 0; // C on middle line
        const refOctave = 4;
        final octaveAdjust = pitch.octave + clef.octaveShift - refOctave;
        return (pitchStep - refStep) + (octaveAdjust * 7);

      case ClefType.tenor:
        const refStep = 5; // A on middle line
        const refOctave = 3;
        final octaveAdjust = pitch.octave + clef.octaveShift - refOctave;
        return (pitchStep - refStep) + (octaveAdjust * 7);

      default:
        return 0;
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

  /// Renderizar dinâmica associada à nota
  void _renderDynamic(
    Canvas canvas,
    Dynamic dynamic,
    Offset basePosition,
    int staffPosition,
  ) {
    symbolAndTextRenderer.renderDynamic(canvas, dynamic, basePosition);
  }
}
