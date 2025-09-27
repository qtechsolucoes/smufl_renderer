// lib/src/rendering/music_painter.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../layout/layout_engine.dart';
import '../music_model/musical_element.dart';
import '../smufl/smufl_metadata_loader.dart';
import '../theme/music_score_theme.dart';
import 'advanced_painter.dart';
import 'performance_optimizer.dart';
import 'staff_coordinate_system.dart';

class MusicPainter extends CustomPainter with AdvancedMusicPainterMixin {
  final List<PositionedElement> positionedElements;
  final SmuflMetadata metadata;
  final MusicScoreTheme theme;
  final double staffSpace; // CORREÇÃO: Usar staffSpace do LayoutEngine

  MusicPainter({
    required this.positionedElements,
    required this.metadata,
    required this.theme,
    this.staffSpace = 10.0, // Valor padrão mais compacto
  });

  static const Map<String, int> _stepToDiatonic = {
    'C': 0,
    'D': 1,
    'E': 2,
    'F': 3,
    'G': 4,
    'A': 5,
    'B': 6,
  };
  static const _sharpPositions = <int>[6, 3, 7, 4, 1, 5, 2];
  static const _flatPositions = <int>[2, 5, 1, 4, 0, 3, -1];

  @override
  void paint(Canvas canvas, Size size) {
    if (metadata.isNotLoaded) return;

    // CORREÇÃO: Usar o staffSpace passado como parâmetro em vez de calcular incorretamente

    // Otimização: ordena elementos para melhor performance
    final optimizedElements = PerformanceOptimizer.optimizeRenderOrder(
      positionedElements,
    );

    final systems = optimizedElements.map((e) => e.system).toSet();
    for (final system in systems) {
      // CORREÇÃO: Posicionamento escalável das linhas da pauta
      _drawStaffLinesOptimized(
        canvas,
        size.width,
        50.0 + (system * staffSpace * 8),
        staffSpace,
      );
    }

    Clef currentClef = Clef(type: 'g');

    for (int i = 0; i < optimizedElements.length; i++) {
      final pe = optimizedElements[i];
      final element = pe.element;
      final position = pe.position;

      if (element is Clef) {
        currentClef = element;
        _drawClef(canvas, element, position, staffSpace);
      } else if (element is KeySignature) {
        _drawKeySignature(canvas, element, position, staffSpace);
      } else if (element is TimeSignature) {
        _drawTimeSignature(canvas, element, position, staffSpace);
      } else if (element is Note) {
        if (element.tie == TieType.start) {
          PositionedElement? endNoteElement;
          for (int j = i + 1; j < optimizedElements.length; j++) {
            if (optimizedElements[j].element is Note) {
              endNoteElement = optimizedElements[j];
              break;
            }
          }
          if (endNoteElement != null) {
            _drawTie(canvas, pe, endNoteElement, currentClef, staffSpace);
          }
        }

        // --- LÓGICA DE DESENHO DE LIGADURAS (SLURS) ---
        if (element.slur == SlurType.start) {
          PositionedElement? endNoteElement;
          // Procura pela nota que termina a ligadura
          for (int j = i + 1; j < optimizedElements.length; j++) {
            final nextEl = optimizedElements[j].element;
            if (nextEl is Note && nextEl.slur == SlurType.end) {
              endNoteElement = optimizedElements[j];
              break;
            }
          }
          if (endNoteElement != null) {
            _drawSlur(canvas, pe, endNoteElement, currentClef, staffSpace);
          }
        }

        if (element.beam == BeamType.start) {
          final beamGroup = <PositionedElement>[pe];
          int j = i + 1;
          while (j < positionedElements.length) {
            final nextPe = positionedElements[j];
            final nextElement = nextPe.element;
            if (nextElement is Note && nextElement.beam != null) {
              beamGroup.add(nextPe);
              if (nextElement.beam == BeamType.end) {
                break;
              }
            } else {
              break;
            }
            j++;
          }
          _drawBeamGroup(canvas, beamGroup, currentClef, staffSpace);
          i = j;
        } else {
          _drawNote(canvas, element, currentClef, position, staffSpace);
        }

        // Desenhar acidentes se presente
        if (element.pitch.accidentalGlyph != null) {
          _drawAccidental(canvas, element, currentClef, position, staffSpace);
        }

        // === ELEMENTOS AVANÇADOS ===
      } else if (element is Chord) {
        drawChord(
          canvas,
          element,
          currentClef,
          position,
          staffSpace,
          metadata,
          theme,
        );
      } else if (element is Ornament) {
        drawOrnament(canvas, element, position, staffSpace, metadata, theme);
      } else if (element is Dynamic) {
        drawDynamic(canvas, element, position, staffSpace, metadata, theme);
      } else if (element is Breath) {
        drawBreath(canvas, element, position, staffSpace, metadata, theme);
      } else if (element is MusicText) {
        _drawMusicText(canvas, element, position, staffSpace, theme);
      } else if (element is TempoMark) {
        _drawTempoMark(canvas, element, position, staffSpace, theme);
      } else if (element is Tuplet) {
        _drawTuplet(canvas, element, i, optimizedElements, staffSpace, theme);
      } else if (element is Rest) {
        _drawRest(canvas, element, position, staffSpace);
      } else if (element is Barline) {
        _drawBarline(canvas, position, staffSpace);
      }
    }
  }

  /// Nova função para desenhar ligaduras de expressão (slurs)
  void _drawSlur(
    Canvas canvas,
    PositionedElement startPe,
    PositionedElement endPe,
    Clef clef,
    double staffSpace,
  ) {
    final startNote = startPe.element as Note;
    final endNote = endPe.element as Note;

    final startStaffPos = _calculateStaffPosition(startNote.pitch, clef);
    final endStaffPos = _calculateStaffPosition(endNote.pitch, clef);

    // Determina a direção da curva (acima ou abaixo) com base na média da posição das notas
    final bool curveGoesUp = ((startStaffPos + endStaffPos) / 2) < 0;
    final double verticalDirection = curveGoesUp
        ? -1.0
        : 1.0; // Invertido, curva vai por cima

    final startNoteY = startPe.position.dy - (startStaffPos * staffSpace / 2);
    final endNoteY = endPe.position.dy - (endStaffPos * staffSpace / 2);

    metadata.getGlyphBBox(startNote.duration.type.glyphName);

    final endBbox = metadata.getGlyphBBox(endNote.duration.type.glyphName);
    final endNoteheadWidth =
        (endBbox?['bBoxNE']?[0] ?? 0.0) * (staffSpace * 4 / 2048);

    // Pontos de início e fim da curva
    final startPoint = Offset(
      startPe.position.dx,
      startNoteY + (staffSpace * 0.7 * verticalDirection),
    );
    final endPoint = Offset(
      endPe.position.dx + endNoteheadWidth,
      endNoteY + (staffSpace * 0.7 * verticalDirection),
    );

    // O arco da curva é mais pronunciado para slurs do que para ties
    final double arcHeight =
        staffSpace * 1.5 + (endPoint.dx - startPoint.dx) * 0.05;

    // Pontos de controle para a Curva de Bézier
    final controlPoint1 = Offset(
      startPoint.dx + (endPoint.dx - startPoint.dx) * 0.25,
      startPoint.dy + (arcHeight * verticalDirection),
    );
    final controlPoint2 = Offset(
      endPoint.dx - (endPoint.dx - startPoint.dx) * 0.25,
      endPoint.dy + (arcHeight * verticalDirection),
    );

    final slurPaint = Paint()
      ..color = theme.noteheadColor
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          metadata.getEngravingDefault('thinBarlineThickness') * 1.5;

    final path = Path();
    path.moveTo(startPoint.dx, startPoint.dy);
    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      endPoint.dx,
      endPoint.dy,
    );

    canvas.drawPath(path, slurPaint);
  }

  void _drawTie(
    Canvas canvas,
    PositionedElement startPe,
    PositionedElement endPe,
    Clef clef,
    double staffSpace,
  ) {
    final startNote = startPe.element as Note;
    final startStaffPos = _calculateStaffPosition(startNote.pitch, clef);
    final bool stemsGoUp = startStaffPos < 0;
    final double verticalDirection = stemsGoUp ? 1.0 : -1.0;
    final startNoteY = startPe.position.dy - (startStaffPos * staffSpace / 2);
    final endNote = endPe.element as Note;
    final endStaffPos = _calculateStaffPosition(endNote.pitch, clef);
    final endNoteY = endPe.position.dy - (endStaffPos * staffSpace / 2);
    final startBbox = metadata.getGlyphBBox(startNote.duration.type.glyphName);
    final startNoteheadWidth =
        (startBbox?['bBoxNE']?[0] ?? 0.0) * (staffSpace * 4 / 2048);
    final startPoint = Offset(
      startPe.position.dx + startNoteheadWidth * 0.8,
      startNoteY,
    );
    final endPoint = Offset(endPe.position.dx, endNoteY);
    final controlPoint = Offset(
      (startPoint.dx + endPoint.dx) / 2,
      ((startPoint.dy + endPoint.dy) / 2) +
          (staffSpace * 1.2 * verticalDirection),
    );
    final tiePaint = Paint()
      ..color = theme.noteheadColor
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          metadata.getEngravingDefault('thinBarlineThickness') * 1.5;
    final path = Path();
    path.moveTo(startPoint.dx, startPoint.dy);
    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );
    canvas.drawPath(path, tiePaint);
  }

  void _drawBeamGroup(
    Canvas canvas,
    List<PositionedElement> group,
    Clef clef,
    double staffSpace,
  ) {
    if (group.isEmpty) return;
    double totalPosition = 0;
    for (final pe in group) {
      totalPosition += _calculateStaffPosition(
        (pe.element as Note).pitch,
        clef,
      );
    }
    bool stemsGoUp = (totalPosition / group.length) < 0;
    final stemPositions = <Offset>[];
    for (final pe in group) {
      final note = pe.element as Note;
      final position = pe.position;
      final staffPos = _calculateStaffPosition(note.pitch, clef);
      final noteY = position.dy - (staffPos * staffSpace / 2);
      _drawGlyph(
        canvas: canvas,
        glyphName: note.duration.type.glyphName,
        color: theme.noteheadColor,
        x: position.dx,
        y: noteY,
        fontSize: staffSpace * 3.5, // Tamanho consistente com outras notas
      );
      _drawArticulations(
        canvas,
        note,
        stemsGoUp,
        position.dx,
        noteY,
        staffSpace,
      );
      final bbox = metadata.getGlyphBBox(note.duration.type.glyphName);
      final noteheadWidth = (bbox?['bBoxNE']?[0] ?? 1.18) * staffSpace;
      final stemX = stemsGoUp ? position.dx + noteheadWidth : position.dx;
      stemPositions.add(Offset(stemX, noteY));
    }
    final stemHeight = staffSpace * 3.5;
    final beamThickness = staffSpace * 0.5;
    final firstStem = stemPositions.first;
    final lastStem = stemPositions.last;
    final firstStemEndY = stemsGoUp
        ? firstStem.dy - stemHeight
        : firstStem.dy + stemHeight;
    final lastStemEndY = stemsGoUp
        ? lastStem.dy - stemHeight
        : lastStem.dy + stemHeight;
    final beamPaint = Paint()
      ..color = theme.stemColor
      ..strokeWidth = beamThickness
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(
      Offset(firstStem.dx, firstStemEndY),
      Offset(lastStem.dx, lastStemEndY),
      beamPaint,
    );
    final stemPaint = Paint()
      ..color = theme.stemColor
      ..strokeWidth = metadata.getEngravingDefault('stemThickness');
    for (final stemPos in stemPositions) {
      final yBeam = lerpDouble(
        firstStemEndY,
        lastStemEndY,
        (stemPos.dx - firstStem.dx) / (lastStem.dx - firstStem.dx),
      )!;
      canvas.drawLine(
        Offset(stemPos.dx, stemPos.dy),
        Offset(stemPos.dx, yBeam),
        stemPaint,
      );
    }
  }

  void _drawNote(
    Canvas canvas,
    Note note,
    Clef clef,
    Offset position,
    double staffSpace,
  ) {
    // CORREÇÃO: Usar StaffCoordinateSystem para calcular Y correto
    final system = _getSystemFromPosition(position);
    final systemY = 50.0 + (system * staffSpace * 8);
    final staffBaseline = Offset(0, systemY + (2 * staffSpace)); // 3ª linha da pauta

    final coordSystem = StaffCoordinateSystem(
      staffSpace: staffSpace,
      staffBaseline: staffBaseline,
    );

    final noteY = coordSystem.getNoteY(note.pitch.step, note.pitch.octave);
    final glyphName = note.duration.type.glyphName;

    // Regra profissional: hastes para cima se a nota estiver na metade inferior do pentagrama
    final staffPosition = _calculateStaffPosition(note.pitch, clef);
    bool stemsGoUp = staffPosition >
        0; // Corrigido: > 0 para hastes para cima quando abaixo da linha central

    // Desenha a cabeça da nota
    // Baseado nos metadados Bravura: noteheadBlack bBoxSW: [0.0, -0.5], bBoxNE: [1.18, 0.5]
    _drawGlyph(
      canvas: canvas,
      glyphName: glyphName,
      color: theme.noteheadColor,
      x: position.dx,
      y: noteY,
      fontSize: staffSpace * 3.5, // Tamanho apropriado para notas
    );

    _drawArticulations(canvas, note, stemsGoUp, position.dx, noteY, staffSpace);

    if (note.duration.type != DurationType.whole) {
      final stemHeight = staffSpace * 3.5;
      final stemThickness = metadata.getEngravingDefault('stemThickness');
      final stemPaint = Paint()
        ..color = theme.stemColor
        ..strokeWidth = stemThickness;

      // Obtém as dimensões precisas da cabeça da nota
      final bbox = metadata.getGlyphBBox(glyphName);
      // Usando valores dos metadados da Bravura para noteheadBlack: width=1.18, height=1.0 em staff spaces
      final noteheadWidth = (bbox?['bBoxNE']?[0] ?? 1.18) * staffSpace;
      final noteheadHeight = (bbox?['bBoxNE']?[1] ?? 0.5) * staffSpace;

      // Posicionamento preciso da haste
      double stemX;
      if (stemsGoUp) {
        // Haste no lado direito da cabeça da nota
        stemX = position.dx + noteheadWidth * 0.9;
      } else {
        // Haste no lado esquerdo da cabeça da nota
        stemX = position.dx + noteheadWidth * 0.1;
      }

      // Ponto de conexão da haste com a cabeça da nota
      double stemStartY;
      if (stemsGoUp) {
        // Conecta no topo da cabeça da nota
        stemStartY = noteY - noteheadHeight * 0.1;
      } else {
        // Conecta na base da cabeça da nota
        stemStartY = noteY + noteheadHeight * 0.1;
      }

      double stemEndY = stemsGoUp
          ? stemStartY - stemHeight
          : stemStartY + stemHeight;

      canvas.drawLine(
        Offset(stemX, stemStartY),
        Offset(stemX, stemEndY),
        stemPaint,
      );

      // Bandeirolas para notas não agrupadas
      if (note.beam == null && note.duration.type.value < 1.0) {
        final flagGlyph = note.duration.type == DurationType.eighth
            ? (stemsGoUp ? 'flag8thUp' : 'flag8thDown')
            : (stemsGoUp ? 'flag16thUp' : 'flag16thDown');

        // Posicionamento preciso da bandeirola
        double flagX = stemX;
        double flagY = stemEndY;

        if (!stemsGoUp) {
          // Para hastes para baixo, ajusta o posicionamento da bandeirola
          flagX -= noteheadWidth * 0.1;
        }

        _drawGlyph(
          canvas: canvas,
          glyphName: flagGlyph,
          color: theme.stemColor,
          x: flagX,
          y: flagY,
          fontSize: staffSpace * 3.5, // Tamanho proporcional às notas
        );
      }
    }
  }

  void _drawArticulations(
    Canvas canvas,
    Note note,
    bool stemsGoUp,
    double noteX,
    double noteY,
    double staffSpace,
  ) {
    if (note.articulations.isEmpty) return;
    final yDirection = stemsGoUp ? -1 : 1;
    final yOffset = staffSpace * 1.5 * yDirection;
    final articulationGlyphs = {
      ArticulationType.staccato: stemsGoUp
          ? 'articStaccatoBelow'
          : 'articStaccatoAbove',
      ArticulationType.accent: stemsGoUp
          ? 'articAccentBelow'
          : 'articAccentAbove',
      ArticulationType.tenuto: stemsGoUp
          ? 'articTenutoBelow'
          : 'articTenutoAbove',
    };
    for (final articulation in note.articulations) {
      final glyphName = articulationGlyphs[articulation];
      if (glyphName != null) {
        _drawGlyph(
          canvas: canvas,
          glyphName: glyphName,
          color: theme.articulationColor,
          x: noteX,
          y: noteY + yOffset,
          fontSize: staffSpace * 4,
        );
      }
    }
  }

  void _drawStaffLinesOptimized(
    Canvas canvas,
    double width,
    double y,
    double staffSpace,
  ) {
    final path = PerformanceOptimizer.getStaffLinesPath(
      width,
      y - (2 * staffSpace),
      staffSpace,
    );
    final paint = PerformanceOptimizer.getPaint(
      color: theme.staffLineColor,
      strokeWidth: metadata.getEngravingDefault('staffLineThickness'),
      style: PaintingStyle.stroke,
    );

    canvas.drawPath(path, paint);
    PerformanceOptimizer.returnPaint(paint);
  }

  void _drawClef(Canvas canvas, Clef clef, Offset position, double staffSpace) {
    // A clave de sol deve ser posicionada de forma que sua linha da clave (2ª linha) fique no centro da pauta
    // Segundo metadados Bravura: bBoxSW: [0.0, -2.632], bBoxNE: [2.684, 4.392]
    // A clave precisa ser ajustada para que o ponto de referência fique na 2ª linha da pauta
    _drawGlyph(
      canvas: canvas,
      glyphName: 'gClef',
      color: theme.clefColor,
      x: position.dx,
      y:
          position.dy -
          (staffSpace * 0.5), // Ajuste para alinhar com a 2ª linha da pauta
      fontSize: staffSpace * 4,
    );
  }

  void _drawKeySignature(
    Canvas canvas,
    KeySignature ks,
    Offset position,
    double staffSpace,
  ) {
    final positions = ks.count > 0 ? _sharpPositions : _flatPositions;
    final glyphName = ks.count > 0 ? 'accidentalSharp' : 'accidentalFlat';
    final count = ks.count.abs();
    double currentX = position.dx;
    for (int i = 0; i < count; i++) {
      final staffPosition = positions[i];
      // Posicionamento correto baseado na posição das linhas da pauta
      // staffPosition representa a posição relativa às linhas da pauta (0 = 3ª linha)
      final y = position.dy - (staffPosition * staffSpace / 2);
      _drawGlyph(
        canvas: canvas,
        glyphName: glyphName,
        color: theme.keySignatureColor,
        x: currentX,
        y: y,
        fontSize: staffSpace * 3.5, // Tamanho ligeiramente menor para acidentes
      );
      currentX += staffSpace * 0.6; // Espaçamento mais apertado entre acidentes
    }
  }

  void _drawTimeSignature(
    Canvas canvas,
    TimeSignature ts,
    Offset position,
    double staffSpace,
  ) {
    final numGlyph = 'timeSig${ts.numerator}';
    final denGlyph = 'timeSig${ts.denominator}';
    // Posicionamento padrão SMuFL: números centralizados na pauta
    // Numerador na posição da 4ª linha (1 staff space acima do centro)
    // Denominador na posição da 2ª linha (1 staff space abaixo do centro)
    _drawGlyph(
      canvas: canvas,
      glyphName: numGlyph,
      color: theme.timeSignatureColor,
      x: position.dx,
      y:
          position.dy -
          (0.75 * staffSpace), // Numerador ligeiramente acima do centro
      fontSize: staffSpace * 2.5, // Tamanho apropriado para fórmula de compasso
    );
    _drawGlyph(
      canvas: canvas,
      glyphName: denGlyph,
      color: theme.timeSignatureColor,
      x: position.dx,
      y:
          position.dy +
          (0.75 * staffSpace), // Denominador ligeiramente abaixo do centro
      fontSize: staffSpace * 2.5, // Tamanho apropriado para fórmula de compasso
    );
  }

  void _drawRest(Canvas canvas, Rest rest, Offset position, double staffSpace) {
    String glyphName;
    double yOffset;
    switch (rest.duration.type) {
      case DurationType.whole:
        glyphName = 'restWhole';
        yOffset = -staffSpace;
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
    }
    final y = position.dy + yOffset;
    _drawGlyph(
      canvas: canvas,
      glyphName: glyphName,
      color: theme.restColor,
      x: position.dx,
      y: y,
      fontSize: staffSpace * 4,
    );
  }

  void _drawBarline(Canvas canvas, Offset position, double staffSpace) {
    final linePaint = Paint()
      ..color = theme.barlineColor
      ..strokeWidth = metadata.getEngravingDefault('thinBarlineThickness');
    final startY = position.dy - (2 * staffSpace);
    final endY = position.dy + (2 * staffSpace);
    canvas.drawLine(
      Offset(position.dx, startY),
      Offset(position.dx, endY),
      linePaint,
    );
  }

  int _calculateStaffPosition(Pitch pitch, Clef clef) {
    if (clef.type != 'g') return 0;
    const int baseStep = 4;
    const int baseOctave = 4;
    const int basePosition = -2;
    int pitchStep = _stepToDiatonic[pitch.step]!;
    int diatonicDistance =
        (pitchStep - baseStep) + ((pitch.octave - baseOctave) * 7);
    return basePosition + diatonicDistance;
  }

  void _drawGlyph({
    required Canvas canvas,
    required String glyphName,
    required Color color,
    required double x,
    required double y,
    required double fontSize,
  }) {
    // Otimização: usa renderização otimizada de SMuFL
    final character = metadata.getCodepoint(glyphName);
    if (character.isNotEmpty) {
      PerformanceOptimizer.drawOptimizedSmuflText(
        canvas,
        character,
        Offset(x, y),
        fontSize,
        color,
      );
    }
  }

  // Métodos auxiliares para elementos avançados
  void _drawAccidental(
    Canvas canvas,
    Note note,
    Clef clef,
    Offset position,
    double staffSpace,
  ) {
    if (note.pitch.accidentalGlyph == null) return;

    final staffPosition = _calculateStaffPosition(note.pitch, clef);
    final noteY = position.dy - (staffPosition * staffSpace / 2);
    final accidentalX =
        position.dx - staffSpace * 1.5; // Posição à esquerda da nota

    _drawGlyph(
      canvas: canvas,
      glyphName: note.pitch.accidentalGlyph!,
      color: theme.accidentalColor ?? theme.noteheadColor,
      x: accidentalX,
      y: noteY,
      fontSize: staffSpace * 4,
    );
  }

  void _drawMusicText(
    Canvas canvas,
    MusicText text,
    Offset position,
    double staffSpace,
    MusicScoreTheme theme,
  ) {
    TextStyle style =
        theme.textStyle ?? const TextStyle(color: Colors.black, fontSize: 12);

    switch (text.type) {
      case TextType.dynamics:
        style = theme.dynamicTextStyle ?? style;
        break;
      case TextType.tempo:
        style = theme.tempoTextStyle ?? style;
        break;
      case TextType.expression:
        style = theme.expressionTextStyle ?? style;
        break;
      case TextType.lyrics:
        style = theme.lyricTextStyle ?? style;
        break;
      case TextType.chord:
        style = theme.chordTextStyle ?? style;
        break;
      case TextType.rehearsal:
        style = theme.rehearsalTextStyle ?? style;
        break;
      default:
        break;
    }

    if (text.fontFamily != null) {
      style = style.copyWith(fontFamily: text.fontFamily);
    }
    if (text.fontSize != null) {
      style = style.copyWith(fontSize: text.fontSize);
    }
    if (text.bold == true) {
      style = style.copyWith(fontWeight: FontWeight.bold);
    }
    if (text.italic == true) {
      style = style.copyWith(fontStyle: FontStyle.italic);
    }

    final textPainter = TextPainter(
      text: TextSpan(text: text.text, style: style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    double yOffset = 0;
    switch (text.placement) {
      case TextPlacement.above:
        yOffset = -staffSpace * 2;
        break;
      case TextPlacement.below:
        yOffset = staffSpace * 3;
        break;
      case TextPlacement.inside:
        yOffset = 0;
        break;
    }

    final offset = Offset(
      position.dx - textPainter.width / 2,
      position.dy + yOffset - textPainter.height / 2,
    );

    textPainter.paint(canvas, offset);
  }

  void _drawTempoMark(
    Canvas canvas,
    TempoMark tempo,
    Offset position,
    double staffSpace,
    MusicScoreTheme theme,
  ) {
    String text = '';

    if (tempo.text != null) {
      text = tempo.text!;
    }

    if (tempo.bpm != null) {
      if (text.isNotEmpty) text += ' ';

      // Adiciona símbolo da nota e BPM
      final noteSymbol = _getDurationSymbol(tempo.beatUnit);
      text += '$noteSymbol = ${tempo.bpm}';
    }

    if (text.isNotEmpty) {
      final style =
          theme.tempoTextStyle ??
          const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          );

      final textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final offset = Offset(
        position.dx,
        position.dy - staffSpace * 3 - textPainter.height,
      );

      textPainter.paint(canvas, offset);
    }
  }

  String _getDurationSymbol(DurationType type) {
    switch (type) {
      case DurationType.whole:
        return '𝅝';
      case DurationType.half:
        return '𝅗𝅥';
      case DurationType.quarter:
        return '♩';
      case DurationType.eighth:
        return '♪';
      case DurationType.sixteenth:
        return '𝅘𝅥𝅯';
    }
  }

  /// Desenha quiálteras (tuplets)
  void _drawTuplet(
    Canvas canvas,
    Tuplet tuplet,
    int currentIndex,
    List<PositionedElement> elements,
    double staffSpace,
    MusicScoreTheme theme,
  ) {
    // Coleta as posições dos elementos da quiáltera
    final List<Offset> positions = [];

    // Adiciona a posição do elemento atual (que é a própria tuplet)
    positions.add(elements[currentIndex].position);

    // Procura pelos elementos subsequentes da quiáltera
    for (int i = 0; i < tuplet.elements.length; i++) {
      if (currentIndex + i + 1 < elements.length) {
        positions.add(elements[currentIndex + i + 1].position);
      }
    }

    // Usa o método do mixin para desenhar a quiáltera
    if (positions.isNotEmpty) {
      drawTuplet(canvas, tuplet, positions, staffSpace, theme);
    }
  }

  // Método auxiliar para obter o sistema (linha de pauta) de uma posição
  int _getSystemFromPosition(Offset position) {
    // Cada sistema tem altura de staffSpace * 8
    return ((position.dy - 50.0) / (staffSpace * 8)).floor();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
