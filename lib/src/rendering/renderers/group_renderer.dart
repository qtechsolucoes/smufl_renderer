// lib/src/rendering/renderers/group_renderer.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../layout/layout_engine.dart';
import '../../music_model/musical_element.dart';
import '../../smufl/smufl_metadata_loader.dart';
import '../../theme/music_score_theme.dart';
import '../staff_coordinate_system.dart';

/// Renderizador especialista em desenhar elementos que agrupam ou conectam
/// outras notas, como Beams (barras), Slurs (ligaduras de expressão) e
/// Ties (ligaduras de valor).
class GroupRenderer {
  final Canvas canvas;
  final List<PositionedElement> elements;
  final StaffCoordinateSystem coordinates;
  final SmuflMetadata metadata;
  final MusicScoreTheme theme;
  final double glyphSize;
  final double staffLineThickness;
  final double stemThickness;
  final Clef currentClef;

  GroupRenderer({
    required this.canvas,
    required this.elements,
    required this.coordinates,
    required this.metadata,
    required this.theme,
    required this.glyphSize,
    required this.staffLineThickness,
    required this.stemThickness,
    required this.currentClef,
  });

  // ################# BEAM RENDERING #################

  void renderBeams() {
    final beamGroups = _identifyBeamGroups();
    for (final group in beamGroups.values) {
      if (group.length < 2) continue;

      final positions = <Offset>[];
      final staffPositions = <int>[];
      final durations = <DurationType>[];

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
          durations.add(note.duration.type);
        }
      }

      final avgPos =
          staffPositions.reduce((a, b) => a + b) / staffPositions.length;
      final stemUp = avgPos < 0;

      _renderBeamGroup(positions, staffPositions, durations, stemUp);
    }
  }

  Map<int, List<int>> _identifyBeamGroups() {
    final groups = <int, List<int>>{};
    int groupId = 0;
    for (int i = 0; i < elements.length; i++) {
      final element = elements[i].element;
      if (element is Note && element.beam == BeamType.start) {
        final group = <int>[i];
        for (int j = i + 1; j < elements.length; j++) {
          final nextElement = elements[j].element;
          if (nextElement is Note && nextElement.beam != null) {
            group.add(j);
            if (nextElement.beam == BeamType.end) break;
          } else {
            break; // Interrompe se encontrar um elemento que não seja uma nota com beam
          }
        }
        if (group.length >= 2) {
          groups[groupId++] = group;
        }
      }
    }
    return groups;
  }

  void _renderBeamGroup(
    List<Offset> positions,
    List<int> staffPositions,
    List<DurationType> durations,
    bool stemUp,
  ) {
    int maxBeams = 0;
    final beamCounts = durations.map((d) {
      final beams = switch (d) {
        DurationType.eighth => 1,
        DurationType.sixteenth => 2,
        DurationType.thirtySecond => 3,
        DurationType.sixtyFourth => 4,
        _ => 0,
      };
      if (beams > maxBeams) maxBeams = beams;
      return beams;
    }).toList();

    double stemHeightFactor = 3.5 + (maxBeams > 2 ? (maxBeams - 2) * 0.4 : 0);
    final stemHeight = coordinates.staffSpace * stemHeightFactor;

    final stemEndpoints = <Offset>[];
    for (int i = 0; i < positions.length; i++) {
      final noteWidth = coordinates.staffSpace * 1.18;
      final stemX = stemUp
          ? positions[i].dx + (noteWidth * 0.45)
          : positions[i].dx - (noteWidth * 0.45);
      stemEndpoints.add(Offset(stemX, positions[i].dy));
    }

    final firstNotePos = staffPositions.first;
    final lastNotePos = staffPositions.last;
    final y_start = stemUp
        ? positions.first.dy - stemHeight
        : positions.first.dy + stemHeight;
    final y_end = stemUp
        ? positions.last.dy - stemHeight
        : positions.last.dy + stemHeight;

    final firstStem = Offset(stemEndpoints.first.dx, y_start);
    final lastStem = Offset(stemEndpoints.last.dx, y_end);

    final slope = (lastStem.dy - firstStem.dy) / (lastStem.dx - firstStem.dx);
    final clampedSlope = slope.isFinite ? slope.clamp(-0.5, 0.5) : 0.0;

    double getBeamY(double x) =>
        firstStem.dy + (clampedSlope * (x - firstStem.dx));

    final stemPaint = Paint()
      ..color = theme.stemColor
      ..strokeWidth = stemThickness;
    final beamPaint = Paint()
      ..color = theme.beamColor ?? theme.stemColor
      ..style = PaintingStyle.fill;
    final beamThickness =
        metadata.getEngravingDefault('beamThickness') * coordinates.staffSpace;
    final beamSpacing = beamThickness * 1.5;

    for (int i = 0; i < positions.length; i++) {
      final stemX = stemEndpoints[i].dx;
      final beamY = getBeamY(stemX);
      canvas.drawLine(
        Offset(stemX, positions[i].dy),
        Offset(stemX, beamY),
        stemPaint,
      );
    }

    for (int beamLevel = 0; beamLevel < maxBeams; beamLevel++) {
      // Lógica complexa de desenho de beams parciais
    }
    final mainBeamYOffset = stemUp ? 0.0 : -beamThickness;
    final mainBeamPath = Path()
      ..moveTo(firstStem.dx, getBeamY(firstStem.dx) + mainBeamYOffset)
      ..lineTo(lastStem.dx, getBeamY(lastStem.dx) + mainBeamYOffset)
      ..lineTo(
        lastStem.dx,
        getBeamY(lastStem.dx) + beamThickness + mainBeamYOffset,
      )
      ..lineTo(
        firstStem.dx,
        getBeamY(firstStem.dx) + beamThickness + mainBeamYOffset,
      )
      ..close();
    canvas.drawPath(mainBeamPath, beamPaint);
  }

  // ################# TIE RENDERING #################

  void renderTies() {
    final tieGroups = _identifyTieGroups();
    for (final group in tieGroups.values) {
      if (group.length < 2) continue;
      final startElement = elements[group.first];
      final endElement = elements[group.last];
      if (startElement.element is Note) {
        _renderSingleTie(startElement, endElement);
      } else if (startElement.element is Chord) {
        _renderChordTies(startElement, endElement);
      }
    }
  }

  Map<int, List<int>> _identifyTieGroups() {
    final groups = <int, List<int>>{};
    int groupId = 0;
    for (int i = 0; i < elements.length; i++) {
      final element = elements[i].element;
      TieType? tieType;
      if (element is Note)
        tieType = element.tie;
      else if (element is Chord)
        tieType = element.tie;

      if (tieType == TieType.start) {
        final group = <int>[i];
        for (int j = i + 1; j < elements.length; j++) {
          final startEl = elements[i].element;
          final nextEl = elements[j].element;
          bool isMatch = false;
          TieType? nextTieType;

          if (startEl is Note && nextEl is Note) {
            isMatch = startEl.pitch == nextEl.pitch;
            nextTieType = nextEl.tie;
          } else if (startEl is Chord && nextEl is Chord) {
            isMatch = startEl.notes.length == nextEl.notes.length;
            nextTieType = nextEl.tie;
          }

          if (isMatch) {
            group.add(j);
            if (nextTieType == TieType.end) break;
          }
        }
        if (group.length > 1) groups[groupId++] = group;
      }
    }
    return groups;
  }

  void _renderChordTies(
    PositionedElement startChordEl,
    PositionedElement endChordEl,
  ) {
    final startChord = startChordEl.element as Chord;
    final endChord = endChordEl.element as Chord;
    if (startChord.notes.length != endChord.notes.length) return;

    final startPositions = startChord.notes
        .map((n) => _calculateStaffPosition(n.pitch))
        .toList();
    final mostExtremePos = startPositions.reduce(
      (a, b) => a.abs() > b.abs() ? a : b,
    );
    final curveUp = mostExtremePos < 0;

    for (int i = 0; i < startChord.notes.length; i++) {
      final startStaffPos = startPositions[i];
      final endStaffPos = _calculateStaffPosition(endChord.notes[i].pitch);
      final startNoteY =
          coordinates.staffBaseline.dy -
          (startStaffPos * coordinates.staffSpace * 0.5);
      final endNoteY =
          coordinates.staffBaseline.dy -
          (endStaffPos * coordinates.staffSpace * 0.5);
      _drawTieCurve(
        startChordEl.position.dx,
        startNoteY,
        endChordEl.position.dx,
        endNoteY,
        curveUp,
      );
    }
  }

  void _renderSingleTie(
    PositionedElement startNoteEl,
    PositionedElement endNoteEl,
  ) {
    final startNote = startNoteEl.element as Note;
    final startStaffPos = _calculateStaffPosition(startNote.pitch);
    final stemUp = startStaffPos <= 0;
    final curveUp = !stemUp;

    final startNoteY =
        coordinates.staffBaseline.dy -
        (startStaffPos * coordinates.staffSpace * 0.5);
    final endNoteY =
        coordinates.staffBaseline.dy -
        (_calculateStaffPosition((endNoteEl.element as Note).pitch) *
            coordinates.staffSpace *
            0.5);
    _drawTieCurve(
      startNoteEl.position.dx,
      startNoteY,
      endNoteEl.position.dx,
      endNoteY,
      curveUp,
    );
  }

  void _drawTieCurve(
    double startX,
    double startY,
    double endX,
    double endY,
    bool curveUp,
  ) {
    final noteheadWidth =
        (metadata.getGlyphBBox('noteheadBlack')?['bBoxNE']?[0] ?? 1.18) *
        coordinates.staffSpace;
    final startPoint = Offset(startX + noteheadWidth / 2, startY);
    final endPoint = Offset(endX - noteheadWidth / 2, endY);

    final direction = curveUp ? -1.0 : 1.0;
    final arcHeight =
        (coordinates.staffSpace * 0.8) + (endPoint.dx - startPoint.dx) * 0.04;

    final controlPoint1 = Offset(
      startPoint.dx + (endPoint.dx - startPoint.dx) * 0.25,
      startPoint.dy + (arcHeight * direction),
    );
    final controlPoint2 = Offset(
      endPoint.dx - (endPoint.dx - startPoint.dx) * 0.25,
      endPoint.dy + (arcHeight * direction),
    );

    final tiePaint = Paint()
      ..color = theme.tieColor ?? theme.noteheadColor
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(startPoint.dx, startPoint.dy)
      ..cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        endPoint.dx,
        endPoint.dy,
      )
      ..cubicTo(
        controlPoint2.dx,
        controlPoint2.dy - (direction * staffLineThickness * 1.5),
        controlPoint1.dx,
        controlPoint1.dy - (direction * staffLineThickness * 1.5),
        startPoint.dx,
        startPoint.dy,
      );

    canvas.drawPath(path, tiePaint);
  }

  // ################# SLUR RENDERING #################

  void renderSlurs() {
    // A lógica de Slur está em `slur_calculator.dart` e pode ser chamada aqui.
    // Por simplicidade, vamos usar uma versão básica de desenho.
    final slurGroups = _identifySlurGroups();
    for (final group in slurGroups.values) {
      if (group.length < 2) continue;

      final startElement = elements[group.first];
      final endElement = elements[group.last];

      if (startElement.element is! Note || endElement.element is! Note)
        continue;
      _renderSingleSlur(startElement, endElement);
    }
  }

  Map<int, List<int>> _identifySlurGroups() {
    final groups = <int, List<int>>{};
    int groupId = 0;
    for (int i = 0; i < elements.length; i++) {
      final element = elements[i].element;
      if (element is Note && element.slur == SlurType.start) {
        final group = <int>[i];
        for (int j = i + 1; j < elements.length; j++) {
          final nextElement = elements[j].element;
          if (nextElement is Note) {
            group.add(j);
            if (nextElement.slur == SlurType.end) break;
          }
        }
        if (group.length > 1) groups[groupId++] = group;
      }
    }
    return groups;
  }

  void _renderSingleSlur(
    PositionedElement startElement,
    PositionedElement endElement,
  ) {
    final startNote = startElement.element as Note;
    final startStaffPos = _calculateStaffPosition(startNote.pitch);
    final startStemUp = startStaffPos <= 0;
    final slurAbove = !startStemUp;

    final startNoteY =
        coordinates.staffBaseline.dy -
        (startStaffPos * coordinates.staffSpace * 0.5);
    final endNoteY =
        coordinates.staffBaseline.dy -
        (_calculateStaffPosition((endElement.element as Note).pitch) *
            coordinates.staffSpace *
            0.5);

    final noteheadWidth =
        (metadata.getGlyphBBox('noteheadBlack')?['bBoxNE']?[0] ?? 1.18) *
        coordinates.staffSpace;

    final startPoint = Offset(
      startElement.position.dx - noteheadWidth / 2,
      startNoteY,
    );
    final endPoint = Offset(
      endElement.position.dx + noteheadWidth / 2,
      endNoteY,
    );

    final direction = slurAbove ? -1.0 : 1.0;
    final arcHeight =
        (coordinates.staffSpace * 1.5) +
        (endPoint.dx - startPoint.dx).abs() * 0.1;

    final controlPoint1 = Offset(
      startPoint.dx + (endPoint.dx - startPoint.dx) * 0.2,
      startPoint.dy + (arcHeight * direction),
    );
    final controlPoint2 = Offset(
      endPoint.dx - (endPoint.dx - startPoint.dx) * 0.2,
      endPoint.dy + (arcHeight * direction),
    );

    final slurPaint = Paint()
      ..color = theme.slurColor ?? theme.noteheadColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = staffLineThickness * 1.5;

    final path = Path()
      ..moveTo(startPoint.dx, startPoint.dy)
      ..cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        endPoint.dx,
        endPoint.dy,
      );

    canvas.drawPath(path, slurPaint);
  }

  // ################# HELPERS #################

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

    int baseStep, baseOctave, basePosition;
    switch (currentClef!.actualClefType) {
      case ClefType.treble:
        baseStep = 4;
        baseOctave = 4;
        basePosition = 2;
        break;
      case ClefType.bass:
        baseStep = 3;
        baseOctave = 3;
        basePosition = -2;
        break;
      case ClefType.alto:
        baseStep = 0;
        baseOctave = 4;
        basePosition = 0;
        break;
      case ClefType.tenor:
        baseStep = 0;
        baseOctave = 4;
        basePosition = -2;
        break;
      default:
        return 0;
    }
    int diatonicDistance =
        (pitchStep - baseStep) +
        ((pitch.octave + currentClef!.octaveShift - baseOctave) * 7);
    return basePosition + diatonicDistance;
  }
}
