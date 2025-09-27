// lib/src/layout/layout_engine.dart
import 'dart:collection';
import 'package:flutter/material.dart';
import '../music_model/musical_element.dart';

/// Uma classe para guardar um elemento e sua posição calculada.
class PositionedElement {
  final MusicalElement element;
  final Offset position;
  final int system; // A qual "linha" de pauta ele pertence

  PositionedElement(this.element, this.position, {this.system = 0});
}

class LayoutEngine {
  final Staff staff;
  final double availableWidth;

  static const double quarterNoteSpace = 4.0;

  LayoutEngine(this.staff, {required this.availableWidth});

  List<PositionedElement> layout() {
    final List<PositionedElement> positionedElements = [];
    double cursorX = 10.0;
    double cursorY = 100.0;
    int currentSystem = 0;
    final double spaceUnit = 10.0;

    for (final measure in staff.measures) {
      // --- Início da Lógica de Agrupamento de Barras (Beaming) ---
      final processedElements = _processBeams(measure.elements);
      // --- Fim da Lógica de Agrupamento de Barras (Beaming) ---

      // Calcula a largura ideal do compasso com os elementos processados
      double idealMeasureWidth = 0;
      final Map<MusicalElement, double> elementWidths = {};
      for (final element in processedElements) {
        double width = 0;
        if (element is Note) {
          width = quarterNoteSpace * element.duration.type.value;
        } else if (element is Rest) {
          width = quarterNoteSpace * element.duration.type.value;
        } else if (element is Clef) {
          width = 8.0;
        } else if (element is KeySignature) {
          width = 4.0 + (element.count.abs() * 2.5);
        } else if (element is TimeSignature) {
          width = 6.0;
        }
        elementWidths[element] = width * spaceUnit;
        idealMeasureWidth += elementWidths[element]!;
      }

      if (cursorX + idealMeasureWidth > availableWidth &&
          measure != staff.measures.first) {
        cursorX = 10.0;
        currentSystem++;
        cursorY += 120.0;
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
      cursorX += spaceUnit * 2.0;
    }
    return positionedElements;
  }

  /// Processa uma lista de elementos para identificar e marcar grupos de notas
  /// que devem ser conectadas por barras de ligação.
  List<MusicalElement> _processBeams(List<MusicalElement> elements) {
    final List<MusicalElement> result = [];
    final queue = Queue<MusicalElement>.from(elements);

    while (queue.isNotEmpty) {
      final current = queue.first;

      if (current is Note && _isBeamable(current)) {
        // Encontramos o início de um possível grupo de barras
        final beamGroup = <Note>[];
        beamGroup.add(queue.removeFirst() as Note);

        // Olha para frente na fila para encontrar outras notas conectáveis
        while (queue.isNotEmpty &&
            queue.first is Note &&
            _isBeamable(queue.first as Note)) {
          beamGroup.add(queue.removeFirst() as Note);
        }

        // Se o grupo tem mais de uma nota, marca-as para ligação
        if (beamGroup.length > 1) {
          result.add(_cloneNoteWithBeam(beamGroup.first, BeamType.start));
          for (int i = 1; i < beamGroup.length - 1; i++) {
            result.add(_cloneNoteWithBeam(beamGroup[i], BeamType.inner));
          }
          result.add(_cloneNoteWithBeam(beamGroup.last, BeamType.end));
        } else {
          // Grupo de uma nota só, adiciona de volta sem marcação de barra
          result.addAll(beamGroup);
        }
      } else {
        // Elemento não conectável, apenas o move para o resultado
        result.add(queue.removeFirst());
      }
    }
    return result;
  }

  /// Verifica se uma nota tem uma duração que permite ligação por barra.
  bool _isBeamable(Note note) {
    return note.duration.type == DurationType.eighth ||
        note.duration.type == DurationType.sixteenth;
  }

  /// Cria um clone de uma nota, aplicando o tipo de barra.
  Note _cloneNoteWithBeam(Note original, BeamType beamType) {
    return Note(
      pitch: original.pitch,
      duration: original.duration,
      beam: beamType, // A única propriedade que muda
    );
  }
}
