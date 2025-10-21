// lib/src/rendering/renderers/note_renderer.dart
// VERSÃO REFATORADA: Usa StaffPositionCalculator e BaseGlyphRenderer
//
// MELHORIAS IMPLEMENTADAS:
// ✅ Usa StaffPositionCalculator unificado para cálculo de posições
// ✅ Usa BaseGlyphRenderer.drawGlyphWithBBox para renderização consistente
// ✅ Elimina código duplicado de _calculateStaffPosition
// ✅ Elimina uso de centerVertically/centerHorizontally inconsistente
// ✅ Cache de TextPainters para melhor performance

import 'package:flutter/material.dart';
import '../../music_model/musical_element.dart';
import '../../smufl/smufl_metadata_loader.dart';
import '../../theme/music_score_theme.dart';
import '../smufl_positioning_engine.dart';
import '../staff_coordinate_system.dart';
import '../staff_position_calculator.dart';
import 'articulation_renderer.dart';
import 'base_glyph_renderer.dart';
import 'ornament_renderer.dart';
import 'symbol_and_text_renderer.dart';

class NoteRenderer extends BaseGlyphRenderer {
  final MusicScoreTheme theme;
  final double staffLineThickness;
  final double stemThickness;
  final ArticulationRenderer articulationRenderer;
  final OrnamentRenderer ornamentRenderer;
  final SMuFLPositioningEngine positioningEngine;
  late final SymbolAndTextRenderer symbolAndTextRenderer;

  NoteRenderer({
    required StaffCoordinateSystem coordinates,
    required SmuflMetadata metadata,
    required this.theme,
    required double glyphSize,
    required this.staffLineThickness,
    required this.stemThickness,
    required this.articulationRenderer,
    required this.ornamentRenderer,
    required this.positioningEngine,
  }) : super(
          coordinates: coordinates,
          metadata: metadata,
          glyphSize: glyphSize,
        ) {
    // Inicializar renderizador de símbolos e texto para dinâmicas
    symbolAndTextRenderer = SymbolAndTextRenderer(
      coordinates: coordinates,
      metadata: metadata,
      theme: theme,
      glyphSize: glyphSize,
    );
  }

  void render(Canvas canvas, Note note, Offset basePosition, Clef currentClef) {
    // MELHORIA: Usar StaffPositionCalculator unificado
    final staffPosition = StaffPositionCalculator.calculate(note.pitch, currentClef);

    // Converter posição da pauta para coordenada Y em pixels
    final noteY = StaffPositionCalculator.toPixelY(
      staffPosition,
      coordinates.staffSpace,
      coordinates.staffBaseline.dy,
    );

    // Desenhar linhas suplementares se necessário
    _drawLedgerLines(canvas, basePosition.dx, staffPosition);

    // Desenhar acidente se presente
    if (note.pitch.accidentalGlyph != null) {
      _renderAccidental(canvas, note, Offset(basePosition.dx, noteY), currentClef);
    }

    // MELHORIA: Desenhar cabeça de nota usando BaseGlyphRenderer
    // Usa drawGlyphWithBBox que automaticamente aplica bounding box SMuFL
    final noteheadGlyph = note.duration.type.glyphName;

    drawGlyphWithBBox(
      canvas,
      glyphName: noteheadGlyph,
      position: Offset(basePosition.dx, noteY),
      color: theme.noteheadColor,
      options: GlyphDrawOptions.noteheadDefault,
    );

    // Desenhar haste e bandeirola (se não for semibreve e não tiver beam)
    if (note.duration.type != DurationType.whole && note.beam == null) {
      renderStemAndFlag(
        canvas,
        Offset(basePosition.dx, noteY),
        staffPosition,
        note.duration.type,
      );
    }

    // Renderizar articulações
    articulationRenderer.render(
      canvas,
      note.articulations,
      Offset(basePosition.dx, noteY),
      staffPosition,
    );

    // Renderizar ornamentos
    ornamentRenderer.renderForNote(
      canvas,
      note,
      Offset(basePosition.dx, noteY),
      staffPosition,
    );

    // Renderizar dinâmicas se presente
    if (note.dynamicElement != null) {
      _renderDynamic(canvas, note.dynamicElement!, basePosition, staffPosition);
    }

    // Renderizar pontos de aumentação se presente
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

    // Obter âncora SMuFL da cabeça de nota
    final noteheadGlyph = duration.glyphName;
    final stemAnchor = stemUp
        ? positioningEngine.getStemUpAnchor(noteheadGlyph)
        : positioningEngine.getStemDownAnchor(noteheadGlyph);

    // Converter âncora de staff spaces para pixels
    final stemAnchorPixels = Offset(
      stemAnchor.dx * coordinates.staffSpace,
      stemAnchor.dy * coordinates.staffSpace,
    );

    // Posição inicial da haste
    final stemX = notePos.dx + stemAnchorPixels.dx;
    final stemStartY = notePos.dy + stemAnchorPixels.dy;

    // Calcular comprimento da haste
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

    // Desenhar haste
    final stemPaint = Paint()
      ..color = theme.stemColor
      ..strokeWidth = stemThickness
      ..strokeCap = StrokeCap.butt;

    canvas.drawLine(
      Offset(stemX, stemStartY),
      Offset(stemX, stemEndY),
      stemPaint,
    );

    // Desenhar bandeirola se necessário
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
      // Obter âncora da bandeirola
      final flagAnchor = positioningEngine.getFlagAnchor(flagGlyph);

      // Converter âncora de spaces para pixels
      final flagAnchorPixels = Offset(
        flagAnchor.dx * coordinates.staffSpace,
        flagAnchor.dy * coordinates.staffSpace,
      );

      // Calcular posição da bandeirola
      final flagX = stemEnd.dx - flagAnchorPixels.dx;
      final flagY = stemEnd.dy - flagAnchorPixels.dy;

      // MELHORIA: Usar drawGlyphWithBBox para bandeirolas
      // Bandeirolas não precisam de centralização (já estão ancoradas)
      drawGlyphWithBBox(
        canvas,
        glyphName: flagGlyph,
        position: Offset(flagX, flagY),
        color: theme.stemColor,
        options: const GlyphDrawOptions(), // Sem centralização
      );
    }
  }

  void _renderAccidental(
    Canvas canvas,
    Note note,
    Offset notePos,
    Clef currentClef,
  ) {
    // MELHORIA: Usar StaffPositionCalculator
    final staffPosition = StaffPositionCalculator.calculate(
      note.pitch,
      currentClef,
    );

    // Calcular posição do acidente usando positioning engine
    final accidentalPosition = positioningEngine.calculateAccidentalPosition(
      accidentalGlyph: note.pitch.accidentalGlyph!,
      noteheadGlyph: note.duration.type.glyphName,
      staffPosition: staffPosition.toDouble(),
    );

    // Converter de staff spaces para pixels
    final accidentalX = notePos.dx + (accidentalPosition.dx * coordinates.staffSpace);
    final accidentalY = notePos.dy + (accidentalPosition.dy * coordinates.staffSpace);

    // MELHORIA: Usar drawGlyphWithBBox para acidentes
    drawGlyphWithBBox(
      canvas,
      glyphName: note.pitch.accidentalGlyph!,
      position: Offset(accidentalX, accidentalY),
      color: theme.accidentalColor ?? theme.noteheadColor,
      options: GlyphDrawOptions.accidentalDefault,
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

    // Se nota está em LINHA (staffPosition par), mover ponto para espaço adjacente
    if (staffPosition % 2 == 0) {
      dotY -= coordinates.staffSpace * 0.5;
    }

    for (int i = 0; i < note.duration.dots; i++) {
      final currentDotX = dotX + (i * coordinates.staffSpace * 0.4);

      // MELHORIA: Usar drawGlyphWithBBox para pontos
      drawGlyphWithBBox(
        canvas,
        glyphName: 'augmentationDot',
        position: Offset(currentDotX, dotY),
        color: theme.noteheadColor,
        options: const GlyphDrawOptions(
          centerHorizontally: true,
          centerVertically: true,
          size: null, // Usa glyphSize padrão
          scale: 0.8, // 80% do tamanho normal
        ),
      );
    }
  }

  void _drawLedgerLines(Canvas canvas, double x, int staffPosition) {
    if (!theme.showLedgerLines) return;

    // MELHORIA: Usar StaffPositionCalculator
    if (!StaffPositionCalculator.needsLedgerLines(staffPosition)) return;

    final paint = Paint()
      ..color = theme.staffLineColor
      ..strokeWidth = staffLineThickness;

    // Obter largura da nota do metadata
    final noteheadInfo = metadata.getGlyphInfo('noteheadBlack');
    final noteWidth = noteheadInfo?.boundingBox?.widthInPixels(coordinates.staffSpace)
        ?? (coordinates.staffSpace * 1.18);

    // Extensão das linhas suplementares (Bravura: 0.4 staff spaces)
    final extension = coordinates.staffSpace * 0.4;
    final totalWidth = noteWidth + (2 * extension);

    // Obter posições das linhas suplementares
    final ledgerPositions = StaffPositionCalculator.getLedgerLinePositions(staffPosition);

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
