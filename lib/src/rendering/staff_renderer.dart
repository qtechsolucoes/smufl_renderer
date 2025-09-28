// lib/src/rendering/staff_renderer.dart
// VERSÃO CORRIGIDA E ATUALIZADA - Compatível com estrutura existente

import 'package:flutter/material.dart';
import '../layout/layout_engine.dart';
import '../music_model/musical_element.dart';
import '../smufl/smufl_metadata_loader.dart';
import '../theme/music_score_theme.dart';
import 'staff_coordinate_system.dart';

/// Renderizador de pauta com posicionamento correto baseado em SMuFL
/// VERSÃO CORRIGIDA com todas as melhorias
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
    glyphSize = coordinates.staffSpace * 4.0;
    staffLineThickness =
        metadata.getEngravingDefault('staffLineThickness') * 2.5;
    stemThickness = metadata.getEngravingDefault('stemThickness') * 2.5;
  }

  /// Renderiza a pauta completa com todos os elementos
  void renderStaff(Canvas canvas, List<PositionedElement> elements, Size size) {
    // 1. Desenhar linhas da pauta
    _drawStaffLines(canvas, size.width);

    // 2. Resetar clave atual
    currentClef = null;

    // 3. Coletar grupos para processamento
    final beamGroups = _identifyBeamGroups(elements);

    // 4. Renderizar elementos em ordem
    for (final positioned in elements) {
      _renderElement(canvas, positioned);
    }

    // 5. Renderizar beams após elementos individuais
    _renderBeamGroups(canvas, beamGroups, elements);
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
        Offset(width - 20, y),
        paint,
      );
    }
  }

  void _renderElement(Canvas canvas, PositionedElement positioned) {
    final element = positioned.element;
    final basePosition = positioned.position;

    if (element is Clef) {
      currentClef = element;
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
    final glyphName = clef.glyphName;
    double yOffset = 0;

    // CORREÇÃO: Posicionamento baseado no tipo real de clave
    switch (clef.actualClefType) {
      case ClefType.treble:
      case ClefType.treble8va:
      case ClefType.treble8vb:
        // Clave de Sol: espiral na 2ª linha
        yOffset = coordinates.getStaffLineY(2) - coordinates.staffBaseline.dy;
        break;

      case ClefType.bass:
      case ClefType.bass8va:
      case ClefType.bass8vb:
        // Clave de Fá: pontos na 4ª linha
        yOffset = coordinates.getStaffLineY(4) - coordinates.staffBaseline.dy;
        break;

      case ClefType.alto:
        // Clave de Dó: centro na 3ª linha
        yOffset = 0;
        break;

      case ClefType.tenor:
        // Clave de Dó tenor: centro na 4ª linha
        yOffset = coordinates.getStaffLineY(4) - coordinates.staffBaseline.dy;
        break;

      default:
        yOffset = 0;
    }

    _drawGlyph(
      canvas: canvas,
      glyphName: glyphName,
      position: Offset(basePosition.dx, coordinates.staffBaseline.dy + yOffset),
      size: glyphSize,
      color: theme.clefColor,
      centerVertically: true,
    );
  }

  void _renderKeySignature(
    Canvas canvas,
    KeySignature ks,
    Offset basePosition,
  ) {
    if (ks.count == 0 || currentClef == null) return;

    final glyphName = ks.count > 0 ? 'accidentalSharp' : 'accidentalFlat';
    final count = ks.count.abs();

    // CORREÇÃO: Usar posições corretas baseadas na clave
    final positions = _getKeySignaturePositions(
      currentClef!.actualClefType,
      ks.count > 0,
    );

    double currentX = basePosition.dx;
    const spacing = 0.8;

    for (int i = 0; i < count && i < positions.length; i++) {
      final staffPos = positions[i];
      final y =
          coordinates.staffBaseline.dy -
          (staffPos * coordinates.staffSpace * 0.5);

      _drawGlyph(
        canvas: canvas,
        glyphName: glyphName,
        position: Offset(currentX, y),
        size: glyphSize * 0.9,
        color: theme.keySignatureColor,
        centerVertically: true,
      );

      currentX += spacing * coordinates.staffSpace;
    }
  }

  List<int> _getKeySignaturePositions(ClefType clefType, bool isSharp) {
    switch (clefType) {
      case ClefType.treble:
        return isSharp
            ? [6, 3, 7, 4, 1, 5, 2] // F# C# G# D# A# E# B#
            : [2, 5, 1, 4, 0, 3, -1]; // Bb Eb Ab Db Gb Cb Fb

      case ClefType.bass:
        return isSharp ? [4, 1, 5, 2, -1, 3, 0] : [0, 3, -1, 2, -2, 1, -3];

      case ClefType.alto:
        return isSharp ? [5, 2, 6, 3, 0, 4, 1] : [1, 4, 0, 3, -1, 2, -2];

      default:
        return [];
    }
  }

  void _renderTimeSignature(
    Canvas canvas,
    TimeSignature ts,
    Offset basePosition,
  ) {
    // Numerador
    _drawGlyph(
      canvas: canvas,
      glyphName: 'timeSig${ts.numerator}',
      position: Offset(basePosition.dx, coordinates.getStaffLineY(4)),
      size: glyphSize,
      color: theme.timeSignatureColor,
      centerVertically: true,
    );

    // Denominador
    _drawGlyph(
      canvas: canvas,
      glyphName: 'timeSig${ts.denominator}',
      position: Offset(basePosition.dx, coordinates.getStaffLineY(2)),
      size: glyphSize,
      color: theme.timeSignatureColor,
      centerVertically: true,
    );
  }

  void _renderNote(Canvas canvas, Note note, Offset basePosition) {
    // Calcular posição vertical
    final staffPosition = _calculateStaffPosition(note.pitch);
    final noteY =
        coordinates.staffBaseline.dy -
        (staffPosition * coordinates.staffSpace * 0.5);

    // Desenhar linhas suplementares
    _drawLedgerLines(canvas, basePosition.dx, staffPosition);

    // Desenhar acidente
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
      centerHorizontally: true,
    );

    // CORREÇÃO: Desenhar haste corretamente
    if (note.duration.type != DurationType.whole && note.beam == null) {
      _renderStem(
        canvas,
        Offset(basePosition.dx, noteY),
        staffPosition,
        note.duration.type,
      );
    }

    // CORREÇÃO: Articulações independentes
    _renderArticulations(
      canvas,
      note,
      Offset(basePosition.dx, noteY),
      staffPosition,
    );

    // Pontos de aumento
    if (note.duration.dots > 0) {
      _renderAugmentationDots(
        canvas,
        note,
        Offset(basePosition.dx, noteY),
        staffPosition,
      );
    }
  }

  void _renderStem(
    Canvas canvas,
    Offset notePos,
    int staffPosition,
    DurationType duration, {
    double? customStemFactor,
  }) {
    // CORREÇÃO: Direção baseada na posição
    final stemUp = staffPosition <= 0;

    final noteWidth = coordinates.staffSpace * 1.18;
    // Usa o fator customizado ou o padrão 3.5
    final stemHeight = coordinates.staffSpace * (customStemFactor ?? 3.5);

    // CORREÇÃO: Posicionamento X correto
    final stemX = stemUp
        ? notePos.dx + (noteWidth * 0.45)
        : notePos.dx - (noteWidth * 0.45);

    // CORREÇÃO: Posições Y corretas
    final stemStartY = stemUp
        ? notePos.dy + (coordinates.staffSpace * 0.1)
        : notePos.dy - (coordinates.staffSpace * 0.1);

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

    // Bandeirola se necessário
    if (duration.value < 0.25) {
      _renderFlag(canvas, Offset(stemX, stemEndY), duration, stemUp);
    }
  }

  void _renderFlag(
    Canvas canvas,
    Offset stemEnd,
    DurationType duration,
    bool stemUp,
  ) {
    String flagGlyph;

    switch (duration) {
      case DurationType.eighth:
        flagGlyph = stemUp ? 'flag8thUp' : 'flag8thDown';
        break;
      case DurationType.sixteenth:
        flagGlyph = stemUp ? 'flag16thUp' : 'flag16thDown';
        break;
      case DurationType.thirtySecond:
        flagGlyph = stemUp ? 'flag32ndUp' : 'flag32ndDown';
        break;
      case DurationType.sixtyFourth:
        flagGlyph = stemUp ? 'flag64thUp' : 'flag64thDown';
        break;
      default:
        return;
    }
    // Crie um deslocamento vertical.
    // Use um valor pequeno, baseado no staffSpace, para manter a proporção.
    final double yOffset = coordinates.staffSpace * -2; // Ajuste este valor

    // Crie a nova posição aplicando o deslocamento
    final adjustedPosition = Offset(stemEnd.dx, stemEnd.dy + yOffset);

    _drawGlyph(
      canvas: canvas,
      glyphName: flagGlyph,
      position: adjustedPosition,
      size: glyphSize,
      color: theme.stemColor,
      centerVertically: false,
      centerHorizontally: false,
    );
  }

  void _renderArticulations(
    Canvas canvas,
    Note note,
    Offset notePos,
    int staffPosition,
  ) {
    if (note.articulations.isEmpty) return;

    // CORREÇÃO: Articulação independente da haste
    final stemUp = staffPosition <= 0;
    final articulationAbove = !stemUp; // Lado oposto à haste

    final articulationY = articulationAbove
        ? notePos.dy - (coordinates.staffSpace * 0.8)
        : notePos.dy + (coordinates.staffSpace * 0.8);

    for (final articulation in note.articulations) {
      final glyphName = _getArticulationGlyph(articulation, articulationAbove);

      _drawGlyph(
        canvas: canvas,
        glyphName: glyphName,
        position: Offset(notePos.dx, articulationY),
        size: glyphSize * 0.7,
        color: theme.articulationColor,
        centerVertically: true,
        centerHorizontally: true,
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
      case ArticulationType.marcato:
        return above ? 'articMarcatoAbove' : 'articMarcatoBelow';
      default:
        return 'articStaccatoAbove';
    }
  }

  void _renderRest(Canvas canvas, Rest rest, Offset position) {
    String glyphName;
    double yOffset = 0;

    switch (rest.duration.type) {
      case DurationType.whole:
        glyphName = 'restWhole';
        yOffset = -coordinates.staffSpace;
        break;
      case DurationType.half:
        glyphName = 'restHalf';
        yOffset = 0;
        break;
      case DurationType.quarter:
        glyphName = 'restQuarter';
        yOffset = 0;
        break;
      case DurationType.eighth:
        glyphName = 'rest8th';
        yOffset = 0;
        break;
      case DurationType.sixteenth:
        glyphName = 'rest16th';
        yOffset = 0;
        break;
      default:
        glyphName = 'restQuarter';
    }

    _drawGlyph(
      canvas: canvas,
      glyphName: glyphName,
      position: Offset(position.dx, coordinates.staffBaseline.dy + yOffset),
      size: glyphSize,
      color: theme.restColor,
      centerVertically: true,
    );
  }

  void _renderChord(Canvas canvas, Chord chord, Offset basePosition) {
    // Ordenar notas
    final sortedNotes = [...chord.notes]
      ..sort(
        (a, b) => _calculateStaffPosition(
          b.pitch,
        ).compareTo(_calculateStaffPosition(a.pitch)),
      );

    // Calcular posições
    final positions = <int>[];
    for (final note in sortedNotes) {
      positions.add(_calculateStaffPosition(note.pitch));
    }

    // Direção da haste baseada na média
    final avgPos = positions.reduce((a, b) => a + b) / positions.length;
    final stemUp = avgPos <= 0;

    // Renderizar notas com ajuste para segundas
    for (int i = 0; i < sortedNotes.length; i++) {
      final note = sortedNotes[i];
      final staffPos = positions[i];
      final noteY =
          coordinates.staffBaseline.dy -
          (staffPos * coordinates.staffSpace * 0.5);

      double xOffset = 0;
      if (i > 0 && (positions[i - 1] - positions[i]).abs() == 1) {
        xOffset = stemUp
            ? (i % 2 == 1 ? -coordinates.staffSpace * 0.8 : 0)
            : (i % 2 == 1 ? coordinates.staffSpace * 0.8 : 0);
      }

      _drawGlyph(
        canvas: canvas,
        glyphName: note.duration.type.glyphName,
        position: Offset(basePosition.dx + xOffset, noteY),
        size: glyphSize,
        color: theme.noteheadColor,
        centerVertically: true,
        centerHorizontally: true,
      );
    }

    // Renderizar haste única
    if (chord.duration.type != DurationType.whole) {
      final extremePos = stemUp ? positions.last : positions.first;
      final extremeY =
          coordinates.staffBaseline.dy -
          (extremePos * coordinates.staffSpace * 0.5);

      // <<--- MUDANÇA AQUI: Lógica granular para o tamanho da haste
      double stemFactor;
      final noteCount = chord.notes.length;

      if (noteCount >= 5) {
        stemFactor = 6.5; // Para acordes com 5 ou mais notas
      } else if (noteCount == 4) {
        stemFactor = 5.5; // Para acordes com 4 notas
      } else if (noteCount == 3) {
        stemFactor = 4.5; // Para acordes com 3 notas
      } else {
        stemFactor = 3.5; // Padrão para 1 ou 2 notas
      }

      _renderStem(
        canvas,
        Offset(basePosition.dx, extremeY),
        extremePos,
        chord.duration.type,
        customStemFactor: stemFactor,
      );
    }
  }

  void _renderBarline(Canvas canvas, Offset position) {
    final paint = Paint()
      ..color = theme.barlineColor
      ..strokeWidth = metadata.getEngravingDefault('thinBarlineThickness');

    canvas.drawLine(
      Offset(position.dx, coordinates.getStaffLineY(1)),
      Offset(position.dx, coordinates.getStaffLineY(5)),
      paint,
    );
  }

  void _drawLedgerLines(Canvas canvas, double x, int staffPosition) {
    if (!theme.showLedgerLines) return;

    final paint = Paint()
      ..color = theme.staffLineColor
      ..strokeWidth = metadata.getEngravingDefault('legerLineThickness') * 4.0;

    final extension =
        metadata.getEngravingDefault('legerLineExtension') *
        coordinates.staffSpace;
    final noteWidth = coordinates.staffSpace * 1.18;
    final totalWidth = noteWidth + (2 * extension);

    // Linhas superiores
    if (staffPosition < -4) {
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

    // Linhas inferiores
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
    }
  }

  void _renderAugmentationDots(
    Canvas canvas,
    Note note,
    Offset notePos,
    int staffPosition,
  ) {
    final dotX = notePos.dx + (coordinates.staffSpace * 1.2);

    double dotY = notePos.dy;
    if (staffPosition % 2 == 0) {
      // Em linha
      dotY -= coordinates.staffSpace * 0.25;
    }

    for (int i = 0; i < note.duration.dots; i++) {
      final currentDotX = dotX + (i * coordinates.staffSpace * 0.4);

      _drawGlyph(
        canvas: canvas,
        glyphName: 'augmentationDot',
        position: Offset(currentDotX, dotY),
        size: coordinates.staffSpace * 3,
        color: theme.noteheadColor,
        centerVertically: true,
        centerHorizontally: true,
      );
    }
  }

  void _renderAccidental(Canvas canvas, Note note, Offset notePos) {
    final accidentalX = notePos.dx - (coordinates.staffSpace * 1.5);

    _drawGlyph(
      canvas: canvas,
      glyphName: note.pitch.accidentalGlyph!,
      position: Offset(accidentalX, notePos.dy),
      size: glyphSize,
      color: theme.accidentalColor ?? theme.noteheadColor,
      centerVertically: true,
      centerHorizontally: true,
    );
  }

  // CORREÇÃO: Processamento de beams
  Map<int, List<int>> _identifyBeamGroups(List<PositionedElement> elements) {
    final groups = <int, List<int>>{};
    int groupId = 0;

    for (int i = 0; i < elements.length; i++) {
      final element = elements[i].element;

      if (element is Note && element.beam == BeamType.start) {
        final group = <int>[i];

        for (int j = i + 1; j < elements.length; j++) {
          final nextElement = elements[j].element;
          if (nextElement is Note) {
            group.add(j);
            if (nextElement.beam == BeamType.end) break;
          } else {
            break;
          }
        }

        if (group.length >= 2) {
          groups[groupId++] = group;
        }
      }
    }

    return groups;
  }

  void _renderBeamGroups(
    Canvas canvas,
    Map<int, List<int>> groups,
    List<PositionedElement> elements,
  ) {
    for (final group in groups.values) {
      if (group.length < 2) continue;

      final positions = <Offset>[];
      final staffPositions = <int>[];

      for (final index in group) {
        final element = elements[index];
        if (element.element is Note) {
          final note = element.element as Note;
          final staffPos = _calculateStaffPosition(note.pitch);
          final noteY =
              coordinates.staffBaseline.dy -
              (staffPos * coordinates.staffSpace * 0.5);

          positions.add(Offset(element.position.dx, noteY));
          staffPositions.add(staffPos);
        }
      }

      // Calcular direção
      final avgPos =
          staffPositions.reduce((a, b) => a + b) / staffPositions.length;
      final stemUp = avgPos <= 0;

      _renderBeamGroup(canvas, positions, staffPositions, stemUp);
    }
  }

  void _renderBeamGroup(
    Canvas canvas,
    List<Offset> positions,
    List<int> staffPositions,
    bool stemUp,
  ) {
    if (positions.length < 2) return;

    final stemHeight = coordinates.staffSpace * 3.5;
    final beamThickness =
        metadata.getEngravingDefault('beamThickness') * coordinates.staffSpace;

    // Calcular endpoints das hastes
    final stemEndpoints = <Offset>[];
    for (int i = 0; i < positions.length; i++) {
      final noteWidth = coordinates.staffSpace * 1.18;
      final stemX = stemUp
          ? positions[i].dx + (noteWidth * 0.45)
          : positions[i].dx - (noteWidth * 0.45);

      final stemEndY = stemUp
          ? positions[i].dy - stemHeight
          : positions[i].dy + stemHeight;

      stemEndpoints.add(Offset(stemX, stemEndY));
    }

    // Calcular inclinação
    final slope =
        (stemEndpoints.last.dy - stemEndpoints.first.dy) /
        (stemEndpoints.last.dx - stemEndpoints.first.dx);
    final clampedSlope = slope.clamp(-0.15, 0.15);

    // Desenhar hastes
    final stemPaint = Paint()
      ..color = theme.stemColor
      ..strokeWidth = stemThickness;

    for (int i = 0; i < positions.length; i++) {
      final stemX = stemEndpoints[i].dx;
      final beamY =
          stemEndpoints.first.dy +
          (clampedSlope * (stemX - stemEndpoints.first.dx));

      canvas.drawLine(
        Offset(stemX, positions[i].dy),
        Offset(stemX, beamY),
        stemPaint,
      );
    }

    // Desenhar beam
    final beamPaint = Paint()
      ..color = theme.beamColor ?? theme.stemColor
      ..style = PaintingStyle.fill;

    final firstY = stemEndpoints.first.dy;
    final lastY =
        firstY +
        (clampedSlope * (stemEndpoints.last.dx - stemEndpoints.first.dx));

    final path = Path()
      ..moveTo(stemEndpoints.first.dx, firstY)
      ..lineTo(stemEndpoints.last.dx, lastY)
      ..lineTo(stemEndpoints.last.dx, lastY + beamThickness)
      ..lineTo(stemEndpoints.first.dx, firstY + beamThickness)
      ..close();

    canvas.drawPath(path, beamPaint);
  }

  int _calculateStaffPosition(Pitch pitch) {
    if (currentClef == null) return 0;

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

    switch (currentClef!.actualClefType) {
      case ClefType.treble:
        const refStep = 6; // B
        const refOctave = 4;
        return (pitchStep - refStep) + ((pitch.octave - refOctave) * 7);

      case ClefType.bass:
        const refStep = 1; // D
        const refOctave = 3;
        return (pitchStep - refStep) + ((pitch.octave - refOctave) * 7);

      case ClefType.alto:
        const refStep = 0; // C
        const refOctave = 4;
        return (pitchStep - refStep) + ((pitch.octave - refOctave) * 7);

      default:
        return 0;
    }
  }

  void _drawGlyph({
    required Canvas canvas,
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
