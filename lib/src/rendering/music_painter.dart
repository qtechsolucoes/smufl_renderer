// lib/src/rendering/music_painter.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '../layout/layout_engine.dart';
import '../music_model/musical_element.dart';
import '../smufl/smufl_metadata_loader.dart';
import '../theme/music_score_theme.dart';

class MusicPainter extends CustomPainter {
  final List<PositionedElement> positionedElements;
  final SmuflMetadata metadata;
  final MusicScoreTheme theme;

  MusicPainter({
    required this.positionedElements,
    required this.metadata,
    required this.theme,
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

    final staffSpace =
        metadata.getEngravingDefault('thickBarlineThickness') * 4;

    final systems = positionedElements.map((e) => e.system).toSet();
    for (final system in systems) {
      _drawStaffLines(canvas, size.width, 100.0 + (system * 120.0), staffSpace);
    }

    Clef currentClef = Clef(type: 'g');

    for (int i = 0; i < positionedElements.length; i++) {
      final pe = positionedElements[i];
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
        // --- LÓGICA DE DESENHO DE LIGADURAS (TIES) ---
        // A ligadura é desenhada 'em adição' à nota, então não usamos 'else'
        if (element.tie == TieType.start) {
          PositionedElement? endNoteElement;
          // Procura pela próxima nota na partitura para ser o fim da ligadura
          for (int j = i + 1; j < positionedElements.length; j++) {
            if (positionedElements[j].element is Note) {
              endNoteElement = positionedElements[j];
              break;
            }
          }
          if (endNoteElement != null) {
            _drawTie(canvas, pe, endNoteElement, currentClef, staffSpace);
          }
        }

        // --- LÓGICA DE DESENHO DE NOTAS/BARRAS ---
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
      } else if (element is Rest) {
        _drawRest(canvas, element, position, staffSpace);
      } else if (element is Barline) {
        _drawBarline(canvas, position, staffSpace);
      }
    }
  }

  /// Nova função para desenhar ligaduras de valor (ties)
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

    // A curva da ligadura vai na direção oposta à da haste
    final double verticalDirection = stemsGoUp ? 1.0 : -1.0;

    final startNoteY = startPe.position.dy - (startStaffPos * staffSpace / 2);
    final endNote = endPe.element as Note;
    final endStaffPos = _calculateStaffPosition(endNote.pitch, clef);
    final endNoteY = endPe.position.dy - (endStaffPos * staffSpace / 2);

    final startBbox = metadata.getGlyphBBox(startNote.duration.type.glyphName);
    final startNoteheadWidth =
        (startBbox?['bBoxNE']?[0] ?? 0.0) * (staffSpace * 4 / 2048);

    // Pontos de início e fim da curva nas bordas das cabeças das notas
    final startPoint = Offset(
      startPe.position.dx + startNoteheadWidth * 0.8,
      startNoteY,
    );
    final endPoint = Offset(endPe.position.dx, endNoteY);

    // O ponto de controle define o arco da curva
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
        fontSize: staffSpace * 4,
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
      final noteheadWidth =
          (bbox?['bBoxNE']?[0] ?? 0.0) * (staffSpace * 4 / 2048);
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
    final staffPosition = _calculateStaffPosition(note.pitch, clef);
    final noteY = position.dy - (staffPosition * staffSpace / 2);
    final glyphName = note.duration.type.glyphName;
    bool stemsGoUp = staffPosition < 0;

    _drawGlyph(
      canvas: canvas,
      glyphName: glyphName,
      color: theme.noteheadColor,
      x: position.dx,
      y: noteY,
      fontSize: staffSpace * 4,
    );

    _drawArticulations(canvas, note, stemsGoUp, position.dx, noteY, staffSpace);

    if (note.duration.type != DurationType.whole) {
      final stemHeight = staffSpace * 3.5;
      final stemPaint = Paint()
        ..color = theme.stemColor
        ..strokeWidth = metadata.getEngravingDefault('stemThickness');
      final bbox = metadata.getGlyphBBox(glyphName);
      final noteheadWidth =
          (bbox?['bBoxNE']?[0] ?? 0.0) * (staffSpace * 4 / 2048);
      double stemX = stemsGoUp
          ? position.dx + noteheadWidth - (stemPaint.strokeWidth / 2)
          : position.dx + (stemPaint.strokeWidth / 2);
      double stemStartY = noteY;
      double stemEndY = stemsGoUp ? noteY - stemHeight : noteY + stemHeight;
      canvas.drawLine(
        Offset(stemX, stemStartY),
        Offset(stemX, stemEndY),
        stemPaint,
      );

      if (note.beam == null && note.duration.type.value < 1.0) {
        final flagGlyph = note.duration.type == DurationType.eighth
            ? (stemsGoUp ? 'flag8thUp' : 'flag8thDown')
            : (stemsGoUp ? 'flag16thUp' : 'flag16thDown');

        _drawGlyph(
          canvas: canvas,
          glyphName: flagGlyph,
          color: theme.stemColor,
          x: stemX,
          y: stemEndY,
          fontSize: staffSpace * 4,
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

    // A posição da articulação é oposta à da haste
    final yDirection = stemsGoUp
        ? -1
        : 1; // CORREÇÃO: Invertido para ficar do lado oposto da haste
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

  void _drawStaffLines(
    Canvas canvas,
    double width,
    double y,
    double staffSpace,
  ) {
    final linePaint = Paint()
      ..color = theme.staffLineColor
      ..strokeWidth = metadata.getEngravingDefault('staffLineThickness');
    double currentY = y - (2 * staffSpace);
    for (int i = 0; i < 5; i++) {
      canvas.drawLine(Offset(0, currentY), Offset(width, currentY), linePaint);
      currentY += staffSpace;
    }
  }

  void _drawClef(Canvas canvas, Clef clef, Offset position, double staffSpace) {
    _drawGlyph(
      canvas: canvas,
      glyphName: 'gClef',
      color: theme.clefColor,
      x: position.dx,
      y: position.dy + staffSpace,
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
      final y = position.dy - (staffPosition * staffSpace / 2);
      _drawGlyph(
        canvas: canvas,
        glyphName: glyphName,
        color: theme.keySignatureColor,
        x: currentX,
        y: y,
        fontSize: staffSpace * 4,
      );
      currentX += 12;
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
    _drawGlyph(
      canvas: canvas,
      glyphName: numGlyph,
      color: theme.timeSignatureColor,
      x: position.dx,
      y: position.dy - (1.5 * staffSpace),
      fontSize: staffSpace * 4,
    );
    _drawGlyph(
      canvas: canvas,
      glyphName: denGlyph,
      color: theme.timeSignatureColor,
      x: position.dx,
      y: position.dy + (1.5 * staffSpace),
      fontSize: staffSpace * 4,
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
    final textPainter = TextPainter(
      text: TextSpan(
        text: metadata.getCodepoint(glyphName),
        style: TextStyle(
          fontFamily: 'Bravura',
          fontSize: fontSize,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final yOffset = y - (textPainter.height / 2);
    textPainter.paint(canvas, Offset(x, yOffset));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
