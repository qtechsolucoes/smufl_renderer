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

  // Sistema de rastreamento de clave atual
  Clef currentClef = Clef(clefType: ClefType.treble);

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
  // Posições para clave de Sol (G clef)
  static const _sharpPositions = <int>[6, 3, 7, 4, 1, 5, 2];
  static const _flatPositions = <int>[2, 5, 1, 4, 0, 3, -1];

  // Posições para clave de Fá (F clef)
  static const _sharpPositionsBass = <int>[4, 1, 5, 2, -1, 3, 0];
  static const _flatPositionsBass = <int>[0, 3, -1, 2, -2, 1, -3];

  // Posições para clave de Dó (C clef)
  static const _sharpPositionsAlto = <int>[5, 2, 6, 3, 0, 4, 1];
  static const _flatPositionsAlto = <int>[1, 4, 0, 3, -1, 2, -2];

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

    // Usa a clave atual armazenada na instância
    Clef localCurrentClef = currentClef;

    for (int i = 0; i < optimizedElements.length; i++) {
      final pe = optimizedElements[i];
      final element = pe.element;
      final position = pe.position;

      if (element is Clef) {
        localCurrentClef = element;
        currentClef = element; // Atualiza a clave na instância
        _drawClef(canvas, element, position, staffSpace);
      } else if (element is KeySignature) {
        _drawKeySignature(
          canvas,
          element,
          localCurrentClef,
          position,
          staffSpace,
        );
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
            _drawTie(canvas, pe, endNoteElement, localCurrentClef, staffSpace);
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
            _drawSlur(canvas, pe, endNoteElement, localCurrentClef, staffSpace);
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
          _drawBeamGroup(canvas, beamGroup, localCurrentClef, staffSpace);
          i = j;
        } else {
          _drawNote(canvas, element, localCurrentClef, position, staffSpace);
        }

        // Desenhar acidentes se presente
        if (element.pitch.accidentalGlyph != null) {
          _drawAccidental(
            canvas,
            element,
            localCurrentClef,
            position,
            staffSpace,
          );
        }

        // === ELEMENTOS AVANÇADOS ===
      } else if (element is Chord) {
        drawChord(
          canvas,
          element,
          localCurrentClef,
          position,
          staffSpace,
          metadata,
          theme,
        );
      } else if (element is Ornament) {
        drawOrnament(
          canvas,
          element,
          position,
          staffSpace,
          metadata,
          theme,
          'noteheadBlack',
        );
      } else if (element is Dynamic) {
        drawDynamic(
          canvas,
          element,
          position,
          staffSpace,
          metadata,
          theme,
          'noteheadBlack',
        );
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

    // Usar metadados SMuFL para dimensões precisas
    final beamThickness =
        metadata.getEngravingDefault('beamThickness') * staffSpace;
    final beamSpacing =
        metadata.getEngravingDefault('beamSpacing') * staffSpace;

    final firstStem = stemPositions.first;
    final lastStem = stemPositions.last;
    final firstStemEndY = stemsGoUp
        ? firstStem.dy - stemHeight
        : firstStem.dy + stemHeight;
    final lastStemEndY = stemsGoUp
        ? lastStem.dy - stemHeight
        : lastStem.dy + stemHeight;

    // Determinar quantos beams são necessários
    final noteDurations = group
        .map((pe) => (pe.element as Note).duration.type)
        .toList();
    final maxBeams = noteDurations
        .map(_getBeamCount)
        .reduce((a, b) => a > b ? a : b);

    final beamPaint = Paint()
      ..color = theme.stemColor
      ..strokeWidth = beamThickness
      ..strokeCap = StrokeCap.butt;

    final stemPaint = Paint()
      ..color = theme.stemColor
      ..strokeWidth =
          metadata.getEngravingDefault('stemThickness') * staffSpace;

    // Desenhar hastes
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

    // Desenhar beams (barras horizontais)
    for (int beamLevel = 0; beamLevel < maxBeams; beamLevel++) {
      final beamOffset =
          beamLevel * (beamThickness + beamSpacing) * (stemsGoUp ? 1 : -1);

      double startY = firstStemEndY + beamOffset;
      double endY = lastStemEndY + beamOffset;

      // Beam principal (conecta todas as notas)
      if (beamLevel == 0) {
        canvas.drawLine(
          Offset(firstStem.dx, startY),
          Offset(lastStem.dx, endY),
          beamPaint,
        );
      } else {
        // Beams secundários (para semicolcheias, fusas, etc.)
        _drawSecondaryBeams(
          canvas,
          beamPaint,
          stemPositions,
          noteDurations,
          beamLevel,
          startY,
          endY,
          firstStem,
          lastStem,
        );
      }
    }
  }

  /// Desenha beams secundários para figuras menores que colcheias
  void _drawSecondaryBeams(
    Canvas canvas,
    Paint beamPaint,
    List<Offset> stemPositions,
    List<DurationType> noteDurations,
    int beamLevel,
    double startY,
    double endY,
    Offset firstStem,
    Offset lastStem,
  ) {
    for (int i = 0; i < noteDurations.length; i++) {
      final beamCount = _getBeamCount(noteDurations[i]);

      if (beamCount > beamLevel) {
        final stemPos = stemPositions[i];
        final yBeam = lerpDouble(
          startY,
          endY,
          (stemPos.dx - firstStem.dx) / (lastStem.dx - firstStem.dx),
        )!;

        // Determinar se deve conectar com a próxima nota
        bool connectToNext = false;
        if (i < noteDurations.length - 1) {
          final nextBeamCount = _getBeamCount(noteDurations[i + 1]);
          connectToNext = nextBeamCount > beamLevel;
        }

        if (connectToNext) {
          // Conectar com a próxima haste
          final nextStemPos = stemPositions[i + 1];
          final nextYBeam = lerpDouble(
            startY,
            endY,
            (nextStemPos.dx - firstStem.dx) / (lastStem.dx - firstStem.dx),
          )!;

          canvas.drawLine(
            Offset(stemPos.dx, yBeam),
            Offset(nextStemPos.dx, nextYBeam),
            beamPaint,
          );
        } else {
          // Beam curto (hook)
          final hookLength = (lastStem.dx - firstStem.dx) * 0.15;
          canvas.drawLine(
            Offset(stemPos.dx, yBeam),
            Offset(stemPos.dx + hookLength, yBeam),
            beamPaint,
          );
        }
      }
    }
  }

  /// Retorna o número de beams necessários para uma duração
  int _getBeamCount(DurationType durationType) {
    switch (durationType) {
      case DurationType.eighth:
        return 1;
      case DurationType.sixteenth:
        return 2;
      case DurationType.thirtySecond:
        return 3;
      case DurationType.sixtyFourth:
        return 4;
      default:
        return 0;
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
    final staffBaseline = Offset(
      0,
      systemY + (2 * staffSpace),
    ); // 3ª linha da pauta

    final coordSystem = StaffCoordinateSystem(
      staffSpace: staffSpace,
      staffBaseline: staffBaseline,
    );

    final noteY = coordSystem.getNoteY(note.pitch.step, note.pitch.octave);
    final glyphName = note.duration.type.glyphName;

    // Regra profissional: hastes para cima se a nota estiver na metade inferior do pentagrama
    final staffPosition = _calculateStaffPosition(note.pitch, clef);
    bool stemsGoUp =
        staffPosition >
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

    // Desenhar ornamentos da nota
    _drawNoteOrnaments(canvas, note, position.dx, noteY, staffSpace);

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

    // Desenhar pontos de aumento (augmentation dots)
    if (note.duration.dots > 0) {
      _drawAugmentationDots(canvas, note, position, noteY, staffSpace);
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

    // CORRIGIDO: Regras corretas de posicionamento
    // Haste para cima → articulação ABAIXO da nota
    // Haste para baixo → articulação ACIMA da nota
    // Sem haste (semibreve) → articulação ACIMA da nota
    final articulationsGoBelow =
        stemsGoUp || note.duration.type == DurationType.whole;

    // Usar âncoras SMuFL para posicionamento preciso
    final noteGlyph = note.duration.type.glyphName;
    // final glyphInfo = metadata.getGlyphInfo(noteGlyph);

    // Calcular posição centralizada na cabeça da nota
    // Obter dimensões da cabeça da nota
    final bbox = metadata.getGlyphBBox(noteGlyph);
    final noteheadHeight = (bbox?['bBoxNE']?[1] ?? 0.5) * staffSpace;
    final noteheadWidth = (bbox?['bBoxNE']?[0] ?? 1.18) * staffSpace;

    // Posicionamento: um pouco acima/abaixo da cabeça da nota
    double yOffset;
    if (articulationsGoBelow) {
      // Haste para cima: articulação abaixo da nota
      yOffset =
          noteheadHeight * 0.5 + staffSpace * 0.4; // Um pouco abaixo da cabeça
    } else {
      // Haste para baixo ou semibreve: articulação acima da nota
      yOffset =
          -(noteheadHeight * 0.5 +
              staffSpace * 0.4); // Um pouco acima da cabeça
    }

    final articulationGlyphs = {
      ArticulationType.staccato: articulationsGoBelow
          ? 'articStaccatoBelow'
          : 'articStaccatoAbove',
      ArticulationType.staccatissimo: articulationsGoBelow
          ? 'articStaccatissimoBelow'
          : 'articStaccatissimoAbove',
      ArticulationType.accent: articulationsGoBelow
          ? 'articAccentBelow'
          : 'articAccentAbove',
      ArticulationType.strongAccent: articulationsGoBelow
          ? 'articAccentBelow'
          : 'articAccentAbove',
      ArticulationType.tenuto: articulationsGoBelow
          ? 'articTenutoBelow'
          : 'articTenutoAbove',
      ArticulationType.marcato: articulationsGoBelow
          ? 'articMarcatoBelow'
          : 'articMarcatoAbove',
      ArticulationType.legato: articulationsGoBelow
          ? 'articTenutoBelow'
          : 'articTenutoAbove',
      ArticulationType.portato: articulationsGoBelow
          ? 'articTenutoStaccatoBelow'
          : 'articTenutoStaccatoAbove',

      // Técnicas de cordas - posicionamento especial
      ArticulationType.upBow: 'stringsUpBow',
      ArticulationType.downBow: 'stringsDownBow',
      ArticulationType.harmonics: 'stringsHarmonic',

      ArticulationType.pizzicato: articulationsGoBelow
          ? 'pluckedPizzicatoBelow'
          : 'pluckedPizzicatoAbove',
      ArticulationType.snap: articulationsGoBelow
          ? 'pluckedSnapPizzicatoBelow'
          : 'pluckedSnapPizzicatoAbove',
      ArticulationType.thumb: articulationsGoBelow
          ? 'pluckedThumbPositionBelow'
          : 'pluckedThumbPositionAbove',
      ArticulationType.stopped: articulationsGoBelow
          ? 'brassMuteClosedBelow'
          : 'brassMuteClosedAbove',
      ArticulationType.open: articulationsGoBelow
          ? 'brassMuteOpenBelow'
          : 'brassMuteOpenAbove',
      ArticulationType.halfStopped: articulationsGoBelow
          ? 'brassMuteHalfClosedBelow'
          : 'brassMuteHalfClosedAbove',
    };
    for (final articulation in note.articulations) {
      final glyphName = articulationGlyphs[articulation];
      if (glyphName != null) {
        // Centralizar a articulação na cabeça da nota
        final articulationX = noteX + (noteheadWidth / 2);

        _drawGlyph(
          canvas: canvas,
          glyphName: glyphName,
          color: theme.articulationColor,
          x: articulationX,
          y: noteY + yOffset,
          fontSize: staffSpace * 2, // Tamanho menor para melhor proporção
        );
      }
    }
  }

  /// Desenha pontos de aumento conforme especificações SMuFL
  void _drawAugmentationDots(
    Canvas canvas,
    Note note,
    Offset position,
    double noteY,
    double staffSpace,
  ) {
    if (note.duration.dots == 0) return;

    // Configurações conforme especificações SMuFL
    const glyphName = 'augmentationDot';
    final dotSize = staffSpace * 0.8;

    // Usar metadados SMuFL para posicionamento preciso
    final noteGlyph = note.duration.type.glyphName;
    final noteGlyphInfo = metadata.getGlyphInfo(noteGlyph);

    double startX;
    if (noteGlyphInfo?.boundingBox != null) {
      // Usar bounding box exata da nota
      final noteWidth = noteGlyphInfo!.boundingBox!.bBoxNeX * staffSpace;
      startX = position.dx + noteWidth + (staffSpace * 0.2);
    } else {
      // Fallback
      final bbox = metadata.getGlyphBBox(noteGlyph);
      final noteheadWidth = (bbox?['bBoxNE']?[0] ?? 1.18) * staffSpace;
      startX = position.dx + noteheadWidth + (staffSpace * 0.2);
    }

    // Verificar se a nota está em linha (posição Y múltipla de staffSpace/2)
    final staffPosition = _calculateStaffPosition(
      note.pitch,
      _getCurrentClef(),
    );
    final isOnLine = (staffPosition % 2) == 0;

    // Se estiver em linha, deslocar o ponto para o espaço acima
    final dotY = isOnLine ? noteY - (staffSpace * 0.25) : noteY;

    // Desenhar os pontos
    for (int i = 0; i < note.duration.dots; i++) {
      final dotX = startX + (i * staffSpace * 0.7); // Espaçamento entre pontos

      _drawGlyph(
        canvas: canvas,
        glyphName: glyphName,
        color: theme.noteheadColor,
        x: dotX,
        y: dotY,
        fontSize: dotSize,
      );
    }
  }

  /// Retorna a clave atual
  Clef _getCurrentClef() {
    return currentClef;
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
    // Usar metadados SMuFL para posicionamento preciso
    final glyphName = clef.glyphName;
    final glyphInfo = metadata.getGlyphInfo(glyphName);
    final referencePosition = clef.referenceLinePosition;

    // Calcular offset Y baseado na posição de referência da clave
    // Cada posição representa meio staff space
    final yOffset = -referencePosition * (staffSpace / 2);

    // Usar bounding box dos metadados SMuFL para dimensionamento correto
    double fontSize = staffSpace * 4;
    double additionalYOffset = 0.0;

    if (glyphInfo?.boundingBox != null) {
      final bbox = glyphInfo!.boundingBox!;
      // Calcular tamanho baseado na altura do glifo
      final glyphHeight = (bbox.bBoxNeY - bbox.bBoxSwY);
      if (glyphHeight > 0) {
        fontSize =
            staffSpace *
            4.0 *
            (glyphHeight / 4.0); // Normalizar para altura de 4 staff spaces
      }

      // Ajustar posição vertical baseada no centro do glifo
      final glyphCenter = (bbox.bBoxNeY + bbox.bBoxSwY) / 2;
      additionalYOffset = -glyphCenter * staffSpace;
    } else {
      // Fallback para ajustes manuais por tipo
      switch (clef.actualClefType) {
        case ClefType.treble: // Claves de Sol
          additionalYOffset = -staffSpace * 0.5;
          break;
        case ClefType.bass:
        case ClefType.bassThirdLine:
        case ClefType.bass8va:
        case ClefType.bass8vb:
        case ClefType.bass15ma:
        case ClefType.bass15mb:
          additionalYOffset = staffSpace * 0.3;
          break;
        case ClefType.soprano:
        case ClefType.mezzoSoprano:
        case ClefType.alto:
        case ClefType.tenor:
        case ClefType.baritone:
        case ClefType.c8vb:
          additionalYOffset = 0.0;
          break;
        default:
          additionalYOffset = 0.0;
          fontSize = staffSpace * 3;
          break;
      }
    }

    _drawGlyph(
      canvas: canvas,
      glyphName: glyphName,
      color: theme.clefColor,
      x: position.dx,
      y: position.dy + yOffset + additionalYOffset,
      fontSize: fontSize,
    );

    // Desenhar indicações de oitava se necessário
    if (clef.octaveShift != 0) {
      _drawOctaveIndication(canvas, clef, position, staffSpace);
    }
  }

  void _drawOctaveIndication(
    Canvas canvas,
    Clef clef,
    Offset position,
    double staffSpace,
  ) {
    String octaveText = '';
    double yOffset = 0.0;

    switch (clef.octaveShift.abs()) {
      case 1:
        octaveText = '8';
        break;
      case 2:
        octaveText = '15';
        break;
    }

    if (octaveText.isNotEmpty) {
      // Posição acima ou abaixo da clave dependendo do tipo
      yOffset = clef.octaveShift > 0 ? -staffSpace * 3 : staffSpace * 3;

      final textStyle = TextStyle(
        fontSize: staffSpace * 1.2,
        color: theme.clefColor,
        fontWeight: FontWeight.bold,
      );

      final textPainter = TextPainter(
        text: TextSpan(text: octaveText, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final textOffset = Offset(
        position.dx + staffSpace,
        position.dy + yOffset - textPainter.height / 2,
      );

      textPainter.paint(canvas, textOffset);
    }
  }

  void _drawKeySignature(
    Canvas canvas,
    KeySignature ks,
    Clef currentClef,
    Offset position,
    double staffSpace,
  ) {
    final count = ks.count.abs();
    if (count == 0) return;

    final isSharp = ks.count > 0;
    final glyphName = isSharp ? 'accidentalSharp' : 'accidentalFlat';

    // Obter posições específicas para a clave atual
    final positions = _getKeySignaturePositions(
      currentClef.actualClefType.name,
      isSharp,
    );

    double currentX = position.dx;
    for (int i = 0; i < count && i < positions.length; i++) {
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

  /// Retorna as posições corretas dos acidentes na armadura baseado no tipo de clave
  List<int> _getKeySignaturePositions(String clefType, bool isSharp) {
    switch (clefType) {
      case 'g': // Clave de Sol
        return isSharp ? _sharpPositions : _flatPositions;
      case 'f': // Clave de Fá
        return isSharp ? _sharpPositionsBass : _flatPositionsBass;
      case 'c': // Clave de Dó
        return isSharp ? _sharpPositionsAlto : _flatPositionsAlto;
      default:
        return isSharp ? _sharpPositions : _flatPositions;
    }
  }

  void _drawTimeSignature(
    Canvas canvas,
    TimeSignature ts,
    Offset position,
    double staffSpace,
  ) {
    // Verificar se é compasso comum (C) ou cortado (Φ)
    if (ts.numerator == 4 && ts.denominator == 4) {
      // Pode usar timeSigCommon se disponível
      if (metadata.hasGlyph('timeSigCommon')) {
        _drawGlyph(
          canvas: canvas,
          glyphName: 'timeSigCommon',
          color: theme.timeSignatureColor,
          x: position.dx,
          y: position.dy,
          fontSize: staffSpace * 4,
        );
        return;
      }
    } else if (ts.numerator == 2 && ts.denominator == 2) {
      // Pode usar timeSigCutCommon se disponível
      if (metadata.hasGlyph('timeSigCutCommon')) {
        _drawGlyph(
          canvas: canvas,
          glyphName: 'timeSigCutCommon',
          color: theme.timeSignatureColor,
          x: position.dx,
          y: position.dy,
          fontSize: staffSpace * 4,
        );
        return;
      }
    }

    // Desenho padrão com números
    final numGlyph = _getTimeSignatureGlyph(ts.numerator);
    final denGlyph = _getTimeSignatureGlyph(ts.denominator);

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
          (1.0 * staffSpace), // Numerador ligeiramente acima do centro
      fontSize: staffSpace * 3.5, // Tamanho apropriado para fórmula de compasso
    );
    _drawGlyph(
      canvas: canvas,
      glyphName: denGlyph,
      color: theme.timeSignatureColor,
      x: position.dx,
      y:
          position.dy +
          (1.0 * staffSpace), // Denominador ligeiramente abaixo do centro
      fontSize: staffSpace * 3.5, // Tamanho apropriado para fórmula de compasso
    );
  }

  /// Retorna o glifo SMuFL apropriado para um número de fórmula de compasso
  String _getTimeSignatureGlyph(int number) {
    // Verificar se o glifo específico existe, senão usar genérico
    final glyphName = 'timeSig$number';
    return metadata.hasGlyph(glyphName) ? glyphName : 'timeSig0';
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
    // Cálculo baseado no novo sistema de claves
    int baseStep, baseOctave, basePosition;

    switch (clef.actualClefType) {
      case ClefType.treble: // Clave de Sol
        baseStep = 4; // G
        baseOctave = 4;
        basePosition = clef.referenceLinePosition; // Sol na 2ª linha
        break;
      case ClefType.bass:
      case ClefType.bassThirdLine:
      case ClefType.bass8va:
      case ClefType.bass8vb:
      case ClefType.bass15ma:
      case ClefType.bass15mb:
        baseStep = 3; // F
        baseOctave = 3;
        basePosition = clef.referenceLinePosition; // Fá na 4ª linha
        break;
      case ClefType.soprano:
      case ClefType.mezzoSoprano:
      case ClefType.alto:
      case ClefType.tenor:
      case ClefType.baritone:
      case ClefType.c8vb:
        baseStep = 0; // C
        baseOctave = 4;
        basePosition = clef.referenceLinePosition; // Varia conforme a posição
        break;
      default:
        return 0;
    }

    int pitchStep = _stepToDiatonic[pitch.step]!;
    int diatonicDistance =
        (pitchStep - baseStep) +
        ((pitch.octave + clef.octaveShift - baseOctave) * 7);
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

    // Calcular posição X baseada na largura da nota e do acidente
    final noteGlyph = note.duration.type.glyphName;
    final accidentalGlyph = note.pitch.accidentalGlyph!;

    final accidentalWidth = metadata.getGlyphWidthInPixels(
      accidentalGlyph,
      staffSpace,
    );

    // Posição à esquerda da nota com espaçamento apropriado
    final accidentalX = position.dx - accidentalWidth - (staffSpace * 0.2);

    // Usar anchors SMuFL se disponível para posicionamento vertical preciso
    final noteAnchors = metadata.getGlyphAnchors(noteGlyph);
    double accidentalY = noteY;

    if (noteAnchors != null) {
      final opticalCenter = noteAnchors.getAnchorInPixels(
        'opticalCenter',
        staffSpace,
      );
      if (opticalCenter != null) {
        accidentalY = noteY + opticalCenter.dy;
      }
    }

    _drawGlyph(
      canvas: canvas,
      glyphName: accidentalGlyph,
      color: theme.accidentalColor ?? theme.noteheadColor,
      x: accidentalX,
      y: accidentalY,
      fontSize: staffSpace * 4,
    );

    // Para acidentes microtonais, pode adicionar indicação visual adicional
    if (note.pitch.hasMicrotone) {
      _drawMicrotoneIndication(
        canvas,
        note.pitch,
        accidentalX,
        accidentalY,
        staffSpace,
      );
    }
  }

  /// Desenha indicação visual adicional para microtons
  void _drawMicrotoneIndication(
    Canvas canvas,
    Pitch pitch,
    double x,
    double y,
    double staffSpace,
  ) {
    // Opcional: desenhar pequena indicação de cents ou graus microtonais
    if (pitch.centsDeviation.abs() > 0) {
      final centsText = '${pitch.centsDeviation.round()}¢';
      final textStyle = TextStyle(
        fontSize: staffSpace * 0.8,
        color: theme.accidentalColor ?? theme.noteheadColor,
        fontStyle: FontStyle.italic,
      );

      final textPainter = TextPainter(
        text: TextSpan(text: centsText, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final textOffset = Offset(
        x - textPainter.width / 2,
        y + staffSpace * 1.5,
      );

      textPainter.paint(canvas, textOffset);
    }
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
      case DurationType.thirtySecond:
        return '𝅘𝅥𝅰';
      case DurationType.sixtyFourth:
        return '𝅘𝅥𝅱';
      case DurationType.oneHundredTwentyEighth:
        return '𝅘𝅥𝅲';
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

  // Método auxiliar para desenhar ornamentos da nota
  void _drawNoteOrnaments(
    Canvas canvas,
    Note note,
    double noteX,
    double noteY,
    double staffSpace,
  ) {
    // Se a nota não tem ornamentos, não faz nada
    if (note.ornaments.isEmpty) return;

    // Para cada ornamento da nota
    for (final ornament in note.ornaments) {
      // Usa o método do mixin AdvancedMusicPainterMixin para desenhar ornamentos
      drawOrnament(
        canvas,
        ornament,
        Offset(noteX, noteY),
        staffSpace,
        metadata,
        theme,
        note.duration.type.glyphName,
      );
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
