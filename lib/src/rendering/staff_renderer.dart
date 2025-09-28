// lib/src/rendering/staff_renderer.dart

import 'package:flutter/material.dart';
import '../layout/layout_engine.dart';
import '../music_model/musical_element.dart';
import '../smufl/smufl_metadata_loader.dart';
import '../smufl/smufl_coordinates.dart';
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
  late final SmuflGlyphPositioner positioner;

  // Cache de posições de claves
  Clef? currentClef;

  StaffRenderer({
    required this.coordinates,
    required this.metadata,
    required this.theme,
  }) {
    // Configuração correta dos tamanhos segundo o metadata Bravura
    glyphSize = coordinates.staffSpace * 4.0; // Tamanho padrão para glifos
    staffLineThickness = SmuflCoordinates.getStaffLineThickness(coordinates.staffSpace);
    stemThickness = SmuflCoordinates.getStemThickness(coordinates.staffSpace);

    // Inicializar posicionador baseado em anchors SMuFL
    positioner = SmuflGlyphPositioner(
      metadata: metadata,
      staffSpace: coordinates.staffSpace,
    );
  }

  /// Renderiza a pauta completa com todos os elementos
  void renderStaff(Canvas canvas, List<PositionedElement> elements, Size size) {
    // 1. Desenhar linhas da pauta
    _drawStaffLines(canvas, size.width);

    // 2. Resetar clave atual
    currentClef = null;

    // 3. Coletar notas e suas posições para renderização de beams
    final notes = <Note>[];
    final notePositions = <Offset>[];

    // 4. Renderizar elementos em ordem e coletar dados para beams
    for (final positioned in elements) {
      _renderElement(canvas, positioned);

      // Coletar notas para processamento de beams
      if (positioned.element is Note) {
        final note = positioned.element as Note;
        notes.add(note);

        // Calcular posição da nota baseada na altura
        final staffPosition = _calculateStaffPosition(note.pitch);
        final noteY = coordinates.staffBaseline.dy + (staffPosition * coordinates.staffSpace * 0.5);
        notePositions.add(Offset(positioned.position.dx, noteY));
      }
    }

    // 5. Renderizar beams após todos os elementos individuais
    if (notes.isNotEmpty) {
      _renderBeams(canvas, notes, notePositions);
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
    } else if (element.runtimeType.toString() == 'Tuplet') {
      _renderTuplet(canvas, element, basePosition);
    }
  }

  void _renderClef(Canvas canvas, Clef clef, Offset basePosition) {
    final glyphName = clef.glyphName;
    double yOffset = 0;

    // CORREÇÃO DEFINITIVA: Posicionamento preciso baseado nas especificações musicais oficiais
    // Referências: VexFlow, MuseScore, LilyPond e padrões de notação musical
    switch (clef.actualClefType) {
      case ClefType.treble:
      case ClefType.treble8va:
      case ClefType.treble8vb:
      case ClefType.treble15ma:
      case ClefType.treble15mb:
        // TREBLE CLEF: Espiral na 2ª linha (G4)
        // Padrão oficial: a espiral da clave deve envolver a 2ª linha
        yOffset = coordinates.getStaffLineY(2) - coordinates.staffBaseline.dy + (coordinates.staffSpace * 0.05);
        break;

      case ClefType.bass:
      case ClefType.bass8va:
      case ClefType.bass8vb:
      case ClefType.bass15ma:
      case ClefType.bass15mb:
        // BASS CLEF: Linha de referência na 4ª linha (F3)
        // Padrão oficial: os dois pontos devem estar na 4ª linha
        yOffset = coordinates.getStaffLineY(4) - coordinates.staffBaseline.dy + (coordinates.staffSpace * 0.1);
        break;

      case ClefType.bassThirdLine:
        // BASS CLEF alternativo: na 3ª linha
        yOffset = coordinates.getStaffLineY(3) - coordinates.staffBaseline.dy + (coordinates.staffSpace * 0.1);
        break;

      case ClefType.soprano:
        // SOPRANO CLEF: Dó na 1ª linha
        yOffset = coordinates.getStaffLineY(1) - coordinates.staffBaseline.dy;
        break;

      case ClefType.mezzoSoprano:
        // MEZZO-SOPRANO CLEF: Dó na 2ª linha
        yOffset = coordinates.getStaffLineY(2) - coordinates.staffBaseline.dy;
        break;

      case ClefType.alto:
        // ALTO CLEF: Dó na 3ª linha (middle C)
        // Padrão oficial: centro da clave deve estar na 3ª linha
        yOffset = coordinates.getStaffLineY(3) - coordinates.staffBaseline.dy;
        break;

      case ClefType.tenor:
        // TENOR CLEF: Dó na 4ª linha
        // Padrão oficial: centro da clave deve estar na 4ª linha
        yOffset = coordinates.getStaffLineY(4) - coordinates.staffBaseline.dy;
        break;

      case ClefType.baritone:
        // BARITONE CLEF: Dó na 5ª linha
        yOffset = coordinates.getStaffLineY(5) - coordinates.staffBaseline.dy;
        break;

      case ClefType.c8vb:
        // C CLEF oitava abaixo: Dó na 3ª linha (como alto clef)
        yOffset = coordinates.getStaffLineY(3) - coordinates.staffBaseline.dy;
        break;

      case ClefType.percussion:
      case ClefType.percussion2:
      case ClefType.tab6:
      case ClefType.tab4:
        // Claves especiais: centralizar no pentagrama
        yOffset = 0;
        break;
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
    if (ks.count == 0) return;

    final glyphName = ks.count > 0 ? 'accidentalSharp' : 'accidentalFlat';
    final count = ks.count.abs();

    // Usar o sistema de coordenadas correto para obter posições precisas
    final positions = coordinates.getKeySignaturePositions(
      ks.count,
      clef: currentClef?.actualClefType.name ?? 'treble',
    );

    double currentX = basePosition.dx;
    final spacing = coordinates.staffSpace * 0.8; // Espaçamento consistente

    for (int i = 0; i < count && i < positions.length; i++) {
      _drawGlyph(
        canvas: canvas,
        glyphName: glyphName,
        position: Offset(currentX, positions[i]),
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

    // Numerador na parte superior da pauta (entre linhas 4-5)
    _drawGlyph(
      canvas: canvas,
      glyphName: numeratorGlyph,
      position: Offset(basePosition.dx, coordinates.getStaffLineY(4)),
      size: glyphSize,
      color: theme.timeSignatureColor,
      centerVertically: true,
    );

    // Denominador na parte inferior da pauta (entre linhas 2-3)
    _drawGlyph(
      canvas: canvas,
      glyphName: denominatorGlyph,
      position: Offset(basePosition.dx, coordinates.getStaffLineY(2)),
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

    // Desenhar cabeça da nota centralizada
    _drawGlyph(
      canvas: canvas,
      glyphName: note.duration.type.glyphName,
      position: Offset(basePosition.dx, noteY),
      size: glyphSize,
      color: theme.noteheadColor,
      centerVertically: true,
      centerHorizontally: true,
    );

    // Desenhar haste se necessário
    if (note.duration.type != DurationType.whole) {
      _renderStem(canvas, note, Offset(basePosition.dx, noteY), staffPosition);
    }

    // Desenhar pontos de aumento
    if (note.duration.dots > 0) {
      _renderAugmentationDots(canvas, note, Offset(basePosition.dx, noteY), staffPosition);
    }

    // Desenhar articulações
    _renderArticulations(
      canvas,
      note,
      Offset(basePosition.dx, noteY),
      staffPosition,
    );

    // Desenhar ornamentos
    _renderOrnaments(
      canvas,
      note,
      Offset(basePosition.dx, noteY),
    );

    // Desenhar dinâmica
    _renderDynamic(
      canvas,
      note,
      Offset(basePosition.dx, noteY),
    );
  }

  int _calculateStaffPosition(Pitch pitch) {
    // CORREÇÃO: Usar enum ClefType ao invés do método type deprecado
    // Calcular posição na pauta (0 = linha central B4 para clave de sol)
    final clefType = currentClef?.actualClefType ?? ClefType.treble;

    if (clefType == ClefType.treble || currentClef == null) {
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

    // CORREÇÃO: Usar valores oficiais SMuFL para linhas suplementares
    final paint = Paint()
      ..color = theme.staffLineColor
      ..strokeWidth = SmuflCoordinates.getLedgerLineThickness(coordinates.staffSpace);

    // CORREÇÃO: Usar extensão oficial SMuFL
    final extension = SmuflCoordinates.getLedgerLineExtension(coordinates.staffSpace);

    // Estimar largura da nota baseado no metadata (ou usar valor padrão)
    final noteWidth = coordinates.staffSpace * 1.18; // Largura padrão estimada
    final totalWidth = noteWidth + (2 * extension);
    final halfWidth = totalWidth * 0.5;

    // Linhas suplementares superiores (acima da pauta)
    // staffPosition < -4 significa acima da 1ª linha
    if (staffPosition < -4) {
      for (int pos = -6; pos >= staffPosition; pos -= 2) {
        final y = coordinates.staffBaseline.dy - (pos * coordinates.staffSpace * 0.5);
        canvas.drawLine(
          Offset(x - halfWidth, y),
          Offset(x + halfWidth, y),
          paint,
        );
      }
    }

    // Linhas suplementares inferiores (abaixo da pauta)
    // staffPosition > 4 significa abaixo da 5ª linha
    if (staffPosition > 4) {
      for (int pos = 6; pos <= staffPosition; pos += 2) {
        final y = coordinates.staffBaseline.dy - (pos * coordinates.staffSpace * 0.5);
        canvas.drawLine(
          Offset(x - halfWidth, y),
          Offset(x + halfWidth, y),
          paint,
        );
      }
    }
  }

  void _renderStem(
    Canvas canvas,
    Note note,
    Offset notePosition,
    int staffPosition,
  ) {
    // CORREÇÃO: Voltar ao método que funcionava antes, mantendo a regra musical correta
    // Usar posição Y direta para determinar direção da haste
    // 3ª linha (baseline) é a referência
    final middleLineY = coordinates.staffBaseline.dy;

    // Regra musical correta:
    // - Acima da 3ª linha (Y menor) -> hastes para baixo
    // - Abaixo da 3ª linha (Y maior) -> hastes para cima
    // - Na 3ª linha -> hastes para baixo (convenção)
    final stemsUp = notePosition.dy > middleLineY;
    final stemHeight = SmuflCoordinates.getStemHeight(coordinates.staffSpace);

    // Posicionamento correto da haste considerando centralização da nota
    final noteWidth = coordinates.staffSpace * 1.18; // Largura padrão da cabeça
    final halfNoteWidth = noteWidth * 0.5;
    final stemX = stemsUp
        ? notePosition.dx + halfNoteWidth - (stemThickness * 0.5) // Direita para hastes para cima
        : notePosition.dx - halfNoteWidth + (stemThickness * 0.5); // Esquerda para hastes para baixo

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

    // Desenhar bandeirola se necessário (apenas se não estiver em um beam)
    if (note.beam == null && note.duration.type.value < 1.0) {
      _renderFlag(canvas, note, Offset(stemX, stemEndY), stemsUp);
    }
  }

  void _renderFlag(Canvas canvas, Note note, Offset stemEnd, bool stemsUp) {
    String flagGlyph;

    // CORREÇÃO: Implementar todas as durações com bandeirolas
    switch (note.duration.type) {
      case DurationType.eighth:
        flagGlyph = stemsUp ? 'flag8thUp' : 'flag8thDown';
        break;
      case DurationType.sixteenth:
        flagGlyph = stemsUp ? 'flag16thUp' : 'flag16thDown';
        break;
      case DurationType.thirtySecond:
        flagGlyph = stemsUp ? 'flag32ndUp' : 'flag32ndDown';
        break;
      case DurationType.sixtyFourth:
        flagGlyph = stemsUp ? 'flag64thUp' : 'flag64thDown';
        break;
      case DurationType.oneHundredTwentyEighth:
        flagGlyph = stemsUp ? 'flag128thUp' : 'flag128thDown';
        break;
      default:
        return; // Sem bandeirola para esta duração
    }

    // CORREÇÃO: Posicionamento preciso da bandeirola no final da haste
    // Bandeirolas devem estar alinhadas com o final da haste, sem offset adicional
    _drawGlyph(
      canvas: canvas,
      glyphName: flagGlyph,
      position: Offset(stemEnd.dx, stemEnd.dy),
      size: glyphSize,
      color: theme.stemColor,
      centerVertically: false,
      centerHorizontally: false, // Bandeirolas alinhadas à esquerda da haste
    );
  }

  /// Renderiza barras de ligadura (beams) conectando grupos de notas
  void _renderBeams(Canvas canvas, List<Note> notes, List<Offset> notePositions) {
    if (notes.length < 2) return;

    // Encontrar grupos de notas conectadas por beams
    final beamGroups = <List<int>>[];
    List<int> currentGroup = [];

    for (int i = 0; i < notes.length; i++) {
      final note = notes[i];

      if (note.beam == BeamType.start) {
        // Iniciar novo grupo
        if (currentGroup.isNotEmpty) {
          beamGroups.add(List.from(currentGroup));
        }
        currentGroup = [i];
      } else if (note.beam == BeamType.inner || note.beam == BeamType.end) {
        // Adicionar ao grupo atual
        currentGroup.add(i);

        if (note.beam == BeamType.end) {
          // Finalizar grupo
          beamGroups.add(List.from(currentGroup));
          currentGroup = [];
        }
      }
    }

    // Adicionar grupo restante se existir
    if (currentGroup.isNotEmpty) {
      beamGroups.add(currentGroup);
    }

    // Renderizar cada grupo de beams
    for (final group in beamGroups) {
      if (group.length >= 2) {
        _renderBeamGroup(canvas, notes, notePositions, group);
      }
    }
  }

  /// Renderiza um grupo específico de notas conectadas por beams
  void _renderBeamGroup(Canvas canvas, List<Note> notes, List<Offset> notePositions, List<int> indices) {
    if (indices.length < 2) return;

    // Calcular posições das hastes e direção dos beams
    final stemPositions = <Offset>[];
    final stemDirectionsUp = <bool>[];

    for (final index in indices) {
      // final note = notes[index];
      final notePos = notePositions[index];

      // Determinar direção da haste para o grupo (baseado na nota mais extrema)
      final staffPosition = coordinates.getStaffPosition(notePos.dy);
      final stemsUp = staffPosition >= 0; // Simplificado para o grupo
      stemDirectionsUp.add(stemsUp);

      // Calcular posição da haste
      final noteWidth = coordinates.staffSpace * 1.18;
      final stemX = stemsUp ? notePos.dx + (noteWidth * 0.45) : notePos.dx - (noteWidth * 0.45);
      final stemLength = coordinates.staffSpace * 3.5;
      final stemEndY = stemsUp ? notePos.dy - stemLength : notePos.dy + stemLength;

      stemPositions.add(Offset(stemX, stemEndY));
    }

    // Determinar direção dominante do grupo
    final upCount = stemDirectionsUp.where((up) => up).length;
    final groupStemsUp = upCount > stemDirectionsUp.length / 2;

    // Calcular inclinação do beam baseada nas posições das notas
    final firstStem = stemPositions.first;
    final lastStem = stemPositions.last;
    final beamSlope = (lastStem.dy - firstStem.dy) / (lastStem.dx - firstStem.dx);

    // Limitar a inclinação para parecer natural
    final clampedSlope = beamSlope.clamp(-0.2, 0.2);

    // Renderizar beams baseado na duração mínima do grupo
    final minDuration = indices.map((i) => notes[i].duration.type.value).reduce((a, b) => a < b ? a : b);
    final beamCount = _getBeamCount(minDuration);

    for (int beamLevel = 0; beamLevel < beamCount; beamLevel++) {
      _renderSingleBeam(canvas, stemPositions, groupStemsUp, clampedSlope, beamLevel);
    }
  }

  /// Renderiza uma única barra (beam) entre as hastes
  void _renderSingleBeam(Canvas canvas, List<Offset> stemPositions, bool stemsUp, double slope, int level) {
    if (stemPositions.length < 2) return;

    final beamThickness = coordinates.staffSpace * 0.5; // Espessura padrão do beam
    final beamSpacing = coordinates.staffSpace * 0.25; // Espaçamento entre beams múltiplos

    // Offset vertical baseado no nível do beam
    final yOffset = stemsUp ? -(level * beamSpacing) : (level * beamSpacing);

    final path = Path();

    // Pontos da primeira haste
    final firstStem = stemPositions.first;
    final firstY = firstStem.dy + yOffset;

    // Pontos da última haste
    final lastStem = stemPositions.last;
    final lastY = firstY + (slope * (lastStem.dx - firstStem.dx));

    // Criar o trapézio do beam
    if (stemsUp) {
      // Beam acima das hastes
      path.moveTo(firstStem.dx, firstY);
      path.lineTo(lastStem.dx, lastY);
      path.lineTo(lastStem.dx, lastY + beamThickness);
      path.lineTo(firstStem.dx, firstY + beamThickness);
    } else {
      // Beam abaixo das hastes
      path.moveTo(firstStem.dx, firstY);
      path.lineTo(lastStem.dx, lastY);
      path.lineTo(lastStem.dx, lastY - beamThickness);
      path.lineTo(firstStem.dx, firstY - beamThickness);
    }
    path.close();

    // Desenhar o beam
    final beamPaint = Paint()
      ..color = theme.stemColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, beamPaint);
  }

  /// Determina quantos beams são necessários baseado na duração
  int _getBeamCount(double duration) {
    if (duration >= 0.125) return 1; // Colcheia = 1 beam
    if (duration >= 0.0625) return 2; // Semicolcheia = 2 beams
    if (duration >= 0.03125) return 3; // Fusa = 3 beams
    if (duration >= 0.015625) return 4; // Semifusa = 4 beams
    if (duration >= 0.0078125) return 5; // 1/128 = 5 beams
    return 1; // Fallback
  }

  void _renderAccidental(Canvas canvas, Note note, Offset notePosition) {
    if (note.pitch.accidentalGlyph == null) return;

    // Posicionar acidente com espaçamento adequado considerando nota centralizada
    final noteWidth = coordinates.staffSpace * 1.18;
    final halfNoteWidth = noteWidth * 0.5;
    final accidentalSpacing = coordinates.staffSpace * 0.8; // Espaçamento entre acidente e nota
    final accidentalX = notePosition.dx - halfNoteWidth - accidentalSpacing;

    _drawGlyph(
      canvas: canvas,
      glyphName: note.pitch.accidentalGlyph!,
      position: Offset(accidentalX, notePosition.dy),
      size: glyphSize * 0.8,
      color: theme.accidentalColor ?? theme.noteheadColor,
      centerVertically: true,
      centerHorizontally: true,
    );
  }

  void _renderArticulations(
    Canvas canvas,
    Note note,
    Offset notePosition,
    int staffPosition,
  ) {
    if (note.articulations.isEmpty) return;

    // CORREÇÃO: Lógica independente para articulações que não interfere com hastes
    // Usar regra musical correta para posicionamento
    final middleLineY = coordinates.staffBaseline.dy;

    // Determinar se articulações vão acima ou abaixo baseado na posição da nota
    // Regra musical: articulações ficam do lado oposto à haste quando possível
    final noteAboveMiddle = notePosition.dy < middleLineY;
    final articulationAbove = !noteAboveMiddle; // Lado oposto à haste

    // Calcular posição Y da articulação com espaçamento adequado
    final articulationY = articulationAbove
        ? notePosition.dy - coordinates.staffSpace * 1.2 // Acima da nota
        : notePosition.dy + coordinates.staffSpace * 1.2; // Abaixo da nota

    for (final articulation in note.articulations) {
      final glyphName = _getArticulationGlyph(articulation, articulationAbove);

      _drawGlyph(
        canvas: canvas,
        glyphName: glyphName,
        position: Offset(notePosition.dx, articulationY),
        size: glyphSize * 0.7, // Tamanho apropriado para articulações
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
      case ArticulationType.staccatissimo:
        return above ? 'articStaccatissimoAbove' : 'articStaccatissimoBelow';
      case ArticulationType.accent:
        return above ? 'articAccentAbove' : 'articAccentBelow';
      case ArticulationType.strongAccent:
        return above ? 'articAccentAbove' : 'articAccentBelow';
      case ArticulationType.tenuto:
        return above ? 'articTenutoAbove' : 'articTenutoBelow';
      case ArticulationType.marcato:
        return above ? 'articMarcatoAbove' : 'articMarcatoBelow';
      case ArticulationType.legato:
        return above ? 'articTenutoAbove' : 'articTenutoBelow';
      case ArticulationType.portato:
        return above ? 'articTenutoStaccatoAbove' : 'articTenutoStaccatoBelow';
      case ArticulationType.upBow:
        return 'stringsUpBow';
      case ArticulationType.downBow:
        return 'stringsDownBow';
      case ArticulationType.harmonics:
        return 'stringsHarmonic';
      case ArticulationType.pizzicato:
        return above ? 'pluckedPizzicatoAbove' : 'pluckedPizzicatoBelow';
      case ArticulationType.snap:
        return above ? 'pluckedSnapPizzicatoAbove' : 'pluckedSnapPizzicatoBelow';
      case ArticulationType.thumb:
        return above ? 'pluckedThumbPositionAbove' : 'pluckedThumbPositionBelow';
      case ArticulationType.stopped:
        return above ? 'brassMuteClosedAbove' : 'brassMuteClosedBelow';
      case ArticulationType.open:
        return above ? 'brassMuteOpenAbove' : 'brassMuteOpenBelow';
      case ArticulationType.halfStopped:
        return above ? 'brassMuteHalfClosedAbove' : 'brassMuteHalfClosedBelow';
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
      case DurationType.thirtySecond:
        glyphName = 'rest32nd';
        yOffset = 0;
        break;
      case DurationType.sixtyFourth:
        glyphName = 'rest64th';
        yOffset = 0;
        break;
      case DurationType.oneHundredTwentyEighth:
        glyphName = 'rest128th';
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
    // CORREÇÃO: Usar espessura oficial SMuFL para barras de compasso
    final paint = Paint()
      ..color = theme.barlineColor
      ..strokeWidth = SmuflCoordinates.getBarlineThickness(coordinates.staffSpace);

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

    // Renderizar cada nota do acorde com ajuste de posição horizontal
    double xOffset = 0;
    for (int i = 0; i < sortedNotes.length; i++) {
      final note = sortedNotes[i];

      // Aplicar offset para evitar sobreposição de notas
      if (i > 0) {
        // Verificar se as notas são adjacentes (intervalo de segunda)
        final prevPosition = _calculateStaffPosition(sortedNotes[i-1].pitch);
        final currPosition = _calculateStaffPosition(note.pitch);

        if ((prevPosition - currPosition).abs() == 1) {
          // Notas adjacentes: aplicar offset baseado no bounding box real
          final noteheadBBox = metadata.getGlyphBoundingBox('noteheadBlack');
          final noteWidth = noteheadBBox?.widthInPixels(coordinates.staffSpace) ??
                           (coordinates.staffSpace * 1.18);
          xOffset = (i % 2 == 1) ? noteWidth * 0.6 : 0; // 60% da largura para evitar sobreposição
        }
      }

      _renderNote(canvas, note, Offset(basePosition.dx + xOffset, basePosition.dy));
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

    // Centralização vertical
    double yOffset = 0;
    if (centerVertically) {
      yOffset = -textPainter.height * 0.5;
    }

    // Centralização horizontal melhorada para notas
    double xOffset = 0;
    if (centerHorizontally) {
      // Para notas, usar metade da largura do glifo para centralizar
      xOffset = -textPainter.width * 0.5;
    }

    textPainter.paint(canvas, Offset(position.dx + xOffset, position.dy + yOffset));
  }

  /// Renderiza ornamentos de uma nota
  void _renderOrnaments(Canvas canvas, Note note, Offset basePosition) {
    if (note.ornaments.isEmpty) return;

    for (final ornament in note.ornaments) {
      _renderOrnament(canvas, ornament, basePosition);
    }
  }

  /// Renderiza um único ornamento
  void _renderOrnament(Canvas canvas, dynamic ornament, Offset basePosition) {
    if (ornament == null) return;

    // Verificar se é um Ornament válido via duck typing
    try {
      final type = ornament.type;
      final above = ornament.above ?? true;

      String? glyphName = _getOrnamentGlyph(type);
      if (glyphName == null) return;

      // Posição do ornamento baseada em metadados SMuFL
      final ornamentY = above
          ? basePosition.dy - (coordinates.staffSpace * 3.0)
          : basePosition.dy + (coordinates.staffSpace * 3.0);

      _drawGlyph(
        canvas: canvas,
        glyphName: glyphName,
        position: Offset(basePosition.dx, ornamentY),
        size: coordinates.staffSpace * 3.0,
        color: theme.ornamentColor ?? theme.noteheadColor,
        centerVertically: true,
        centerHorizontally: true,
      );
    } catch (e) {
      // Ignorar ornamentos inválidos
    }
  }

  /// Renderiza dinâmica de uma nota
  void _renderDynamic(Canvas canvas, Note note, Offset basePosition) {
    final dynamic = note.dynamicElement;
    if (dynamic == null) return;

    try {
      final type = dynamic.type;

      if (dynamic.isHairpin == true) {
        _renderHairpin(canvas, dynamic, basePosition);
      } else {
        String? glyphName = _getDynamicGlyph(type);
        if (glyphName != null) {
          // Dinâmicas sempre ficam abaixo da pauta
          final dynamicY = basePosition.dy + (coordinates.staffSpace * 4.0);

          _drawGlyph(
            canvas: canvas,
            glyphName: glyphName,
            position: Offset(basePosition.dx, dynamicY),
            size: coordinates.staffSpace * 2.5,
            color: theme.dynamicColor ?? theme.noteheadColor,
            centerVertically: true,
            centerHorizontally: true,
          );
        }
      }
    } catch (e) {
      // Ignorar dinâmicas inválidas
    }
  }

  /// Renderiza hairpins (crescendo/diminuendo)
  void _renderHairpin(Canvas canvas, dynamic dynamic, Offset basePosition) {
    // Implementação básica de hairpin
    final length = coordinates.staffSpace * 4.0;
    final height = coordinates.staffSpace * 0.5;
    final y = basePosition.dy + (coordinates.staffSpace * 4.0);

    final paint = Paint()
      ..color = theme.dynamicColor ?? theme.noteheadColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();

    try {
      final type = dynamic.type.toString();
      if (type.contains('crescendo')) {
        // Crescendo: linha que se abre
        path.moveTo(basePosition.dx, y - height / 2);
        path.lineTo(basePosition.dx + length, y - height);
        path.moveTo(basePosition.dx, y + height / 2);
        path.lineTo(basePosition.dx + length, y + height);
      } else if (type.contains('diminuendo')) {
        // Diminuendo: linha que se fecha
        path.moveTo(basePosition.dx, y - height);
        path.lineTo(basePosition.dx + length, y - height / 2);
        path.moveTo(basePosition.dx, y + height);
        path.lineTo(basePosition.dx + length, y + height / 2);
      }

      canvas.drawPath(path, paint);
    } catch (e) {
      // Ignorar hairpins inválidos
    }
  }

  /// Mapeia tipos de ornamentos para glifos SMuFL
  String? _getOrnamentGlyph(dynamic type) {
    final typeStr = type.toString();

    const ornamentGlyphs = {
      'OrnamentType.trill': 'ornamentTrill',
      'OrnamentType.trillFlat': 'ornamentTrillFlat',
      'OrnamentType.trillNatural': 'ornamentTrillNatural',
      'OrnamentType.trillSharp': 'ornamentTrillSharp',
      'OrnamentType.mordent': 'ornamentMordent',
      'OrnamentType.invertedMordent': 'ornamentMordentInverted',
      'OrnamentType.shortTrill': 'ornamentShortTrill',
      'OrnamentType.turn': 'ornamentTurn',
      'OrnamentType.invertedTurn': 'ornamentTurnInverted',
      'OrnamentType.turnSlash': 'ornamentTurnSlash',
      'OrnamentType.fermata': 'fermataAbove',
      'OrnamentType.fermataBelow': 'fermataBelow',
      'OrnamentType.acciaccatura': 'ornamentAppoggiaturaDown',
      'OrnamentType.glissando': 'glissandoUp',
      'OrnamentType.arpeggio': 'arpeggiato',
    };

    return ornamentGlyphs[typeStr];
  }

  /// Mapeia tipos de dinâmica para glifos SMuFL
  String? _getDynamicGlyph(dynamic type) {
    final typeStr = type.toString();

    const dynamicGlyphs = {
      'DynamicType.piano': 'dynamicPiano',
      'DynamicType.forte': 'dynamicForte',
      'DynamicType.mezzoForte': 'dynamicMF',
      'DynamicType.mezzoPiano': 'dynamicMP',
      'DynamicType.fortissimo': 'dynamicFF',
      'DynamicType.pianissimo': 'dynamicPP',
      'DynamicType.fortississimo': 'dynamicFFF',
      'DynamicType.pianississimo': 'dynamicPPP',
      'DynamicType.sforzando': 'dynamicSforzando1',
      'DynamicType.p': 'dynamicPiano',
      'DynamicType.f': 'dynamicForte',
      'DynamicType.mp': 'dynamicMP',
      'DynamicType.mf': 'dynamicMF',
      'DynamicType.pp': 'dynamicPP',
      'DynamicType.ff': 'dynamicFF',
      'DynamicType.ppp': 'dynamicPPP',
      'DynamicType.fff': 'dynamicFFF',
    };

    return dynamicGlyphs[typeStr];
  }

  /// Renderiza pontos de aumento
  void _renderAugmentationDots(Canvas canvas, Note note, Offset basePosition, int staffPosition) {
    if (note.duration.dots == 0) return;

    // Posição horizontal: à direita da cabeça da nota
    final dotX = basePosition.dx + (coordinates.staffSpace * 0.8);

    // Posição vertical: sempre em espaços (não em linhas)
    double dotY = basePosition.dy;

    // Se a nota está numa linha, mover o ponto para o espaço acima
    if (staffPosition % 2 == 0) {
      dotY -= coordinates.staffSpace * 0.25;
    }

    // Desenhar cada ponto
    for (int i = 0; i < note.duration.dots; i++) {
      final currentDotX = dotX + (i * coordinates.staffSpace * 0.4);

      _drawGlyph(
        canvas: canvas,
        glyphName: 'augmentationDot',
        position: Offset(currentDotX, dotY),
        size: coordinates.staffSpace * 2.0,
        color: theme.noteheadColor,
        centerVertically: true,
        centerHorizontally: true,
      );
    }
  }

  /// Renderiza tuplet (quiáltera)
  void _renderTuplet(Canvas canvas, dynamic tuplet, Offset basePosition) {
    try {
      final actualNotes = tuplet.actualNotes ?? 3;
      final showBracket = tuplet.showBracket ?? true;
      final showNumber = tuplet.showNumber ?? true;

      if (!showBracket && !showNumber) return;

      // Assumir largura baseada no número de notas
      final tupletWidth = coordinates.staffSpace * actualNotes * 1.5;
      final bracketY = basePosition.dy - (coordinates.staffSpace * 2.5);

      // Desenhar colchete se solicitado
      if (showBracket) {
        final paint = Paint()
          ..color = theme.tupletColor ?? theme.noteheadColor
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

        final path = Path();

        // Linha horizontal
        path.moveTo(basePosition.dx, bracketY);
        path.lineTo(basePosition.dx + tupletWidth, bracketY);

        // Linhas verticais nas extremidades
        path.moveTo(basePosition.dx, bracketY);
        path.lineTo(basePosition.dx, bracketY - (coordinates.staffSpace * 0.3));

        path.moveTo(basePosition.dx + tupletWidth, bracketY);
        path.lineTo(basePosition.dx + tupletWidth, bracketY - (coordinates.staffSpace * 0.3));

        canvas.drawPath(path, paint);
      }

      // Desenhar número se solicitado
      if (showNumber) {
        final centerX = basePosition.dx + (tupletWidth / 2);
        final text = '$actualNotes';

        _drawText(
          canvas,
          text,
          Offset(centerX, bracketY - (coordinates.staffSpace * 0.5)),
          theme.tupletTextStyle ?? TextStyle(
            color: theme.tupletColor ?? theme.noteheadColor,
            fontSize: coordinates.staffSpace * 0.8,
            fontWeight: FontWeight.bold,
          ),
        );
      }
    } catch (e) {
      // Ignorar tuplets inválidos
    }
  }

  /// Desenha texto simples
  void _drawText(Canvas canvas, String text, Offset position, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final offset = Offset(
      position.dx - textPainter.width / 2,
      position.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, offset);
  }
}
