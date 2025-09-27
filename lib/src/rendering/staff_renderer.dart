// lib/src/rendering/staff_renderer.dart

import 'package:flutter/material.dart';
import '../layout/layout_engine.dart';
import '../music_model/musical_element.dart';
import '../smufl/smufl_metadata_loader.dart';
import '../theme/music_score_theme.dart';
import 'staff_coordinate_system.dart';

/// Renderizador de pauta com posicionamento correto baseado em SMuFL
class StaffRenderer {
  final StaffCoordinateSystem coordinates;
  final SmuflMetadata metadata;
  final MusicScoreTheme theme;

  // Tamanhos baseados nas especificações SMuFL/Bravura
  late final double glyphSize;
  late final double staffLineThickness;
  late final double stemThickness;

  // Cache de posições de claves
  Clef? currentClef;

  StaffRenderer({
    required this.coordinates,
    required this.metadata,
    required this.theme,
  }) {
    // Configuração correta dos tamanhos segundo SMuFL
    glyphSize = coordinates.staffSpace * 4.0; // Tamanho padrão para glifos
    staffLineThickness = coordinates.staffSpace * 0.13; // 13% do staff space
    stemThickness = coordinates.staffSpace * 0.12; // 12% do staff space
  }

  /// Renderiza a pauta completa com todos os elementos
  void renderStaff(Canvas canvas, List<PositionedElement> elements, Size size) {
    // 1. Desenhar linhas da pauta
    _drawStaffLines(canvas, size.width);

    // 2. Resetar clave atual
    currentClef = null;

    // 3. Renderizar elementos em ordem
    for (final positioned in elements) {
      _renderElement(canvas, positioned);
    }
  }

  void _drawStaffLines(Canvas canvas, double width) {
    final paint = Paint()
      ..color = theme.staffLineColor
      ..strokeWidth = staffLineThickness
      ..style = PaintingStyle.stroke;

    // Desenhar 5 linhas da pauta
    for (int line = 1; line <= 5; line++) {
      final y = coordinates.getStaffLineY(line);
      canvas.drawLine(
        Offset(coordinates.staffBaseline.dx, y),
        Offset(width - 20, y), // Margem direita
        paint,
      );
    }
  }

  void _renderElement(Canvas canvas, PositionedElement positioned) {
    final element = positioned.element;
    final basePosition = positioned.position;

    if (element is Clef) {
      currentClef = element; // Atualizar clave atual
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
    } else if (element is Chord) {
      _renderChord(canvas, element, basePosition);
    }
  }

  void _renderClef(Canvas canvas, Clef clef, Offset basePosition) {
    // Posicionamento correto da clave de sol
    // A clave de sol deve ter seu centro na 2ª linha (G4)
    double yOffset = 0;

    if (clef.type == 'g') {
      // Ajuste vertical para alinhar o círculo central com a 2ª linha
      yOffset =
          coordinates.staffSpace *
          1.0; // G4 está 1 staff space acima da linha central
    } else if (clef.type == 'f') {
      // Clave de fá - os dois pontos ficam ao redor da 4ª linha
      yOffset = -coordinates.staffSpace * 1.0;
    }

    _drawGlyph(
      canvas: canvas,
      glyphName: _getClefGlyphName(clef.type),
      position: Offset(basePosition.dx, coordinates.staffBaseline.dy + yOffset),
      size: glyphSize,
      color: theme.clefColor,
      centerVertically: true,
    );
  }

  String _getClefGlyphName(String clefType) {
    switch (clefType) {
      case 'g':
        return 'gClef';
      case 'f':
        return 'fClef';
      case 'c':
        return 'cClef';
      case 'percussion':
        return 'unpitchedPercussionClef1';
      default:
        return 'gClef';
    }
  }

  void _renderKeySignature(
    Canvas canvas,
    KeySignature ks,
    Offset basePosition,
  ) {
    if (ks.count == 0) return;

    final isSharp = ks.count > 0;
    final glyphName = isSharp ? 'accidentalSharp' : 'accidentalFlat';
    final count = ks.count.abs();

    // Posições corretas para sustenidos e bemóis em clave de sol
    final List<double> positions;

    if (currentClef?.type == 'g' || currentClef == null) {
      if (isSharp) {
        // Sustenidos: F#, C#, G#, D#, A#, E#, B#
        positions = const [
          -2.0, // F5 (linha superior)
          0.5, // C5 (espaço)
          -1.5, // G5 (espaço acima)
          1.0, // D5 (linha)
          -1.0, // A5 (linha)
          1.5, // E5 (espaço)
          0.0, // B4 (linha central)
        ];
      } else {
        // Bemóis: Bb, Eb, Ab, Db, Gb, Cb, Fb
        positions = const [
          0.0, // B4 (linha central)
          1.5, // E5 (espaço)
          -0.5, // A4 (espaço)
          1.0, // D5 (linha)
          -1.0, // G4 (linha)
          0.5, // C5 (espaço)
          -1.5, // F4 (espaço)
        ];
      }
    } else {
      // Posições para clave de fá
      positions = List.generate(7, (i) => i * 0.5);
    }

    double currentX = basePosition.dx;
    final spacing = coordinates.staffSpace * 0.8;

    for (int i = 0; i < count && i < positions.length; i++) {
      final y =
          coordinates.staffBaseline.dy -
          (positions[i] * coordinates.staffSpace);

      _drawGlyph(
        canvas: canvas,
        glyphName: glyphName,
        position: Offset(currentX, y),
        size: glyphSize * 0.8,
        color: theme.keySignatureColor,
        centerVertically: true,
      );

      currentX += spacing;
    }
  }

  void _renderTimeSignature(
    Canvas canvas,
    TimeSignature ts,
    Offset basePosition,
  ) {
    final numeratorGlyph = 'timeSig${ts.numerator}';
    final denominatorGlyph = 'timeSig${ts.denominator}';

    // Numerador na linha superior da pauta
    _drawGlyph(
      canvas: canvas,
      glyphName: numeratorGlyph,
      position: Offset(basePosition.dx, coordinates.getStaffLineY(2)),
      size: glyphSize,
      color: theme.timeSignatureColor,
      centerVertically: true,
    );

    // Denominador na linha inferior da pauta
    _drawGlyph(
      canvas: canvas,
      glyphName: denominatorGlyph,
      position: Offset(basePosition.dx, coordinates.getStaffLineY(4)),
      size: glyphSize,
      color: theme.timeSignatureColor,
      centerVertically: true,
    );
  }

  void _renderNote(Canvas canvas, Note note, Offset basePosition) {
    // Calcular posição vertical baseada na altura da nota
    final staffPosition = _calculateStaffPosition(note.pitch);
    final noteY =
        coordinates.staffBaseline.dy -
        (staffPosition * coordinates.staffSpace * 0.5);

    // Desenhar linhas suplementares se necessário
    _drawLedgerLines(canvas, basePosition.dx, staffPosition);

    // Desenhar acidente se presente
    if (note.pitch.accidentalGlyph != null) {
      _renderAccidental(canvas, note, Offset(basePosition.dx, noteY));
    }

    // Desenhar cabeça da nota
    _drawGlyph(
      canvas: canvas,
      glyphName: note.duration.type.glyphName,
      position: Offset(basePosition.dx, noteY),
      size: glyphSize,
      color: theme.noteheadColor,
      centerVertically: true,
    );

    // Desenhar haste se necessário
    if (note.duration.type != DurationType.whole) {
      _renderStem(canvas, note, Offset(basePosition.dx, noteY), staffPosition);
    }

    // Desenhar articulações
    _renderArticulations(
      canvas,
      note,
      Offset(basePosition.dx, noteY),
      staffPosition,
    );
  }

  int _calculateStaffPosition(Pitch pitch) {
    // Calcular posição na pauta (0 = linha central B4 para clave de sol)
    if (currentClef?.type == 'g' || currentClef == null) {
      // Para clave de sol: B4 = 0 (linha central)
      const stepToPosition = {
        'C': 0,
        'D': 1,
        'E': 2,
        'F': 3,
        'G': 4,
        'A': 5,
        'B': 6,
      };

      final basePosition = stepToPosition[pitch.step] ?? 0;
      final octaveOffset = (pitch.octave - 4) * 7;

      // Ajuste para B estar na posição correta
      if (pitch.step == 'B') {
        return octaveOffset;
      } else if (pitch.octave == 5) {
        return basePosition + 7 - 6; // C5 e acima
      } else if (pitch.octave == 4) {
        return basePosition - 6; // Notas abaixo de B4
      } else {
        return basePosition + octaveOffset - 6;
      }
    }

    // Para outras claves
    return 0;
  }

  void _drawLedgerLines(Canvas canvas, double x, int staffPosition) {
    if (!theme.showLedgerLines) return;

    final paint = Paint()
      ..color = theme.staffLineColor
      ..strokeWidth = staffLineThickness;

    final ledgerWidth = coordinates.staffSpace * 1.5;
    final ledgerX1 = x - ledgerWidth * 0.5;
    final ledgerX2 = x + ledgerWidth * 0.5;

    // Linhas suplementares superiores
    if (staffPosition < -4) {
      for (int pos = -6; pos >= staffPosition; pos -= 2) {
        final y =
            coordinates.staffBaseline.dy - (pos * coordinates.staffSpace * 0.5);
        canvas.drawLine(Offset(ledgerX1, y), Offset(ledgerX2, y), paint);
      }
    }

    // Linhas suplementares inferiores
    if (staffPosition > 4) {
      for (int pos = 6; pos <= staffPosition; pos += 2) {
        final y =
            coordinates.staffBaseline.dy - (pos * coordinates.staffSpace * 0.5);
        canvas.drawLine(Offset(ledgerX1, y), Offset(ledgerX2, y), paint);
      }
    }
  }

  void _renderStem(
    Canvas canvas,
    Note note,
    Offset notePosition,
    int staffPosition,
  ) {
    // Determinar direção da haste
    final stemsUp = staffPosition > 0;
    final stemHeight = coordinates.staffSpace * 3.5;

    // Calcular posição X da haste (baseado nas dimensões da Bravura)
    final noteWidth =
        coordinates.staffSpace * 1.18; // Largura oficial da noteheadBlack
    final stemX = stemsUp
        ? notePosition.dx + noteWidth * 1.150 - stemThickness * 1.150
        : notePosition.dx - noteWidth * 0.00000025 + stemThickness * 0.00000025;

    // Calcular posições Y da haste
    final stemStartY = notePosition.dy;
    final stemEndY = stemsUp
        ? stemStartY - stemHeight
        : stemStartY + stemHeight;

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

    // Ajuste de posição para bandeirolas
    final flagOffset = stemsUp ? 0.0 : 0.0;

    _drawGlyph(
      canvas: canvas,
      glyphName: flagGlyph,
      position: Offset(stemEnd.dx, stemEnd.dy + flagOffset),
      size: glyphSize,
      color: theme.stemColor,
      centerVertically: false, // Bandeirolas não devem ser centralizadas
    );
  }

  void _renderAccidental(Canvas canvas, Note note, Offset notePosition) {
    if (note.pitch.accidentalGlyph == null) return;

    final accidentalX = notePosition.dx - coordinates.staffSpace * 1.5;

    _drawGlyph(
      canvas: canvas,
      glyphName: note.pitch.accidentalGlyph!,
      position: Offset(accidentalX, notePosition.dy),
      size: glyphSize * 0.8,
      color: theme.accidentalColor ?? theme.noteheadColor,
      centerVertically: true,
    );
  }

  void _renderArticulations(
    Canvas canvas,
    Note note,
    Offset notePosition,
    int staffPosition,
  ) {
    if (note.articulations.isEmpty) return;

    final isAboveStaff = staffPosition < 0;
    final articulationY = isAboveStaff
        ? notePosition.dy - coordinates.staffSpace * 1.5
        : notePosition.dy + coordinates.staffSpace * 1.5;

    for (final articulation in note.articulations) {
      final glyphName = _getArticulationGlyph(articulation, !isAboveStaff);

      _drawGlyph(
        canvas: canvas,
        glyphName: glyphName,
        position: Offset(notePosition.dx, articulationY),
        size: glyphSize * 0.6,
        color: theme.articulationColor,
        centerVertically: true,
      );
    }
  }

  String _getArticulationGlyph(ArticulationType type, bool above) {
    switch (type) {
      case ArticulationType.staccato:
        return above ? 'articStaccatoAbove' : 'articStaccatoBelow';
      case ArticulationType.accent:
        return above ? 'articAccentAbove' : 'articAccentBelow';
      case ArticulationType.tenuto:
        return above ? 'articTenutoAbove' : 'articTenutoBelow';
    }
  }

  void _renderRest(Canvas canvas, Rest rest, Offset basePosition) {
    String glyphName;
    double yOffset = 0;

    switch (rest.duration.type) {
      case DurationType.whole:
        glyphName = 'restWhole';
        yOffset = -coordinates.staffSpace; // Pausa de semibreve na 4ª linha
        break;
      case DurationType.half:
        glyphName = 'restHalf';
        yOffset = -coordinates.staffSpace * 0.5; // Pausa de mínima na 3ª linha
        break;
      case DurationType.quarter:
        glyphName = 'restQuarter';
        yOffset = 0; // Pausa de semínima centrada
        break;
      case DurationType.eighth:
        glyphName = 'rest8th';
        yOffset = 0;
        break;
      case DurationType.sixteenth:
        glyphName = 'rest16th';
        yOffset = 0;
        break;
    }

    _drawGlyph(
      canvas: canvas,
      glyphName: glyphName,
      position: Offset(basePosition.dx, coordinates.staffBaseline.dy + yOffset),
      size: glyphSize,
      color: theme.restColor,
      centerVertically: true,
    );
  }

  void _renderBarline(Canvas canvas, Offset basePosition) {
    final paint = Paint()
      ..color = theme.barlineColor
      ..strokeWidth = coordinates.staffSpace * 0.16; // Espessura padrão SMuFL

    final topY = coordinates.getStaffLineY(1);
    final bottomY = coordinates.getStaffLineY(5);

    canvas.drawLine(
      Offset(basePosition.dx, topY),
      Offset(basePosition.dx, bottomY),
      paint,
    );
  }

  void _renderChord(Canvas canvas, Chord chord, Offset basePosition) {
    // Ordenar notas por altura
    final sortedNotes = [...chord.notes]
      ..sort(
        (a, b) => _calculateStaffPosition(
          b.pitch,
        ).compareTo(_calculateStaffPosition(a.pitch)),
      );

    // Renderizar cada nota do acorde
    for (final note in sortedNotes) {
      _renderNote(canvas, note, basePosition);
    }
  }

  void _drawGlyph({
    required Canvas canvas,
    required String glyphName,
    required Offset position,
    required double size,
    required Color color,
    bool centerVertically = false,
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
          height: 1.0, // Importante para manter proporções corretas
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Calcular offset para centralização vertical se necessário
    double yOffset = 0;
    if (centerVertically) {
      yOffset = -textPainter.height * 0.5;
    }

    textPainter.paint(canvas, Offset(position.dx, position.dy + yOffset));
  }
}
