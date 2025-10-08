// lib/src/rendering/renderers/group_renderer.dart

import 'package:flutter/material.dart';
import '../../layout/layout_engine.dart';
import '../../music_model/musical_element.dart';
import '../../smufl/smufl_metadata_loader.dart';
import '../../theme/music_score_theme.dart';
import '../smufl_positioning_engine.dart';
import '../staff_coordinate_system.dart';

class GroupRenderer {
  final StaffCoordinateSystem coordinates;
  final SmuflMetadata metadata;
  final MusicScoreTheme theme;
  final double glyphSize;
  final double staffLineThickness;
  final double stemThickness;
  late final SMuFLPositioningEngine positioningEngine;

  GroupRenderer({
    required this.coordinates,
    required this.metadata,
    required this.theme,
    required this.glyphSize,
    required this.staffLineThickness,
    required this.stemThickness,
  }) {
    // Initialize with already loaded metadata
    positioningEngine = SMuFLPositioningEngine(metadataLoader: metadata);
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

  void renderBeams(
    Canvas canvas,
    List<PositionedElement> elements,
    Clef currentClef,
  ) {
    final beamGroups = _identifyBeamGroups(elements);
    for (final group in beamGroups.values) {
      if (group.length < 2) continue;

      final positions = <Offset>[];
      final staffPositions = <int>[];
      final durations = <DurationType>[];
      final groupElements = <PositionedElement>[];

      for (final index in group) {
        final element = elements[index];
        groupElements.add(element);
        if (element.element is Note) {
          final note = element.element as Note;
          final staffPos = _calculateStaffPosition(note.pitch, currentClef);
          final noteY =
              coordinates.staffBaseline.dy -
              (staffPos * coordinates.staffSpace * 0.5);
          positions.add(Offset(element.position.dx, noteY));
          staffPositions.add(staffPos);
          durations.add(note.duration.type);
        }
      }
      if (staffPositions.isNotEmpty) {
        final avgPos =
            staffPositions.reduce((a, b) => a + b) / staffPositions.length;
        final stemUp = avgPos <= 0;
        _renderBeamGroup(canvas, groupElements, positions, durations, stemUp);
      }
    }
  }

  void _renderBeamGroup(
    Canvas canvas,
    List<PositionedElement> groupElements,
    List<Offset> positions,
    List<DurationType> durations,
    bool stemUp,
  ) {
    if (positions.length < 2) return;

    int maxBeams = 0;
    final beamCounts = durations.map((duration) {
      final beams = switch (duration) {
        DurationType.eighth => 1,
        DurationType.sixteenth => 2,
        DurationType.thirtySecond => 3,
        DurationType.sixtyFourth => 4,
        _ => 0,
      };
      if (beams > maxBeams) maxBeams = beams;
      return beams;
    }).toList();

    // Configurar fator de altura da haste baseado no número de feixes
    // (valores usados para cálculo de espaçamento no futuro)
    final beamThickness =
        metadata.getEngravingDefault('beamThickness') * coordinates.staffSpace;
    final beamSpacing = beamThickness * 1.5;

    // CORREÇÃO SMuFL: Usar âncoras das cabeças de nota
    final stemEndpoints = <Offset>[];
    final staffPositions = <int>[];

    for (int i = 0; i < positions.length; i++) {
      final element = groupElements[i].element as Note;
      final noteGlyph = durations[i].glyphName;
      final staffPos = _calculateStaffPosition(element.pitch, Clef(clefType: ClefType.treble));

      staffPositions.add(staffPos);

      // Usar âncora SMuFL para posição da haste
      final stemAnchor = stemUp
          ? positioningEngine.getStemUpAnchor(noteGlyph)
          : positioningEngine.getStemDownAnchor(noteGlyph);

      final stemX = positions[i].dx + (stemAnchor.dx * coordinates.staffSpace);
      final stemY = positions[i].dy + (stemAnchor.dy * coordinates.staffSpace);
      stemEndpoints.add(Offset(stemX, stemY));
    }

    // CORREÇÃO SMuFL: Calcular ângulo do feixe usando positioning engine
    // Baseado em Ted Ross e Behind Bars
    final beamAngleSpaces = positioningEngine.calculateBeamAngle(
      noteStaffPositions: staffPositions,
      stemUp: stemUp,
    );

    // Calcular altura do feixe usando positioning engine
    final beamHeightSpaces = positioningEngine.calculateBeamHeight(
      staffPosition: staffPositions.first,
      stemUp: stemUp,
      allStaffPositions: staffPositions,
    );
    final beamHeightPixels = beamHeightSpaces * coordinates.staffSpace;

    // Primeira e última posição do feixe
    final firstNoteY = positions.first.dy;
    final lastNoteY = positions.last.dy;
    final avgNoteY = (firstNoteY + lastNoteY) / 2;

    final beamBaseY = stemUp
        ? avgNoteY - beamHeightPixels
        : avgNoteY + beamHeightPixels;

    // Converter ângulo de spaces para slope pixel
    final xDistance = stemEndpoints.last.dx - stemEndpoints.first.dx;
    final beamAnglePixels = (beamAngleSpaces * coordinates.staffSpace);
    final beamSlope = xDistance > 0 ? beamAnglePixels / xDistance : 0.0;

    final firstStem = Offset(
      stemEndpoints.first.dx,
      beamBaseY,
    );

    double getBeamY(double x) {
      return firstStem.dy + (beamSlope * (x - firstStem.dx));
    }

    final stemPaint = Paint()
      ..color = theme.stemColor
      ..strokeWidth = stemThickness;
    final beamPaint = Paint()
      ..color = theme.beamColor ?? theme.stemColor
      ..style = PaintingStyle.fill;

    // Draw beams
    for (int beamLevel = 0; beamLevel < maxBeams; beamLevel++) {
      Path? currentPath;
      int pathStartIndex = -1;
      for (int i = 0; i < groupElements.length; i++) {
        if (beamCounts[i] > beamLevel) {
          if (currentPath == null) {
            currentPath = Path();
            pathStartIndex = i;
          }
        }
        bool shouldEndPath = false;
        if (i == groupElements.length - 1) {
          shouldEndPath = currentPath != null;
        } else {
          if (beamCounts[i] > beamLevel && beamCounts[i + 1] <= beamLevel) {
            shouldEndPath = true;
          }
        }
        if (shouldEndPath && currentPath != null && pathStartIndex >= 0) {
          int endIndex = i;
          if (beamCounts[i] <= beamLevel && i > pathStartIndex) {
            endIndex = i - 1;
          }
          if (pathStartIndex <= endIndex) {
            final yOffset = stemUp
                ? beamLevel * beamSpacing
                : -beamLevel * beamSpacing;
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

    // Draw stems
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

  Map<int, List<int>> _identifyTieGroups(List<PositionedElement> elements) {
    final groups = <int, List<int>>{};
    int groupId = 0;
    for (int i = 0; i < elements.length; i++) {
      final element = elements[i].element;
      if (element is Note && element.tie == TieType.start) {
        final group = <int>[i];
        for (int j = i + 1; j < elements.length; j++) {
          final nextElement = elements[j].element;
          if (nextElement is Note &&
              nextElement.pitch.step == (element).pitch.step &&
              nextElement.pitch.octave == element.pitch.octave) {
            group.add(j);
            if (nextElement.tie == TieType.end) break;
          }
        }
        if (group.length >= 2) {
          groups[groupId++] = group;
        }
      }
    }
    return groups;
  }

  void renderTies(
    Canvas canvas,
    List<PositionedElement> elements,
    Clef currentClef,
  ) {
    final tieGroups = _identifyTieGroups(elements);
    for (final group in tieGroups.values) {
      final startElement = elements[group.first];
      final endElement = elements[group.last];
      if (startElement.element is! Note || endElement.element is! Note) {
        continue;
      }

      final startNote = startElement.element as Note;
      final startStaffPos = _calculateStaffPosition(
        startNote.pitch,
        currentClef,
      );

      // CORREÇÃO LACERDA: "Ligaduras ficam do lado OPOSTO das hastes"
      // Se haste para cima, ligadura embaixo; se haste para baixo, ligadura em cima
      final stemUp = startStaffPos <= 0; // Haste para cima quando nota está abaixo/na linha central
      final tieAbove = !stemUp; // Ligadura oposta à haste

      final startNoteY =
          coordinates.staffBaseline.dy -
          (startStaffPos * coordinates.staffSpace * 0.5);
      final endNoteY =
          coordinates.staffBaseline.dy -
          (_calculateStaffPosition(
                (endElement.element as Note).pitch,
                currentClef,
              ) *
              coordinates.staffSpace *
              0.5);
      final noteWidth = coordinates.staffSpace * 1.18;

      // CORREÇÃO: Ligadura começa e termina nas bordas das cabeças
      final startPoint = Offset(
        startElement.position.dx + noteWidth * 0.6,
        startNoteY + (tieAbove ? -coordinates.staffSpace * 0.2 : coordinates.staffSpace * 0.2),
      );
      final endPoint = Offset(
        endElement.position.dx + noteWidth * 0.4,
        endNoteY + (tieAbove ? -coordinates.staffSpace * 0.2 : coordinates.staffSpace * 0.2),
      );

      // CORREÇÃO LACERDA: Ligadura com curva suave, altura proporcional à distância
      final distance = (endPoint.dx - startPoint.dx).abs();
      final curvatureHeight = (distance * 0.08).clamp(
        coordinates.staffSpace * 0.3,
        coordinates.staffSpace * 0.8,
      );

      final controlPoint = Offset(
        (startPoint.dx + endPoint.dx) / 2,
        ((startPoint.dy + endPoint.dy) / 2) +
            (curvatureHeight * (tieAbove ? -1 : 1)),
      );

      // CORREÇÃO: Ligadura preenchida (não apenas traço), formato de arco
      final tiePaint = Paint()
        ..color = theme.tieColor ?? theme.noteheadColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = coordinates.staffSpace * 0.13
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

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
  }

  Map<int, List<int>> _identifySlurGroups(List<PositionedElement> elements) {
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
        if (group.length >= 2) {
          groups[groupId++] = group;
        }
      }
    }
    return groups;
  }

  void renderSlurs(
    Canvas canvas,
    List<PositionedElement> elements,
    Clef currentClef,
  ) {
    final slurGroups = _identifySlurGroups(elements);
    for (final group in slurGroups.values) {
      if (group.length < 2) continue;

      final startElement = elements[group.first];
      final endElement = elements[group.last];
      if (startElement.element is! Note || endElement.element is! Note) {
        continue;
      }
      final startNote = startElement.element as Note;
      final endNote = endElement.element as Note;
      final startStaffPos = _calculateStaffPosition(
        startNote.pitch,
        currentClef,
      );
      final endStaffPos = _calculateStaffPosition(endNote.pitch, currentClef);

      // CORREÇÃO LACERDA: Ligadura de expressão segue mesma regra de tie
      // Oposta à direção das hastes
      final startStemUp = startStaffPos <= 0;
      final slurAbove = !startStemUp;

      final startNoteY =
          coordinates.staffBaseline.dy -
          (startStaffPos * coordinates.staffSpace * 0.5);
      final endNoteY =
          coordinates.staffBaseline.dy -
          (endStaffPos * coordinates.staffSpace * 0.5);

      final noteWidth = coordinates.staffSpace * 1.18;

      // CORREÇÃO: Ligadura mais próxima das cabeças
      final startPoint = Offset(
        startElement.position.dx + noteWidth * 0.3,
        startNoteY + (coordinates.staffSpace * 0.4 * (slurAbove ? -1 : 1)),
      );
      final endPoint = Offset(
        endElement.position.dx + noteWidth * 0.7,
        endNoteY + (coordinates.staffSpace * 0.4 * (slurAbove ? -1 : 1)),
      );

      // CORREÇÃO LACERDA: Altura do arco proporcional à distância
      // Quanto mais longa, mais alta a curva
      final distance = (endPoint.dx - startPoint.dx).abs();
      final arcHeight = coordinates.staffSpace * 1.2 + (distance * 0.04);

      // Curva bezier cúbica para forma mais natural
      final controlPoint1 = Offset(
        startPoint.dx + (endPoint.dx - startPoint.dx) * 0.3,
        startPoint.dy + (arcHeight * (slurAbove ? -1 : 1)),
      );
      final controlPoint2 = Offset(
        endPoint.dx - (endPoint.dx - startPoint.dx) * 0.3,
        endPoint.dy + (arcHeight * (slurAbove ? -1 : 1)),
      );

      // CORREÇÃO: Espessura padrão de ligadura de expressão
      final slurPaint = Paint()
        ..color = theme.slurColor ?? theme.noteheadColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = coordinates.staffSpace * 0.12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

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
  }

  int _calculateStaffPosition(Pitch pitch, Clef clef) {
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
    switch (clef.actualClefType) {
      case ClefType.treble:
        baseStep = 6;
        baseOctave = 4;
        basePosition = 0;
        break;
      case ClefType.bass:
        baseStep = 1;
        baseOctave = 3;
        basePosition = 0;
        break;
      case ClefType.alto:
        baseStep = 0;
        baseOctave = 4;
        basePosition = 0;
        break;
      case ClefType.tenor:
        baseStep = 5;
        baseOctave = 3;
        basePosition = 0;
        break;
      default:
        return 0;
    }
    int diatonicDistance =
        (pitchStep - baseStep) +
        ((pitch.octave + clef.octaveShift - baseOctave) * 7);
    return basePosition - diatonicDistance;
  }
}
