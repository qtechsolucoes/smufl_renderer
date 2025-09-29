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
    } else if (element is Tuplet) {
      _renderTuplet(canvas, element, basePosition);
    } else if (element is RepeatMark) {
      _renderRepeatMark(canvas, element, basePosition);
    }
  }

  void _renderClef(Canvas canvas, Clef clef, Offset basePosition) {
    final glyphName = clef.glyphName;
    double yOffset = 0;

    switch (clef.actualClefType) {
      case ClefType.treble:
      case ClefType.treble8va:
      case ClefType.treble8vb:
        yOffset = coordinates.getStaffLineY(2) - coordinates.staffBaseline.dy;
        break;
      case ClefType.bass:
      case ClefType.bass8va:
      case ClefType.bass8vb:
        yOffset = coordinates.getStaffLineY(4) - coordinates.staffBaseline.dy;
        break;
      case ClefType.alto:
        yOffset = 0;
        break;
      case ClefType.tenor:
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
    // Posições corretas baseadas nas linhas do pentagrama
    // 0 = linha central, positivo = linhas acima, negativo = linhas abaixo

    switch (clefType) {
      case ClefType.treble:
        if (isSharp) {
          // Ordem dos sustenidos: F# C# G# D# A# E# B#
          // Baseado no seu mapeamento detalhado para Clave de Sol:
          // F# → 5ª linha (+4), C# → 3º espaço (+1), G# → espaço acima 5ª linha (+5)
          // D# → 4ª linha (+2), A# → 2º espaço (-1), E# → 4º espaço (+3), B# → 3ª linha (0)
          return [4, 1, 5, 2, -1, 3, 0];
        } else {
          // Ordem dos bemóis: Si♭ Mi♭ Lá♭ Ré♭ Sol♭ Dó♭ Fá♭
          // Baseado exatamente na análise da imagem:
          // Si♭ → 3ª linha (0), Mi♭ → 4º espaço (+3), Lá♭ → 2º espaço (-1)
          // Ré♭ → 4ª linha (+2), Sol♭ → 2ª linha (-2), Dó♭ → 3º espaço (+1), Fá♭ → 1º espaço (-3)
          return [0, 3, -1, 2, -2, 1, -3];
        }

      case ClefType.bass:
        if (isSharp) {
          // Sustenidos para clave de Fá baseado no seu mapeamento detalhado:
          // F# → 4ª linha (+2), C# → 2º espaço (-1), G# → 5ª linha (+4)
          // D# → 3ª linha (0), A# → 1º espaço (-3), E# → 4º espaço (+3), B# → 2ª linha (-2)
          return [2, -1, 4, 0, -3, 3, -2];
        } else {
          // Bemóis para clave de Fá baseados exatamente na análise da imagem:
          // Si♭ → 2ª linha (-2), Mi♭ → 4ª linha (+2), Lá♭ → 1ª linha (-4)
          // Ré♭ → 3ª linha (0), Sol♭ → 5ª linha (+4), Dó♭ → 2º espaço (-1), Fá♭ → 4º espaço (+3)
          return [-2, 2, -4, 0, 4, -1, 3];
        }

      case ClefType.alto:
        if (isSharp) {
          // Sustenidos para clave de Dó alto baseado no seu mapeamento detalhado:
          // F# → 4º espaço (+3), C# → 3ª linha (0), G# → 5ª linha (+4)
          // D# → 2º espaço (-1), A# → 4ª linha (+2), E# → 1º espaço (-3), B# → 3º espaço (+1)
          return [3, 0, 4, -1, 2, -3, 1];
        } else {
          // Bemóis para clave de Dó alto baseados exatamente na análise da imagem:
          // Si♭ → 2º espaço (-1), Mi♭ → 4º espaço (+3), Lá♭ → 1º espaço (-3)
          // Ré♭ → 3º espaço (+1), Sol♭ → 5º espaço (+5), Dó♭ → 2ª linha (-2), Fá♭ → 4ª linha (+2)
          return [-1, 3, -3, 1, 5, -2, 2];
        }

      case ClefType.tenor:
        if (isSharp) {
          // Sustenidos para clave de Dó (tenor):
          // F# = 3ª linha (0), C# = 2º espaço (1), G# = 4ª linha (2)
          // D# = 3º espaço (3), A# = 1ª linha (-4), E# = 3ª linha (0), B# = 2ª linha (-2)
          return [0, 1, 2, 3, -4, 0, -2];
        } else {
          // Bemóis para clave de Dó (tenor):
          // Bb = 2ª linha (-2), Eb = 3ª linha (0), Ab = 1ª linha (-4)
          // Db = 2º espaço (1), Gb = abaixo da pauta (-5), Cb = 2ª linha (-2), Fb = 1º espaço (-3)
          return [-2, 0, -4, 1, -5, -2, -3];
        }

      default:
        // Fallback para clave de Sol (baseado no mapeamento detalhado correto)
        return isSharp ? [4, 1, 5, 2, -1, 3, 0] : [0, 3, -1, 2, -2, 1, -3];
    }
  }

  void _renderTimeSignature(
    Canvas canvas,
    TimeSignature ts,
    Offset basePosition,
  ) {
    _drawGlyph(
      canvas: canvas,
      glyphName: 'timeSig${ts.numerator}',
      position: Offset(basePosition.dx, coordinates.getStaffLineY(4)),
      size: glyphSize,
      color: theme.timeSignatureColor,
      centerVertically: true,
    );
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
    final staffPosition = _calculateStaffPosition(note.pitch);
    final noteY =
        coordinates.staffBaseline.dy -
        (staffPosition * coordinates.staffSpace * 0.5);

    _drawLedgerLines(canvas, basePosition.dx, staffPosition);

    if (note.pitch.accidentalGlyph != null) {
      _renderAccidental(canvas, note, Offset(basePosition.dx, noteY));
    }

    _drawGlyph(
      canvas: canvas,
      glyphName: note.duration.type.glyphName,
      position: Offset(basePosition.dx, noteY),
      size: glyphSize,
      color: theme.noteheadColor,
      centerVertically: true,
      centerHorizontally: true,
    );

    if (note.duration.type != DurationType.whole && note.beam == null) {
      _renderStem(
        canvas,
        Offset(basePosition.dx, noteY),
        staffPosition,
        note.duration.type,
      );
    }

    _renderArticulations(
      canvas,
      note,
      Offset(basePosition.dx, noteY),
      staffPosition,
    );

    // Renderizar ornamentos da nota
    _renderOrnaments(
      canvas,
      note,
      Offset(basePosition.dx, noteY),
      staffPosition,
    );

    // Renderizar dinâmicas da nota
    if (note.dynamicElement != null) {
      _renderDynamic(
        canvas,
        note.dynamicElement!,
        Offset(basePosition.dx, noteY),
        staffPosition,
      );
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

  void _renderStem(
    Canvas canvas,
    Offset notePos,
    int staffPosition,
    DurationType duration, {
    double? customStemFactor,
  }) {
    final stemUp = staffPosition <= 0;
    final noteWidth = coordinates.staffSpace * 1.18;

    // ** ALTERAÇÃO AQUI **
    // Define um fator de altura padrão e o ajusta para durações menores.
    double stemHeightFactor = 3.5;
    switch (duration) {
      case DurationType.thirtySecond:
        stemHeightFactor = 4.0;
        break;
      case DurationType.sixtyFourth:
      case DurationType.oneHundredTwentyEighth:
        stemHeightFactor = 4.5;
        break;
      default:
        break;
    }

    // O fator customizado (para acordes) tem prioridade.
    final finalFactor = customStemFactor ?? stemHeightFactor;
    final stemHeight = coordinates.staffSpace * finalFactor;

    final stemX = stemUp
        ? notePos.dx + (noteWidth * 0.45)
        : notePos.dx - (noteWidth * 0.45);

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
    final double yOffset = coordinates.staffSpace * -2;
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

    final stemUp = staffPosition <= 0;
    final articulationAbove = !stemUp;

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
      case DurationType.thirtySecond:
        glyphName = 'rest32nd';
        break;
      case DurationType.sixtyFourth:
        glyphName = 'rest64th';
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
    final sortedNotes = [...chord.notes]
      ..sort(
        (a, b) => _calculateStaffPosition(
          b.pitch,
        ).compareTo(_calculateStaffPosition(a.pitch)),
      );

    final positions = <int>[];
    for (final note in sortedNotes) {
      positions.add(_calculateStaffPosition(note.pitch));
    }

    final avgPos = positions.reduce((a, b) => a + b) / positions.length;
    final stemUp = avgPos <= 0;

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

    if (chord.duration.type != DurationType.whole) {
      final extremePos = stemUp ? positions.last : positions.first;
      final extremeY =
          coordinates.staffBaseline.dy -
          (extremePos * coordinates.staffSpace * 0.5);

      double stemFactor;
      final noteCount = chord.notes.length;

      if (noteCount >= 5) {
        stemFactor = 6.5;
      } else if (noteCount == 4) {
        stemFactor = 5.5;
      } else if (noteCount == 3) {
        stemFactor = 4.5;
      } else {
        stemFactor = 3.5;
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
      final groupElements = <PositionedElement>[];

      for (final index in group) {
        final element = elements[index];
        groupElements.add(element);
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

      final avgPos =
          staffPositions.reduce((a, b) => a + b) / staffPositions.length;
      final stemUp = avgPos <= 0;

      _renderBeamGroup(
        canvas,
        groupElements,
        positions,
        staffPositions,
        stemUp,
      );
    }
  }

  void _renderBeamGroup(
    Canvas canvas,
    List<PositionedElement> groupElements,
    List<Offset> positions,
    List<int> staffPositions,
    bool stemUp,
  ) {
    if (positions.length < 2) return;

    // ** ALTERAÇÃO AQUI **
    // 1. Descobre o número máximo de barras necessárias para o grupo.
    int maxBeams = 0;
    for (final pElement in groupElements) {
      if (pElement.element is Note) {
        final note = pElement.element as Note;
        final beamsForNote = switch (note.duration.type) {
          DurationType.eighth => 1,
          DurationType.sixteenth => 2,
          DurationType.thirtySecond => 3,
          DurationType.sixtyFourth => 4,
          DurationType.oneHundredTwentyEighth => 4, // SMuFL usa 4 como máximo
          _ => 0,
        };
        if (beamsForNote > maxBeams) {
          maxBeams = beamsForNote;
        }
      }
    }

    // 2. Define a altura da haste com base no número de barras.
    double stemHeightFactor = 3.5;
    if (maxBeams == 3) {
      stemHeightFactor = 4.0;
    } else if (maxBeams >= 4) {
      stemHeightFactor = 4.5;
    }
    final stemHeight = coordinates.staffSpace * stemHeightFactor;

    final beamThickness =
        metadata.getEngravingDefault('beamThickness') * coordinates.staffSpace;
    final beamSpacing = beamThickness * 1.5;

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

    final firstStem = stemEndpoints.first;
    final lastStem = stemEndpoints.last;
    final slope = (lastStem.dy - firstStem.dy) / (lastStem.dx - firstStem.dx);
    final clampedSlope = slope.clamp(-0.2, 0.2);

    double getBeamY(double x) {
      return firstStem.dy + (clampedSlope * (x - firstStem.dx));
    }

    final stemPaint = Paint()
      ..color = theme.stemColor
      ..strokeWidth = stemThickness;
    final beamPaint = Paint()
      ..color = theme.beamColor ?? theme.stemColor
      ..style = PaintingStyle.fill;

    for (int beamIndex = 0; beamIndex < maxBeams; beamIndex++) {
      final yOffset = stemUp
          ? beamIndex * beamSpacing
          : -beamIndex * beamSpacing;

      Path? currentPath;
      int pathStartIndex = -1;

      for (int i = 0; i < groupElements.length; i++) {
        final note = groupElements[i].element as Note;
        final beamsForNote = switch (note.duration.type) {
          DurationType.eighth => 1,
          DurationType.sixteenth => 2,
          DurationType.thirtySecond => 3,
          DurationType.sixtyFourth => 4,
          DurationType.oneHundredTwentyEighth => 4,
          _ => 0,
        };

        if (beamsForNote > beamIndex) {
          if (currentPath == null) {
            currentPath = Path();
            pathStartIndex = i;
          }
        }

        bool isLastNoteInSegment =
            (i == groupElements.length - 1) ||
            (switch ((groupElements[i + 1].element as Note).duration.type) {
                  DurationType.eighth => 1,
                  DurationType.sixteenth => 2,
                  DurationType.thirtySecond => 3,
                  DurationType.sixtyFourth => 4,
                  DurationType.oneHundredTwentyEighth => 4,
                  _ => 0,
                } <=
                beamIndex);

        if (currentPath != null &&
            (i > pathStartIndex ||
                (pathStartIndex == i && groupElements.length == 1) ||
                isLastNoteInSegment)) {
          int endIndex = i;
          if (beamsForNote <= beamIndex && i > 0) {
            endIndex = i - 1;
          }

          if (pathStartIndex <= endIndex) {
            final startX = stemEndpoints[pathStartIndex].dx;
            final endX = stemEndpoints[endIndex].dx;
            final startY = getBeamY(startX) + yOffset;
            final endY = getBeamY(endX) + yOffset;

            final beamDirection = stemUp ? 1.0 : -1.0;

            currentPath.moveTo(startX, startY);
            currentPath.lineTo(endX, endY);
            currentPath.lineTo(endX, endY + beamThickness * beamDirection);
            currentPath.lineTo(startX, startY + beamThickness * beamDirection);
            currentPath.close();

            canvas.drawPath(currentPath, beamPaint);
          }
          currentPath = null;
          pathStartIndex = -1;
        }
      }
    }

    for (int i = 0; i < positions.length; i++) {
      final stemX = stemEndpoints[i].dx;
      final beamY = getBeamY(stemX);
      canvas.drawLine(
        Offset(stemX, positions[i].dy),
        Offset(stemX, beamY),
        stemPaint,
      );
    }
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

  void _renderOrnaments(
    Canvas canvas,
    Note note,
    Offset notePos,
    int staffPosition,
  ) {
    if (note.ornaments.isEmpty) return;

    // Determinar se a nota tem haste para cima ou para baixo
    final stemUp = staffPosition <= 0;

    for (final ornament in note.ornaments) {
      final glyphName = _getOrnamentGlyph(ornament.type);
      if (glyphName == null) continue;

      // Calcular posicionamento baseado nas regras especificadas
      final ornamentAbove = _shouldPlaceOrnamentAbove(ornament.type, staffPosition, stemUp);

      // Calcular distância vertical baseada no tipo de ornamento
      final verticalDistance = _getOrnamentVerticalDistance(ornament.type);

      final ornamentY = ornamentAbove
          ? notePos.dy - (coordinates.staffSpace * verticalDistance)
          : notePos.dy + (coordinates.staffSpace * verticalDistance);

      // Calcular posicionamento horizontal para alguns ornamentos específicos
      final ornamentX = _getOrnamentHorizontalPosition(ornament.type, notePos.dx);

      _drawGlyph(
        canvas: canvas,
        glyphName: glyphName,
        position: Offset(ornamentX, ornamentY),
        size: glyphSize * 0.8,
        color: theme.ornamentColor ?? theme.noteheadColor,
        centerVertically: true,
        centerHorizontally: true,
      );
    }
  }

  bool _shouldPlaceOrnamentAbove(OrnamentType type, int staffPosition, bool stemUp) {
    // Regra especial para fermatas - sempre seguem sua direção natural
    if (type == OrnamentType.fermata) return true;
    if (type == OrnamentType.fermataBelow || type == OrnamentType.fermataBelowInverted) return false;

    // Notas altas (na 5ª linha ou acima): ornamentos embaixo para evitar colisão
    if (staffPosition >= 4) return false;

    // Notas muito baixas (1ª linha ou abaixo): ornamentos sempre acima
    if (staffPosition <= -4) return true;

    // Para notas na região média: seguir direção da haste
    // Haste para cima = ornamento acima, haste para baixo = ornamento abaixo
    return stemUp;
  }

  double _getOrnamentVerticalDistance(OrnamentType type) {
    switch (type) {
      case OrnamentType.fermata:
      case OrnamentType.fermataBelow:
      case OrnamentType.fermataBelowInverted:
        return 2.0; // Fermatas mais distantes

      case OrnamentType.arpeggio:
        return 0.5; // Arpejos próximos à nota

      case OrnamentType.appoggiaturaUp:
      case OrnamentType.appoggiaturaDown:
      case OrnamentType.acciaccatura:
        return 1.0; // Apoggiaturas próximas

      default:
        return 1.5; // Trilos, mordentes, grupetos - distância padrão
    }
  }

  double _getOrnamentHorizontalPosition(OrnamentType type, double noteX) {
    switch (type) {
      case OrnamentType.arpeggio:
        // Arpejos à esquerda da nota
        return noteX - (coordinates.staffSpace * 0.5);

      case OrnamentType.appoggiaturaUp:
      case OrnamentType.appoggiaturaDown:
      case OrnamentType.acciaccatura:
        // Apoggiaturas à esquerda da nota principal
        return noteX - (coordinates.staffSpace * 0.8);

      default:
        // Demais ornamentos centralizados na nota
        return noteX;
    }
  }

  String? _getOrnamentGlyph(OrnamentType type) {
    switch (type) {
      case OrnamentType.trill:
        return 'ornamentTrill';
      case OrnamentType.trillFlat:
        return 'ornamentTrillFlat';
      case OrnamentType.trillNatural:
        return 'ornamentTrillNatural';
      case OrnamentType.trillSharp:
        return 'ornamentTrillSharp';
      case OrnamentType.shortTrill:
        return 'ornamentShortTrill';
      case OrnamentType.mordent:
        return 'ornamentMordent';
      case OrnamentType.invertedMordent:
        return 'ornamentMordentInverted';
      case OrnamentType.turn:
        return 'ornamentTurn';
      case OrnamentType.turnInverted:
        return 'ornamentTurnInverted';
      case OrnamentType.turnSlash:
        return 'ornamentTurnSlash';
      case OrnamentType.appoggiaturaUp:
        return 'ornamentAppoggiaturaUp';
      case OrnamentType.appoggiaturaDown:
        return 'ornamentAppoggiaturaDown';
      case OrnamentType.acciaccatura:
        return 'ornamentAcciaccatura';
      case OrnamentType.fermata:
        return 'fermataAbove';
      case OrnamentType.fermataBelow:
        return 'fermataBelow';
      case OrnamentType.fermataBelowInverted:
        return 'fermataBelowInverted';
      case OrnamentType.schleifer:
        return 'ornamentSchleifer';
      case OrnamentType.arpeggio:
        return 'arpeggiato';
      default:
        return null;
    }
  }

  void _renderDynamic(
    Canvas canvas,
    Dynamic dynamic,
    Offset notePos,
    int staffPosition,
  ) {
    if (dynamic.isHairpin) {
      _renderHairpin(canvas, dynamic, notePos);
      return;
    }

    final glyphName = _getDynamicGlyph(dynamic.type);
    final dynamicY = notePos.dy + (coordinates.staffSpace * 4.0); // Abaixo da pauta

    if (glyphName != null) {
      _drawGlyph(
        canvas: canvas,
        glyphName: glyphName,
        position: Offset(notePos.dx, dynamicY),
        size: glyphSize * 0.9,
        color: theme.dynamicColor ?? theme.noteheadColor,
        centerVertically: true,
        centerHorizontally: true,
      );
    } else if (dynamic.customText != null) {
      _drawText(
        canvas: canvas,
        text: dynamic.customText!,
        position: Offset(notePos.dx, dynamicY),
        style: theme.dynamicTextStyle ??
               TextStyle(fontSize: glyphSize * 0.4, color: theme.noteheadColor),
      );
    }
  }

  String? _getDynamicGlyph(DynamicType type) {
    switch (type) {
      case DynamicType.pianississimo:
      case DynamicType.ppp:
        return 'dynamicPPP';
      case DynamicType.pianissimo:
      case DynamicType.pp:
        return 'dynamicPP';
      case DynamicType.piano:
      case DynamicType.p:
        return 'dynamicPiano';
      case DynamicType.mezzoPiano:
      case DynamicType.mp:
        return 'dynamicMP';
      case DynamicType.mezzoForte:
      case DynamicType.mf:
        return 'dynamicMF';
      case DynamicType.forte:
      case DynamicType.f:
        return 'dynamicForte';
      case DynamicType.fortissimo:
      case DynamicType.ff:
        return 'dynamicFF';
      case DynamicType.fortississimo:
      case DynamicType.fff:
        return 'dynamicFFF';
      case DynamicType.pppp:
        return 'dynamicPPPP';
      case DynamicType.ppppp:
        return 'dynamicPPPPP';
      case DynamicType.pppppp:
        return 'dynamicPPPPPP';
      case DynamicType.ffff:
        return 'dynamicFFFF';
      case DynamicType.fffff:
        return 'dynamicFFFFF';
      case DynamicType.ffffff:
        return 'dynamicFFFFFF';
      case DynamicType.sforzando:
        return 'dynamicSforzando1';
      case DynamicType.sforzandoFF:
        return 'dynamicSforzatoFF';
      case DynamicType.sforzandoPiano:
        return 'dynamicSforzatoPiano';
      case DynamicType.rinforzando:
        return 'dynamicRinforzando1';
      case DynamicType.fortePiano:
        return 'dynamicFortePiano';
      case DynamicType.niente:
        return 'dynamicNiente';
      default:
        return null;
    }
  }

  void _renderHairpin(Canvas canvas, Dynamic dynamic, Offset notePos) {
    final length = dynamic.length ?? coordinates.staffSpace * 4;
    final hairpinY = notePos.dy + (coordinates.staffSpace * 4.0);

    final paint = Paint()
      ..color = theme.dynamicColor ?? theme.noteheadColor
      ..strokeWidth = coordinates.staffSpace * 0.1
      ..style = PaintingStyle.stroke;

    if (dynamic.type == DynamicType.crescendo) {
      // Crescendo (hairpin abrindo)
      canvas.drawLine(
        Offset(notePos.dx, hairpinY),
        Offset(notePos.dx + length, hairpinY - (coordinates.staffSpace * 0.3)),
        paint,
      );
      canvas.drawLine(
        Offset(notePos.dx, hairpinY),
        Offset(notePos.dx + length, hairpinY + (coordinates.staffSpace * 0.3)),
        paint,
      );
    } else if (dynamic.type == DynamicType.diminuendo) {
      // Diminuendo (hairpin fechando)
      canvas.drawLine(
        Offset(notePos.dx, hairpinY - (coordinates.staffSpace * 0.3)),
        Offset(notePos.dx + length, hairpinY),
        paint,
      );
      canvas.drawLine(
        Offset(notePos.dx, hairpinY + (coordinates.staffSpace * 0.3)),
        Offset(notePos.dx + length, hairpinY),
        paint,
      );
    }
  }

  void _renderTuplet(Canvas canvas, Tuplet tuplet, Offset basePosition) {
    // Renderizar todas as notas da quiáltera
    double currentX = basePosition.dx;
    final spacing = coordinates.staffSpace * 1.2;
    final List<Offset> notePositions = [];

    for (final element in tuplet.elements) {
      if (element is Note) {
        _renderNote(canvas, element, Offset(currentX, basePosition.dy));
        notePositions.add(Offset(currentX, basePosition.dy));
        currentX += spacing;
      } else if (element is Rest) {
        _renderRest(canvas, element, Offset(currentX, basePosition.dy));
        notePositions.add(Offset(currentX, basePosition.dy));
        currentX += spacing;
      }
    }

    // Desenhar suporte da quiáltera se necessário
    if (tuplet.showBracket && notePositions.length >= 2) {
      _drawTupletBracket(canvas, notePositions, tuplet.actualNotes);
    }

    // Desenhar número da quiáltera
    if (tuplet.showNumber && notePositions.isNotEmpty) {
      _drawTupletNumber(canvas, notePositions, tuplet.actualNotes);
    }
  }

  void _drawTupletBracket(Canvas canvas, List<Offset> notePositions, int number) {
    if (notePositions.length < 2) return;

    final firstNote = notePositions.first;
    final lastNote = notePositions.last;
    final bracketY = firstNote.dy - (coordinates.staffSpace * 2.5);

    final paint = Paint()
      ..color = theme.stemColor
      ..strokeWidth = coordinates.staffSpace * 0.08
      ..style = PaintingStyle.stroke;

    // Linha horizontal do suporte
    canvas.drawLine(
      Offset(firstNote.dx, bracketY),
      Offset(lastNote.dx, bracketY),
      paint,
    );

    // Pequenas linhas verticais nas extremidades
    final verticalLength = coordinates.staffSpace * 0.3;
    canvas.drawLine(
      Offset(firstNote.dx, bracketY),
      Offset(firstNote.dx, bracketY + verticalLength),
      paint,
    );
    canvas.drawLine(
      Offset(lastNote.dx, bracketY),
      Offset(lastNote.dx, bracketY + verticalLength),
      paint,
    );
  }

  void _drawTupletNumber(Canvas canvas, List<Offset> notePositions, int number) {
    if (notePositions.isEmpty) return;

    final centerX = (notePositions.first.dx + notePositions.last.dx) / 2;
    final numberY = notePositions.first.dy - (coordinates.staffSpace * 2.2);

    final glyphName = 'tuplet$number';

    _drawGlyph(
      canvas: canvas,
      glyphName: glyphName,
      position: Offset(centerX, numberY),
      size: glyphSize * 0.6,
      color: theme.stemColor,
      centerVertically: true,
      centerHorizontally: true,
    );
  }

  void _renderRepeatMark(Canvas canvas, RepeatMark repeatMark, Offset basePosition) {
    final glyphName = _getRepeatMarkGlyph(repeatMark.type);
    if (glyphName == null) return;

    // Posição acima do pentagrama para símbolos de repetição
    final signY = coordinates.staffBaseline.dy - (coordinates.staffSpace * 3.0);

    _drawGlyph(
      canvas: canvas,
      glyphName: glyphName,
      position: Offset(basePosition.dx, signY),
      size: glyphSize * 1.2,
      color: theme.noteheadColor,
      centerVertically: true,
      centerHorizontally: true,
    );
  }

  String? _getRepeatMarkGlyph(RepeatType type) {
    switch (type) {
      case RepeatType.segno:
        return 'segno';
      case RepeatType.coda:
        return 'coda';
      case RepeatType.daCapo:
        return 'daCapo';
      case RepeatType.dalSegno:
        return 'dalSegno';
      case RepeatType.fine:
        return 'fine';
      case RepeatType.toCoda:
        return 'toCoda';
      case RepeatType.segnoSquare:
        return 'segnoSquare';
      case RepeatType.codaSquare:
        return 'codaSquare';
      case RepeatType.repeat1Bar:
        return 'repeat1Bar';
      case RepeatType.repeat2Bars:
        return 'repeat2Bars';
      case RepeatType.repeat4Bars:
        return 'repeat4Bars';
      case RepeatType.simile:
        return 'simile';
      case RepeatType.percentRepeat:
        return 'percentRepeat';
      default:
        return null;
    }
  }

  void _drawText({
    required Canvas canvas,
    required String text,
    required Offset position,
    required TextStyle style,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(position.dx - (textPainter.width * 0.5), position.dy - (textPainter.height * 0.5)),
    );
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
