// lib/src/rendering/staff_renderer.dart

import 'package:flutter/material.dart';
import '../layout/layout_engine.dart';
import '../music_model/musical_element.dart';
import '../smufl/smufl_metadata_loader.dart';
import '../theme/music_score_theme.dart';
import 'staff_coordinate_system.dart';

/// Renderizador de pauta que usa o sistema de coordenadas correto
class StaffRenderer {
  final StaffCoordinateSystem coordinates;
  final SmuflMetadata metadata;
  final MusicScoreTheme theme;
  final double glyphSize; // Tamanho base para glifos SMuFL

  StaffRenderer({
    required this.coordinates,
    required this.metadata,
    required this.theme,
  }) : glyphSize = coordinates.staffSpace * 4; // Tamanho padrão SMuFL

  /// Renderiza a pauta completa
  void renderStaff(Canvas canvas, List<PositionedElement> elements, Size size) {
    // 1. Desenhar linhas da pauta
    _drawStaffLines(canvas, size.width);

    // 2. Renderizar elementos em ordem
    for (final positioned in elements) {
      _renderElement(canvas, positioned);
    }
  }

  void _drawStaffLines(Canvas canvas, double width) {
    final paint = Paint()
      ..color = theme.staffLineColor
      ..strokeWidth = 0.13 * coordinates.staffSpace // Valor oficial Bravura
      ..style = PaintingStyle.stroke;

    coordinates.drawStaffLines(canvas, width, paint);
  }

  void _renderElement(Canvas canvas, PositionedElement positioned) {
    final element = positioned.element;
    final basePosition = positioned.position;

    if (element is Clef) {
      _renderClef(canvas, element, basePosition);
    } else if (element is KeySignature) {
      _renderKeySignature(canvas, element, basePosition);
    } else if (element is TimeSignature) {
      _renderTimeSignature(canvas, element, basePosition);
    } else if (element is Note) {
      _renderNote(canvas, element, basePosition);
    } else if (element is Rest) {
      _renderRest(canvas, element, basePosition);
    } else if (element is Barline) {
      _renderBarline(canvas, basePosition);
    }
  }

  void _renderClef(Canvas canvas, Clef clef, Offset basePosition) {
    final clefPosition = coordinates.getClefPosition(
      basePosition,
      clef: clef.type,
    );

    _drawGlyph(
      canvas: canvas,
      glyphName: 'gClef',
      position: clefPosition,
      size: glyphSize,
      color: theme.clefColor,
    );
  }

  void _renderKeySignature(
    Canvas canvas,
    KeySignature ks,
    Offset basePosition,
  ) {
    final positions = coordinates.getKeySignaturePositions(ks.count);
    final glyphName = ks.count > 0 ? 'accidentalSharp' : 'accidentalFlat';

    double currentX = basePosition.dx;
    final accidentalSpacing = coordinates.staffSpace * 1.2; // Espaçamento oficial SMuFL

    for (int i = 0; i < positions.length; i++) {
      _drawGlyph(
        canvas: canvas,
        glyphName: glyphName,
        position: Offset(currentX, positions[i]),
        size: glyphSize * 0.9, // Ligeiramente menor que notas
        color: theme.keySignatureColor,
      );
      currentX += accidentalSpacing;
    }
  }

  void _renderTimeSignature(
    Canvas canvas,
    TimeSignature ts,
    Offset basePosition,
  ) {
    final numeratorPos = coordinates.getTimeSignatureNumeratorPosition(
      basePosition,
    );
    final denominatorPos = coordinates.getTimeSignatureDenominatorPosition(
      basePosition,
    );

    final numeratorGlyph = 'timeSig${ts.numerator}';
    final denominatorGlyph = 'timeSig${ts.denominator}';

    _drawGlyph(
      canvas: canvas,
      glyphName: numeratorGlyph,
      position: numeratorPos,
      size: glyphSize * 0.8, // Tamanho apropriado para números
      color: theme.timeSignatureColor,
    );

    _drawGlyph(
      canvas: canvas,
      glyphName: denominatorGlyph,
      position: denominatorPos,
      size: glyphSize * 0.8,
      color: theme.timeSignatureColor,
    );
  }

  void _renderNote(Canvas canvas, Note note, Offset basePosition) {
    final noteY = coordinates.getNoteY(note.pitch.step, note.pitch.octave);
    final notePosition = Offset(basePosition.dx, noteY);

    // Desenhar cabeça da nota
    _drawGlyph(
      canvas: canvas,
      glyphName: note.duration.type.glyphName,
      position: notePosition,
      size: glyphSize,
      color: theme.noteheadColor,
    );

    // Desenhar haste SEMPRE (exceto para nota breve/whole)
    if (note.duration.type != DurationType.whole) {
      _renderStem(canvas, note, notePosition);
    }

    // Desenhar acidentes se presentes
    if (note.pitch.accidentalGlyph != null) {
      _renderAccidental(canvas, note, notePosition);
    }

    // Desenhar articulações
    _renderArticulations(canvas, note, notePosition);
  }

  void _renderStem(Canvas canvas, Note note, Offset notePosition) {
    final noteY = notePosition.dy;
    final staffCenterY = coordinates.staffBaseline.dy;

    // Determinar direção da haste
    final stemsUp = noteY > staffCenterY;
    final stemHeight = coordinates.staffSpace * 3.5; // Padrão SMuFL: 3.5 staff spaces

    // Calcular posições da haste
    final noteWidth = _getGlyphWidth('noteheadBlack');
    final stemX = stemsUp
        ? notePosition.dx + noteWidth * 0.95
        : notePosition.dx + noteWidth * 0.05;

    final stemStartY = noteY;
    final stemEndY = stemsUp ? noteY - stemHeight : noteY + stemHeight;

    // Desenhar haste
    final stemPaint = Paint()
      ..color = theme.stemColor
      ..strokeWidth = 0.12 * coordinates.staffSpace // Valor oficial Bravura
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(stemX, stemStartY),
      Offset(stemX, stemEndY),
      stemPaint,
    );

    // Desenhar bandeirolas se necessário
    if (note.beam == null && note.duration.type.value < 1.0) {
      _renderFlag(canvas, note, Offset(stemX, stemEndY), stemsUp);
    }
  }

  void _renderFlag(Canvas canvas, Note note, Offset stemEnd, bool stemsUp) {
    String flagGlyph;
    if (note.duration.type == DurationType.eighth) {
      flagGlyph = stemsUp ? 'flag8thUp' : 'flag8thDown';
    } else if (note.duration.type == DurationType.sixteenth) {
      flagGlyph = stemsUp ? 'flag16thUp' : 'flag16thDown';
    } else {
      return;
    }

    _drawGlyph(
      canvas: canvas,
      glyphName: flagGlyph,
      position: stemEnd,
      size: glyphSize,
      color: theme.stemColor,
    );
  }

  void _renderAccidental(Canvas canvas, Note note, Offset notePosition) {
    if (note.pitch.accidentalGlyph == null) return;

    final accidentalX = notePosition.dx - coordinates.staffSpace * 1.2;
    final accidentalPosition = Offset(accidentalX, notePosition.dy);

    _drawGlyph(
      canvas: canvas,
      glyphName: note.pitch.accidentalGlyph!,
      position: accidentalPosition,
      size: glyphSize * 0.9,
      color: theme.accidentalColor ?? theme.noteheadColor,
    );
  }

  void _renderArticulations(Canvas canvas, Note note, Offset notePosition) {
    if (note.articulations.isEmpty) return;

    final noteY = notePosition.dy;
    final staffCenterY = coordinates.staffBaseline.dy;
    final isAboveStaff = noteY < staffCenterY;

    final articulationY = isAboveStaff
        ? noteY - coordinates.staffSpace * 1.2
        : noteY + coordinates.staffSpace * 1.2;

    final articulationGlyphs = {
      ArticulationType.staccato: 'articStaccatoAbove',
      ArticulationType.accent: 'articAccentAbove',
      ArticulationType.tenuto: 'articTenutoAbove',
    };

    double currentX = notePosition.dx;
    for (final articulation in note.articulations) {
      final glyphName = articulationGlyphs[articulation];
      if (glyphName != null) {
        _drawGlyph(
          canvas: canvas,
          glyphName: glyphName,
          position: Offset(currentX, articulationY),
          size: glyphSize * 0.7,
          color: theme.articulationColor,
        );
        currentX += coordinates.staffSpace * 0.5;
      }
    }
  }

  void _renderRest(Canvas canvas, Rest rest, Offset basePosition) {
    final restY = coordinates.staffBaseline.dy; // Pausas no centro da pauta
    String glyphName;

    switch (rest.duration.type) {
      case DurationType.whole:
        glyphName = 'restWhole';
        break;
      case DurationType.half:
        glyphName = 'restHalf';
        break;
      case DurationType.quarter:
        glyphName = 'restQuarter';
        break;
      case DurationType.eighth:
        glyphName = 'rest8th';
        break;
      case DurationType.sixteenth:
        glyphName = 'rest16th';
        break;
    }

    _drawGlyph(
      canvas: canvas,
      glyphName: glyphName,
      position: Offset(basePosition.dx, restY),
      size: glyphSize,
      color: theme.restColor,
    );
  }

  void _renderBarline(Canvas canvas, Offset basePosition) {
    final paint = Paint()
      ..color = theme.barlineColor
      ..strokeWidth = 0.16 * coordinates.staffSpace; // Valor oficial Bravura

    final startY = coordinates.getStaffLineY(1);
    final endY = coordinates.getStaffLineY(5);

    canvas.drawLine(
      Offset(basePosition.dx, startY),
      Offset(basePosition.dx, endY),
      paint,
    );
  }

  void _drawGlyph({
    required Canvas canvas,
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
        style: TextStyle(fontFamily: 'Bravura', fontSize: size, color: color),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  double _getGlyphWidth(String glyphName) {
    // Usar dados oficiais do Bravura para larguras precisas
    final Map<String, double> glyphWidths = {
      'noteheadBlack': 1.18, // Valor oficial Bravura
      'gClef': 2.684, // Valor oficial Bravura
      'accidentalSharp': 1.18,
      'accidentalFlat': 1.128,
    };

    final width = glyphWidths[glyphName] ?? 1.18;
    return width * coordinates.staffSpace;
  }
}
