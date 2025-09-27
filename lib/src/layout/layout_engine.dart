// lib/src/layout/layout_engine.dart

import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:smufl_renderer/smufl_renderer.dart';

/// Uma classe para guardar um elemento e sua posição calculada.
class PositionedElement {
  final MusicalElement element;
  final Offset position;
  final int system;

  PositionedElement(this.element, this.position, {this.system = 0});
}

class LayoutEngine {
  final Staff staff;
  final double availableWidth;
  final double staffSpace;

  final SmuflMetadata _smuflMetadata;

  LayoutEngine(
    this.staff, {
    required this.availableWidth,
    this.staffSpace = 20.0,
  }) : _smuflMetadata = SmuflMetadata();

  double _getGlyphWidth(String glyphName, {double scale = 1.0}) {
    final glyphWidth = _smuflMetadata.getGlyphWidthInPixels(glyphName, staffSpace);
    return glyphWidth * scale;
  }

  List<PositionedElement> layout() {
    final List<PositionedElement> positionedElements = [];
    double cursorX = staffSpace * 1.0; // Margem inicial baseada em staff space
    double cursorY = staffSpace * 3.0; // Margem superior proporcional
    int currentSystem = 0;

    for (final measure in staff.measures) {
      final processedElements = _processBeams(measure.elements);
      double idealMeasureWidth = 0;
      final Map<MusicalElement, double> elementWidths = {};

      for (final element in processedElements) {
        double width = 0;
        double rhythmicSpace = 0;

        if (element is Note) {
          width = _getGlyphWidth('noteheadBlack');
          if (element.pitch.accidentalGlyph != null) {
            width += _getGlyphWidth(element.pitch.accidentalGlyph!);
          }
          rhythmicSpace = staffSpace * element.duration.type.value * 1.5;
        } else if (element is Rest) {
          switch (element.duration.type) {
            case DurationType.whole:
              width = _getGlyphWidth('restWhole');
              break;
            case DurationType.half:
              width = _getGlyphWidth('restHalf');
              break;
            case DurationType.quarter:
              width = _getGlyphWidth('restQuarter');
              break;
            case DurationType.eighth:
              width = _getGlyphWidth('rest8th');
              break;
            case DurationType.sixteenth:
              width = _getGlyphWidth('rest16th');
              break;
          }
          rhythmicSpace = staffSpace * element.duration.type.value * 1.5;
        } else if (element is Chord) {
          width = _getGlyphWidth('noteheadBlack') * 1.5;
          rhythmicSpace = staffSpace * element.duration.type.value * 1.5;
        } else if (element is Clef) {
          width = staffSpace * 2.684 + staffSpace * 0.5; // Largura oficial gClef + espaçamento
        } else if (element is KeySignature) {
          if (element.count != 0) {
            final glyph = element.count > 0
                ? 'accidentalSharp'
                : 'accidentalFlat';
            width = (element.count.abs() * staffSpace * 1.2) + staffSpace * 0.5; // Espaçamento oficial SMuFL
          }
        } else if (element is TimeSignature) {
          width = staffSpace * 2.0; // Largura fixa para fórmula de compasso
        }

        elementWidths[element] = width + rhythmicSpace;
        idealMeasureWidth += elementWidths[element]!;
      }

      if (cursorX + idealMeasureWidth > availableWidth &&
          measure != staff.measures.first) {
        cursorX = 10.0;
        currentSystem++;
        cursorY += staffSpace * 8; // CORREÇÃO: Espaçamento escalável entre sistemas
      }

      for (final element in processedElements) {
        positionedElements.add(
          PositionedElement(
            element,
            Offset(cursorX, cursorY),
            system: currentSystem,
          ),
        );
        cursorX += elementWidths[element]!;
      }

      positionedElements.add(
        PositionedElement(
          Barline(),
          Offset(cursorX, cursorY),
          system: currentSystem,
        ),
      );
      cursorX += _getGlyphWidth('barlineSingle') * 0.5;
    }
    return positionedElements;
  }

  List<MusicalElement> _processBeams(List<MusicalElement> elements) {
    final List<MusicalElement> result = [];
    final queue = Queue<MusicalElement>.from(elements);

    while (queue.isNotEmpty) {
      final current = queue.first;

      if (current is Note && _isBeamable(current)) {
        final beamGroup = <Note>[];
        beamGroup.add(queue.removeFirst() as Note);

        while (queue.isNotEmpty &&
            queue.first is Note &&
            _isBeamable(queue.first as Note)) {
          beamGroup.add(queue.removeFirst() as Note);
        }

        if (beamGroup.length > 1) {
          result.add(_cloneNoteWithBeam(beamGroup.first, BeamType.start));
          for (int i = 1; i < beamGroup.length - 1; i++) {
            result.add(_cloneNoteWithBeam(beamGroup[i], BeamType.inner));
          }
          result.add(_cloneNoteWithBeam(beamGroup.last, BeamType.end));
        } else {
          result.addAll(beamGroup);
        }
      } else {
        result.add(queue.removeFirst());
      }
    }
    return result;
  }

  bool _isBeamable(Note note) {
    return note.duration.type == DurationType.eighth ||
        note.duration.type == DurationType.sixteenth;
  }

  Note _cloneNoteWithBeam(Note original, BeamType beamType) {
    return Note(
      pitch: original.pitch,
      duration: original.duration,
      beam: beamType,
      articulations: original.articulations,
      tie: original.tie,
      slur: original.slur,
    );
  }
}
